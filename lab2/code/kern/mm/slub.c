#include <assert.h>
#include <list.h>
#include <mmu.h>
#include <pmm.h>
#include <slub.h>
#include <stdio.h>

/* A slab keeps its metadata at the start of its page. Free objects hold
 * their next pointer in their own storage; allocated objects have no header. */
#define SLUB_ALIGN (2 * sizeof(uintptr_t))
#define SLUB_HEADER_SIZE \
    ((sizeof(struct slub_slab) + SLUB_ALIGN - 1) & ~(SLUB_ALIGN - 1))

struct slub_cache {
    size_t object_size;
    list_entry_t partial;
    list_entry_t full;
};

struct slub_slab {
    list_entry_t link;
    struct slub_cache *cache;   /* NULL for an allocation larger than a slab object */
    struct Page *page;
    void *freelist;
    size_t inuse;
    size_t capacity;
    size_t nr_pages;
};

static const size_t slub_sizes[] = {
    16, 32, 64, 128, 256, 512, 1024, 2048, 3072,
    PGSIZE - SLUB_HEADER_SIZE,
};
#define SLUB_CACHE_COUNT (sizeof(slub_sizes) / sizeof(slub_sizes[0]))
static struct slub_cache slub_caches[SLUB_CACHE_COUNT];
static bool slub_ready;

static void *
slub_page_address(struct Page *page) {
    return (void *)(page2pa(page) + va_pa_offset);
}

void
slub_init(void) {
    if (slub_ready) {
        return;
    }
    assert(SLUB_HEADER_SIZE < PGSIZE);
    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
        assert(slub_sizes[i] >= sizeof(void *) &&
               slub_sizes[i] % SLUB_ALIGN == 0);
        slub_caches[i].object_size = slub_sizes[i];
        list_init(&slub_caches[i].partial);
        list_init(&slub_caches[i].full);
    }
    slub_ready = 1;
}

static struct slub_slab *
slub_new_slab(struct slub_cache *cache) {
    struct Page *page = alloc_pages(1);
    if (page == NULL) {
        return NULL;
    }

    struct slub_slab *slab = slub_page_address(page);
    list_init(&slab->link);
    slab->cache = cache;
    slab->page = page;
    slab->freelist = NULL;
    slab->inuse = 0;
    slab->capacity = (PGSIZE - SLUB_HEADER_SIZE) / cache->object_size;
    slab->nr_pages = 1;
    assert(slab->capacity > 0);

    char *objects = (char *)slab + SLUB_HEADER_SIZE;
    for (size_t i = slab->capacity; i > 0; i--) {
        void *object = objects + (i - 1) * cache->object_size;
        *(void **)object = slab->freelist;
        slab->freelist = object;
    }
    list_add(&cache->partial, &slab->link);
    return slab;
}

static void *
slub_alloc_large(size_t size) {
    if (size > (size_t)-1 - SLUB_HEADER_SIZE - (PGSIZE - 1)) {
        return NULL;
    }
    size_t nr_pages = (size + SLUB_HEADER_SIZE + PGSIZE - 1) / PGSIZE;
    struct Page *page = alloc_pages(nr_pages);
    if (page == NULL) {
        return NULL;
    }

    struct slub_slab *slab = slub_page_address(page);
    list_init(&slab->link);
    slab->cache = NULL;
    slab->page = page;
    slab->freelist = NULL;
    slab->inuse = 1;
    slab->capacity = 1;
    slab->nr_pages = nr_pages;
    return (char *)slab + SLUB_HEADER_SIZE;
}

void *
slub_alloc(size_t size) {
    assert(slub_ready);
    if (size == 0) {
        return NULL;
    }

    for (size_t i = 0; i < SLUB_CACHE_COUNT; i++) {
        struct slub_cache *cache = &slub_caches[i];
        if (size > cache->object_size) {
            continue;
        }

        struct slub_slab *slab;
        if (list_empty(&cache->partial)) {
            slab = slub_new_slab(cache);
            if (slab == NULL) {
                return NULL;
            }
        } else {
            slab = to_struct(list_next(&cache->partial), struct slub_slab, link);
        }

        void *object = slab->freelist;
        assert(object != NULL && slab->inuse < slab->capacity);
        slab->freelist = *(void **)object;
        slab->inuse++;
        if (slab->inuse == slab->capacity) {
            list_del_init(&slab->link);
            list_add(&cache->full, &slab->link);
        }
        return object;
    }
    return slub_alloc_large(size);
}

