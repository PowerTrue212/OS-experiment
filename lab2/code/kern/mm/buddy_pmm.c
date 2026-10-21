#include <buddy_pmm.h>
#include <list.h>
#include <pmm.h>
#include <stdio.h>

/* A free block's page count is stored in Page.property (unsigned int). */
#define BUDDY_MAX_ORDER (sizeof(unsigned int) * 8 - 1)

static list_entry_t buddy_free_lists[BUDDY_MAX_ORDER + 1];
static size_t buddy_free_count;

static size_t
buddy_block_size(size_t order) {
    return (size_t)1 << order;
}

static void
buddy_link(struct Page *base, size_t order) {
    base->property = buddy_block_size(order);
    SetPageProperty(base);
    list_add(&buddy_free_lists[order], &base->page_link);
}

/* Merge only with the same-size block at the PPN selected by XOR. */
static void
buddy_insert(struct Page *base, size_t order) {
    while (order < BUDDY_MAX_ORDER) {
        size_t size = buddy_block_size(order);
        size_t peer_ppn = page2ppn(base) ^ size;
        if (peer_ppn < nbase || peer_ppn >= npage ||
            size > npage - peer_ppn) {
            break;
        }

        struct Page *peer = pages + (peer_ppn - nbase);
        if (PageReserved(peer) || !PageProperty(peer) ||
            peer->property != size) {
            break;
        }

        list_del_init(&peer->page_link);
        ClearPageProperty(peer);
        peer->property = 0;
        if (peer < base) {
            base = peer;
        }
        order++;
    }
    buddy_link(base, order);
}

static void
buddy_init(void) {
    for (size_t order = 0; order <= BUDDY_MAX_ORDER; order++) {
        list_init(&buddy_free_lists[order]);
    }
    buddy_free_count = 0;
}

static void
buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0);
    for (struct Page *p = base; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }

    buddy_free_count += n;
    while (n != 0) {
        size_t order = BUDDY_MAX_ORDER;
        while (buddy_block_size(order) > n ||
               (page2ppn(base) & (buddy_block_size(order) - 1)) != 0) {
            order--;
        }
        buddy_insert(base, order);
        size_t size = buddy_block_size(order);
        base += size;
        n -= size;
    }
}

static struct Page *
buddy_alloc_pages(size_t n) {
    assert(n > 0);
    size_t order = 0;
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
        order++;
    }
    size_t size = buddy_block_size(order);
    if (size < n || size > buddy_free_count) {
        return NULL;
    }

    size_t found = order;
    while (found <= BUDDY_MAX_ORDER &&
           list_empty(&buddy_free_lists[found])) {
        found++;
    }
    if (found > BUDDY_MAX_ORDER) {
        return NULL;
    }

    struct Page *base = le2page(list_next(&buddy_free_lists[found]), page_link);
    list_del_init(&base->page_link);
    ClearPageProperty(base);
    base->property = 0;
    while (found > order) {
        found--;
        buddy_link(base + buddy_block_size(found), found);
    }
    buddy_free_count -= size;
    return base;
}

static void
buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0);
    size_t order = 0;
    while (order < BUDDY_MAX_ORDER && buddy_block_size(order) < n) {
        order++;
    }
    size_t size = buddy_block_size(order);
    assert(size >= n && (page2ppn(base) & (size - 1)) == 0);
    for (struct Page *p = base; p < base + size; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    buddy_free_count += size;
    buddy_insert(base, order);
}

static size_t
buddy_nr_free_pages(void) {
    return buddy_free_count;
}

static void
buddy_check_free_lists(void) {
    size_t total = 0;
    for (size_t order = 0; order <= BUDDY_MAX_ORDER; order++) {
        size_t size = buddy_block_size(order);
        list_entry_t *head = &buddy_free_lists[order];
        for (list_entry_t *le = list_next(head); le != head; le = list_next(le)) {
            struct Page *p = le2page(le, page_link);
            assert(PageProperty(p) && p->property == size);
            assert((page2ppn(p) & (size - 1)) == 0);
            assert(page2ppn(p) < npage && size <= npage - page2ppn(p));
            total += size;
        }
    }
    assert(total == buddy_free_count);
}

/* The isolated test arena should contain exactly this one free block. */
static void
buddy_check_only_block(struct Page *base, size_t order) {
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
        list_entry_t *head = &buddy_free_lists[i];
        if (i == order) {
            assert(list_next(head) == &base->page_link);
            assert(list_next(&base->page_link) == head);
            assert(PageProperty(base) && base->property == buddy_block_size(i));
        } else {
            assert(list_empty(head));
        }
    }
    assert(buddy_free_count == buddy_block_size(order));
    buddy_check_free_lists();
}