void
slub_free(void *ptr) {
    if (ptr == NULL) {
        return;
    }
    assert(slub_ready);

    struct slub_slab *slab = (struct slub_slab *)ROUNDDOWN((uintptr_t)ptr, PGSIZE);
    assert(slab->page != NULL && slab->inuse > 0);
    if (slab->cache == NULL) {
        assert(ptr == (char *)slab + SLUB_HEADER_SIZE);
        free_pages(slab->page, slab->nr_pages);
        return;
    }

    struct slub_cache *cache = slab->cache;
    uintptr_t offset = (uintptr_t)ptr - ((uintptr_t)slab + SLUB_HEADER_SIZE);
    assert((uintptr_t)ptr >= (uintptr_t)slab + SLUB_HEADER_SIZE &&
           offset < slab->capacity * cache->object_size &&
           offset % cache->object_size == 0);

    if (slab->inuse == slab->capacity) {
        list_del_init(&slab->link);
        list_add(&cache->partial, &slab->link);
    }
    *(void **)ptr = slab->freelist;
    slab->freelist = ptr;
    slab->inuse--;
    if (slab->inuse == 0) {
        list_del_init(&slab->link);
        free_pages(slab->page, 1);
    }
}

/* The checks below use request sizes, not private PMM block sizes. */
#define SLUB_TEST_OBJECT_SIZE 64
#define SLUB_TEST_CAPACITY \
    ((PGSIZE - SLUB_HEADER_SIZE) / SLUB_TEST_OBJECT_SIZE)

static uintptr_t
slub_test_page(void *ptr) {
    return ROUNDDOWN((uintptr_t)ptr, PGSIZE);
}

static void
slub_test_write(void *ptr, size_t size, unsigned char tag) {
    assert(ptr != NULL && (uintptr_t)ptr % SLUB_ALIGN == 0);
    for (size_t i = 0; i < size; i++) {
        ((unsigned char *)ptr)[i] = (unsigned char)(tag + i * 17);
    }
}

static void
slub_test_read(void *ptr, size_t size, unsigned char tag) {
    for (size_t i = 0; i < size; i++) {
        assert(((unsigned char *)ptr)[i] == (unsigned char)(tag + i * 17));
    }
}

static void
slub_test_disjoint(void *a, size_t a_size, void *b, size_t b_size) {
    uintptr_t a_start = (uintptr_t)a, b_start = (uintptr_t)b;
    assert(a_start + a_size <= b_start || b_start + b_size <= a_start);
}

static void
slub_test_sizes(void) {
    size_t before = nr_free_pages();
    const size_t sizes[] = {
        1, 15, 16, 17, 31, 32, 33, 63, 64, 65, 127, 128, 129,
        255, 256, 257, 511, 512, 513, 1023, 1024, 1025,
        2047, 2048, 2049, 3071, 3072, 3073,
        PGSIZE - SLUB_HEADER_SIZE,
    };
    enum { count = sizeof(sizes) / sizeof(sizes[0]) };
    void *objects[count];

    assert(slub_alloc(0) == NULL);
    for (size_t i = 0; i < count; i++) {
        objects[i] = slub_alloc(sizes[i]);
        slub_test_write(objects[i], sizes[i], (unsigned char)i);
        for (size_t j = 0; j < i; j++) {
            slub_test_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
        }
    }
    for (size_t i = 0; i < count; i++) {
        slub_test_read(objects[i], sizes[i], (unsigned char)i);
    }
    for (size_t i = count; i > 0; i--) {
        slub_free(objects[i - 1]);
    }
    assert(nr_free_pages() == before);
}