static void
buddy_check(void) {
    buddy_check_free_lists();
    size_t original_free = buddy_nr_free_pages();
    assert(original_free >= 32);

    /* Keep the upper half allocated so the arena cannot merge with outside
     * blocks while the real free lists are temporarily hidden. */
    struct Page *arena = buddy_alloc_pages(32);
    assert(arena != NULL && (page2ppn(arena) & 31) == 0);
    assert(buddy_nr_free_pages() == original_free - 32);

    list_entry_t saved_lists[BUDDY_MAX_ORDER + 1];
    size_t saved_free = buddy_free_count;
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
        saved_lists[i] = buddy_free_lists[i];
        list_init(&buddy_free_lists[i]);
    }
    buddy_free_count = 0;

    buddy_free_pages(arena, 16);
    buddy_check_only_block(arena, 4);

    /* One page must split a 16-page block through three levels. */
    assert(buddy_alloc_pages(1) == arena);
    assert(buddy_nr_free_pages() == 15);
    for (size_t order = 0; order < 4; order++) {
        struct Page *sibling = arena + buddy_block_size(order);
        list_entry_t *head = &buddy_free_lists[order];
        assert(list_next(head) == &sibling->page_link);
        assert(list_next(&sibling->page_link) == head);
        assert(PageProperty(sibling) &&
               sibling->property == buddy_block_size(order));
        assert((page2ppn(sibling) & (buddy_block_size(order) - 1)) == 0);
    }
    assert(list_empty(&buddy_free_lists[4]));
    buddy_check_free_lists();
    buddy_free_pages(arena, 1);
    buddy_check_only_block(arena, 4);

    /* Requests of 3 and 5 pages consume 4 and 8 pages respectively. */
    const size_t requests[] = {1, 2, 3, 5, 1};
    const size_t blocks[] = {1, 2, 4, 8, 1};
    struct Page *allocated[5];
    size_t remaining = 16;
    for (size_t i = 0; i < 4; i++) {
        allocated[i] = buddy_alloc_pages(requests[i]);
        assert(allocated[i] != NULL);
        assert((page2ppn(allocated[i]) & (blocks[i] - 1)) == 0);
        assert(allocated[i] >= arena && allocated[i] + blocks[i] <= arena + 16);
        for (size_t j = 0; j < i; j++) {
            assert(allocated[i] + blocks[i] <= allocated[j] ||
                   allocated[j] + blocks[j] <= allocated[i]);
        }
        remaining -= blocks[i];
        assert(buddy_nr_free_pages() == remaining);
        buddy_check_free_lists();
    }
    assert(remaining == 1);
    assert(buddy_alloc_pages(2) == NULL);
    assert(buddy_nr_free_pages() == remaining);
    buddy_check_free_lists();

    allocated[4] = buddy_alloc_pages(requests[4]);
    assert(allocated[4] != NULL && allocated[4] >= arena &&
           allocated[4] < arena + 16);
    for (size_t j = 0; j < 4; j++) {
        assert(allocated[4] + 1 <= allocated[j] ||
               allocated[j] + blocks[j] <= allocated[4]);
    }
    assert(buddy_nr_free_pages() == 0);
    assert(buddy_alloc_pages(1) == NULL);
    assert(buddy_nr_free_pages() == 0);
    remaining = 0;
    buddy_check_free_lists();

    for (size_t i = 5; i > 0; i--) {
        size_t j = i - 1;
        buddy_free_pages(allocated[j], requests[j]);
        remaining += blocks[j];
        assert(buddy_nr_free_pages() == remaining);
        buddy_check_free_lists();
    }
    buddy_check_only_block(arena, 4);

    /* Adjacent middle blocks are not buddies: 4..7 and 8..11. */
    struct Page *quarters[4];
    for (size_t i = 0; i < 4; i++) {
        quarters[i] = buddy_alloc_pages(4);
        assert(quarters[i] == arena + 4 * i);
        assert((page2ppn(quarters[i]) & 3) == 0);
        assert(buddy_nr_free_pages() == 12 - 4 * i);
    }
    buddy_free_pages(quarters[1], 4);
    buddy_free_pages(quarters[2], 4);
    assert(buddy_nr_free_pages() == 8);
    assert(PageProperty(quarters[1]) && quarters[1]->property == 4);
    assert(PageProperty(quarters[2]) && quarters[2]->property == 4);
    assert(buddy_alloc_pages(8) == NULL);
    assert(buddy_nr_free_pages() == 8);
    buddy_check_free_lists();

    /* Releasing the true buddy permits an 8-page allocation. */
    buddy_free_pages(quarters[0], 4);
    assert(PageProperty(arena) && arena->property == 8);
    assert(buddy_nr_free_pages() == 12);
    assert(buddy_alloc_pages(8) == arena);
    assert(buddy_nr_free_pages() == 4);
    buddy_free_pages(arena, 8);
    buddy_free_pages(quarters[3], 4);
    buddy_check_only_block(arena, 4);  /* 4+4, then 8+8 */

    assert(buddy_alloc_pages(16) == arena);
    assert(buddy_nr_free_pages() == 0);
    for (size_t i = 0; i <= BUDDY_MAX_ORDER; i++) {
        assert(list_empty(&buddy_free_lists[i]));
        buddy_free_lists[i] = saved_lists[i];
    }
    buddy_free_count = saved_free;
    buddy_free_pages(arena, 32);
    assert(buddy_nr_free_pages() == original_free);
    buddy_check_free_lists();
    cprintf("buddy_check() succeeded!\n");
}

const struct pmm_manager buddy_pmm_manager = {
    .name = "buddy_pmm_manager",
    .init = buddy_init,
    .init_memmap = buddy_init_memmap,
    .alloc_pages = buddy_alloc_pages,
    .free_pages = buddy_free_pages,
    .nr_free_pages = buddy_nr_free_pages,
    .check = buddy_check,
};