static void
slub_test_same_cache(void) {
    size_t before = nr_free_pages();
    void *first[SLUB_TEST_CAPACITY];
    void *reused[SLUB_TEST_CAPACITY];
    void *second[SLUB_TEST_CAPACITY];
    size_t reused_count = 0;

    /* Fill one page. Every returned object must be distinct and writable. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
        first[i] = slub_alloc(SLUB_TEST_OBJECT_SIZE);
        slub_test_write(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
        if (i != 0) {
            assert(slub_test_page(first[i]) == slub_test_page(first[0]));
        }
        for (size_t j = 0; j < i; j++) {
            slub_test_disjoint(first[i], SLUB_TEST_OBJECT_SIZE,
                               first[j], SLUB_TEST_OBJECT_SIZE);
        }
    }
    assert(nr_free_pages() == before - 1);

    /* Free alternate slots. Replacements must come from those slots only. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_free(first[i]);
        assert(nr_free_pages() == before - 1);
    }
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_test_read(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
    }
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i += 2) {
        void *ptr = slub_alloc(SLUB_TEST_OBJECT_SIZE);
        bool was_freed = 0;
        for (size_t j = 0; j < SLUB_TEST_CAPACITY; j += 2) {
            was_freed |= ptr == first[j];
        }
        assert(was_freed);
        for (size_t j = 0; j < reused_count; j++) {
            assert(ptr != reused[j]);
        }
        reused[reused_count++] = ptr;
        slub_test_write(ptr, SLUB_TEST_OBJECT_SIZE, (unsigned char)(i + 91));
    }
    assert(nr_free_pages() == before - 1);
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_test_read(first[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)i);
    }

    /* A full slab forces a second page. Emptying one must spare the other. */
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
        second[i] = slub_alloc(SLUB_TEST_OBJECT_SIZE);
        slub_test_write(second[i], SLUB_TEST_OBJECT_SIZE, (unsigned char)(i + 137));
        assert(slub_test_page(second[i]) != slub_test_page(first[0]));
        if (i != 0) {
            assert(slub_test_page(second[i]) == slub_test_page(second[0]));
        }
    }
    assert(nr_free_pages() == before - 2);
    for (size_t i = 1; i < SLUB_TEST_CAPACITY; i += 2) {
        slub_free(first[i]);
        assert(nr_free_pages() == before - 2);
    }
    for (size_t i = 0; i + 1 < reused_count; i++) {
        slub_free(reused[i]);
        assert(nr_free_pages() == before - 2);
    }
    slub_free(reused[reused_count - 1]);
    assert(nr_free_pages() == before - 1);
    for (size_t i = 0; i < SLUB_TEST_CAPACITY; i++) {
        slub_test_read(second[i], SLUB_TEST_OBJECT_SIZE,
                       (unsigned char)(i + 137));
    }
    for (size_t i = 0; i + 1 < SLUB_TEST_CAPACITY; i++) {
        slub_free(second[i]);
        assert(nr_free_pages() == before - 1);
    }
    slub_free(second[SLUB_TEST_CAPACITY - 1]);
    assert(nr_free_pages() == before);
}

static void
slub_test_cache_isolation(void) {
    size_t before = nr_free_pages();
    void *small0 = slub_alloc(32), *small1 = slub_alloc(32);
    void *medium0 = slub_alloc(256), *medium1 = slub_alloc(256);
    slub_test_write(small0, 32, 11);
    slub_test_write(small1, 32, 12);
    slub_test_write(medium0, 256, 13);
    slub_test_write(medium1, 256, 14);
    assert(nr_free_pages() == before - 2);
    slub_test_disjoint(small0, 32, small1, 32);
    slub_test_disjoint(medium0, 256, medium1, 256);
    slub_test_disjoint(small1, 32, medium0, 256);

    slub_free(small1); /* Recover a nonfirst object's slab and cache. */
    assert(nr_free_pages() == before - 2);
    void *again = slub_alloc(32);
    assert(again == small1);
    slub_test_write(again, 32, 15);
    slub_test_read(small0, 32, 11);
    slub_test_read(medium0, 256, 13);
    slub_test_read(medium1, 256, 14);
    slub_free(small0);
    assert(nr_free_pages() == before - 2);
    slub_free(again);
    assert(nr_free_pages() == before - 1);
    slub_test_read(medium0, 256, 13);
    slub_test_read(medium1, 256, 14);
    slub_free(medium0);
    assert(nr_free_pages() == before - 1);
    slub_free(medium1);
    assert(nr_free_pages() == before);
}

static void
slub_test_large(void) {
    size_t before = nr_free_pages();
    size_t limit = slub_sizes[SLUB_CACHE_COUNT - 1];
    void *small = slub_alloc(16);
    slub_test_write(small, 16, 21);
    size_t with_small = nr_free_pages();
    assert(with_small == before - 1);

    const size_t sizes[] = { limit + 1, 2 * PGSIZE + 17 };
    for (size_t i = 0; i < sizeof(sizes) / sizeof(sizes[0]); i++) {
        size_t free_before_large = nr_free_pages();
        void *large = slub_alloc(sizes[i]);
        slub_test_write(large, sizes[i], (unsigned char)(31 + i));
        slub_test_disjoint(small, 16, large, sizes[i]);
        assert(nr_free_pages() < free_before_large);
        slub_test_read(large, sizes[i], (unsigned char)(31 + i));
        slub_test_read(small, 16, 21);
        slub_free(large);
        assert(nr_free_pages() == free_before_large);
        slub_test_read(small, 16, 21);
    }
    slub_free(small);
    assert(nr_free_pages() == before);
}

static void
slub_test_pmm_interaction(void) {
    size_t before = nr_free_pages();
    void *object = slub_alloc(SLUB_TEST_OBJECT_SIZE);
    slub_test_write(object, SLUB_TEST_OBJECT_SIZE, 73);
    assert(nr_free_pages() == before - 1);

    struct Page *page = alloc_pages(1);
    assert(page != NULL);
    void *page_data = slub_page_address(page);
    assert(slub_test_page(object) != (uintptr_t)page_data);
    assert(nr_free_pages() == before - 2);
    slub_test_write(page_data, PGSIZE, 74);
    slub_test_read(object, SLUB_TEST_OBJECT_SIZE, 73);

    slub_free(object);
    assert(nr_free_pages() == before - 1);
    slub_test_read(page_data, PGSIZE, 74);
    free_pages(page, 1);
    assert(nr_free_pages() == before);
}

static void
slub_test_mixed(void) {
    size_t before = nr_free_pages();
    enum { count = SLUB_TEST_CAPACITY + 5 };
    void *objects[count];
    size_t sizes[count];

    for (size_t i = 0; i < count; i++) {
        sizes[i] = i < SLUB_TEST_CAPACITY + 1 ? SLUB_TEST_OBJECT_SIZE :
                   i == SLUB_TEST_CAPACITY + 1 ? 1 :
                   i == SLUB_TEST_CAPACITY + 2 ? 255 :
                   i == SLUB_TEST_CAPACITY + 3 ? slub_sizes[SLUB_CACHE_COUNT - 1] :
                   slub_sizes[SLUB_CACHE_COUNT - 1] + 1;
        objects[i] = slub_alloc(sizes[i]);
        slub_test_write(objects[i], sizes[i], (unsigned char)(i + 51));
        for (size_t j = 0; j < i; j++) {
            slub_test_disjoint(objects[i], sizes[i], objects[j], sizes[j]);
        }
    }
    assert(slub_test_page(objects[0]) !=
           slub_test_page(objects[SLUB_TEST_CAPACITY]));
    for (size_t i = 1; i < count; i += 2) {
        slub_free(objects[i]);
    }
    for (size_t i = 0; i < count; i += 2) {
        slub_test_read(objects[i], sizes[i], (unsigned char)(i + 51));
    }
    for (size_t i = count; i > 0; i--) {
        if ((i - 1) % 2 == 0) {
            slub_free(objects[i - 1]);
        }
    }
    assert(nr_free_pages() == before);
}

void
slub_check(void) {
    assert(slub_ready);
    size_t free_before = nr_free_pages();
    cprintf("slub test: size classes, alignment and object isolation\n");
    slub_test_sizes();
    cprintf("slub test: freelist, slab extension and independent page reclaim\n");
    slub_test_same_cache();
    cprintf("slub test: cache isolation and pointer-based release\n");
    slub_test_cache_isolation();
    cprintf("slub test: large contiguous allocations and PMM restoration\n");
    slub_test_large();
    cprintf("slub test: coexistence with direct PMM allocation\n");
    slub_test_pmm_interaction();
    cprintf("slub test: mixed allocations and out-of-order release\n");
    slub_test_mixed();
    assert(nr_free_pages() == free_before);
    cprintf("slub extended tests succeeded!\n");
}
