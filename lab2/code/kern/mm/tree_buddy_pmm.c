#include <tree_buddy_pmm.h>
#include <string.h>
#include <stdio.h>

/* The physical interval [DRAM_BASE, PHYSICAL_MEMORY_END) is one aligned
 * power-of-two root. Pages outside init_memmap remain unavailable in the tree.
 * One byte per node keeps the metadata independent of managed Page objects. */
#define TREE_PAGES ((PHYSICAL_MEMORY_END - DRAM_BASE) / PGSIZE)

enum tree_state {
    TREE_UNAVAILABLE,
    TREE_FREE,
    TREE_SPLIT,
    TREE_ALLOCATED,
};

static uint8_t tree_nodes[2 * TREE_PAGES];
static size_t tree_free_count;

static size_t
tree_left(size_t node) {
    return node * 2;
}

/* Add a possibly non-power-of-two free interval. Partial nodes are split;
 * both children must become free before their parent can be coalesced. */
static void
tree_add_free(uint8_t *nodes, size_t node, size_t start, size_t span,
              size_t first, size_t end) {
    if (end <= start || start + span <= first) {
        return;
    }
    if (first <= start && start + span <= end) {
        assert(nodes[node] == TREE_UNAVAILABLE);
        nodes[node] = TREE_FREE;
        return;
    }
    assert(span > 1);
    if (nodes[node] == TREE_UNAVAILABLE) {
        nodes[tree_left(node)] = TREE_UNAVAILABLE;
        nodes[tree_left(node) + 1] = TREE_UNAVAILABLE;
        nodes[node] = TREE_SPLIT;
    }
    assert(nodes[node] == TREE_SPLIT);
    tree_add_free(nodes, tree_left(node), start, span / 2, first, end);
    tree_add_free(nodes, tree_left(node) + 1, start + span / 2,
                  span / 2, first, end);
    if (nodes[tree_left(node)] == TREE_FREE &&
        nodes[tree_left(node) + 1] == TREE_FREE) {
        nodes[node] = TREE_FREE;
    }
}

/* A successful search occupies exactly one node of the requested block size. */
static bool
tree_allocate(uint8_t *nodes, size_t node, size_t start, size_t span,
              size_t wanted, size_t *result) {
    if (span < wanted || nodes[node] == TREE_UNAVAILABLE ||
        nodes[node] == TREE_ALLOCATED) {
        return 0;
    }
    if (span == wanted) {
        if (nodes[node] != TREE_FREE) {
            return 0;
        }
        nodes[node] = TREE_ALLOCATED;
        *result = start;
        return 1;
    }
    if (nodes[node] == TREE_FREE) {
        nodes[node] = TREE_SPLIT;
        nodes[tree_left(node)] = TREE_FREE;
        nodes[tree_left(node) + 1] = TREE_FREE;
    }
    assert(nodes[node] == TREE_SPLIT);
    return tree_allocate(nodes, tree_left(node), start, span / 2,
                         wanted, result) ||
           tree_allocate(nodes, tree_left(node) + 1, start + span / 2,
                         span / 2, wanted, result);
}

/* The node at (first, wanted) must be the exact allocation being released.
 * Only siblings under the same parent can merge, repeatedly up to the root. */
static void
tree_release(uint8_t *nodes, size_t node, size_t start, size_t span,
             size_t first, size_t wanted) {
    assert(start <= first && wanted <= span &&
           first - start <= span - wanted);
    if (start == first && span == wanted) {
        assert(nodes[node] == TREE_ALLOCATED);
        nodes[node] = TREE_FREE;
        return;
    }
    assert(nodes[node] == TREE_SPLIT && span > 1);
    size_t half = span / 2;
    if (first < start + half) {
        tree_release(nodes, tree_left(node), start, half, first, wanted);
    } else {
        tree_release(nodes, tree_left(node) + 1, start + half, half,
                     first, wanted);
    }
    if (nodes[tree_left(node)] == TREE_FREE &&
        nodes[tree_left(node) + 1] == TREE_FREE) {
        nodes[node] = TREE_FREE;
    }
}

static size_t
tree_count_free(const uint8_t *nodes, size_t node, size_t span) {
    switch (nodes[node]) {
    case TREE_UNAVAILABLE:
    case TREE_ALLOCATED:
        return 0;
    case TREE_FREE:
        return span;
    case TREE_SPLIT:
        assert(span > 1);
        assert(nodes[tree_left(node)] != TREE_FREE ||
               nodes[tree_left(node) + 1] != TREE_FREE);
        return tree_count_free(nodes, tree_left(node), span / 2) +
               tree_count_free(nodes, tree_left(node) + 1, span / 2);
    default:
        panic("tree buddy: invalid node state");
    }
}

static size_t
tree_round_up(size_t n) {
    size_t block = 1;
    while (block < n && block < TREE_PAGES) {
        block *= 2;
    }
    return block < n ? 0 : block;
}

static void
tree_buddy_init(void) {
    assert(TREE_PAGES > 0 && (TREE_PAGES & (TREE_PAGES - 1)) == 0);
    assert((nbase & (TREE_PAGES - 1)) == 0);
    memset(tree_nodes, TREE_UNAVAILABLE, sizeof(tree_nodes));
    tree_free_count = 0;
}

static void
tree_buddy_init_memmap(struct Page *base, size_t n) {
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
    size_t first = base - pages;
    assert(first < TREE_PAGES && n <= TREE_PAGES - first);
    assert(n <= npage - nbase - first);
    for (struct Page *p = base; p < base + n; p++) {
        assert(PageReserved(p));
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    tree_add_free(tree_nodes, 1, 0, TREE_PAGES, first, first + n);
    tree_free_count += n;
}

static struct Page *
tree_buddy_alloc_pages(size_t n) {
    assert(n > 0);
    size_t block = tree_round_up(n);
    if (block == 0 || block > tree_free_count) {
        return NULL;
    }
    size_t first;
    if (!tree_allocate(tree_nodes, 1, 0, TREE_PAGES, block, &first)) {
        return NULL;
    }
    tree_free_count -= block;
    return pages + first;
}

static void
tree_buddy_free_pages(struct Page *base, size_t n) {
    assert(n > 0 && base >= pages && base < pages + (npage - nbase));
    size_t block = tree_round_up(n);
    size_t first = base - pages;
    assert(block != 0 && first < TREE_PAGES && block <= TREE_PAGES - first);
    assert(block <= npage - nbase - first);
    assert((first & (block - 1)) == 0);
    /* Check the whole block before changing any Page descriptor. */
    for (struct Page *p = base; p < base + block; p++) {
        assert(!PageReserved(p) && !PageProperty(p));
    }
    tree_release(tree_nodes, 1, 0, TREE_PAGES, first, block);
    for (struct Page *p = base; p < base + block; p++) {
        p->flags = 0;
        p->property = 0;
        set_page_ref(p, 0);
    }
    tree_free_count += block;
}

static size_t
tree_buddy_nr_free_pages(void) {
    return tree_free_count;
}

static void
tree_buddy_check(void) {
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == tree_free_count);

    /* The 13-page range keeps its 8-, 4-, and 1-page pieces. */
    uint8_t small[32] = {0};
    size_t first;
    tree_add_free(small, 1, 0, 16, 0, 13);
    assert(tree_count_free(small, 1, 16) == 13);
    assert(!tree_allocate(small, 1, 0, 16, 16, &first));
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 0);
    assert(tree_allocate(small, 1, 0, 16, 4, &first) && first == 8);
    assert(tree_allocate(small, 1, 0, 16, 1, &first) && first == 12);
    assert(tree_count_free(small, 1, 16) == 0);
    tree_release(small, 1, 0, 16, 8, 4);
    tree_release(small, 1, 0, 16, 0, 8);
    tree_release(small, 1, 0, 16, 12, 1);
    assert(tree_count_free(small, 1, 16) == 13);

    /* An unaligned 13-page range must keep its leading three-page tail. */
    memset(small, TREE_UNAVAILABLE, sizeof(small));
    tree_add_free(small, 1, 0, 16, 3, 16);
    assert(tree_count_free(small, 1, 16) == 13);
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 8);
    assert(tree_allocate(small, 1, 0, 16, 4, &first) && first == 4);
    assert(tree_allocate(small, 1, 0, 16, 1, &first) && first == 3);
    assert(tree_count_free(small, 1, 16) == 0);

    /* Adjacent quarters 4..7 and 8..11 are not buddies. */
    memset(small, TREE_UNAVAILABLE, sizeof(small));
    tree_add_free(small, 1, 0, 16, 0, 16);
    for (size_t i = 0; i < 4; i++) {
        assert(tree_allocate(small, 1, 0, 16, 4, &first));
        assert(first == 4 * i);
    }
    tree_release(small, 1, 0, 16, 4, 4);
    tree_release(small, 1, 0, 16, 8, 4);
    assert(!tree_allocate(small, 1, 0, 16, 8, &first));
    assert(tree_count_free(small, 1, 16) == 8);
    tree_release(small, 1, 0, 16, 0, 4);
    assert(tree_allocate(small, 1, 0, 16, 8, &first) && first == 0);
    tree_release(small, 1, 0, 16, 0, 8);
    tree_release(small, 1, 0, 16, 12, 4);
    assert(small[1] == TREE_FREE);
    assert(tree_count_free(small, 1, 16) == 16);

    size_t before = tree_free_count;
    assert(before >= 13 && tree_round_up(3) == 4 && tree_round_up(5) == 8);
    struct Page *a = tree_buddy_alloc_pages(5);
    struct Page *b = tree_buddy_alloc_pages(3);
    struct Page *c = tree_buddy_alloc_pages(1);
    assert(a != NULL && b != NULL && c != NULL);
    assert(a + 8 <= b || b + 4 <= a);
    assert(a + 8 <= c || c + 1 <= a);
    assert(b + 4 <= c || c + 1 <= b);
    assert((page2ppn(a) & 7) == 0);
    assert((page2ppn(b) & 3) == 0);
    assert(tree_free_count == before - 13);
    tree_buddy_free_pages(a, 5);
    tree_buddy_free_pages(b, 3);
    tree_buddy_free_pages(c, 1);
    assert(tree_free_count == before);
    assert(tree_count_free(tree_nodes, 1, TREE_PAGES) == before);
    cprintf("tree_buddy_check() succeeded!\n");
}

const struct pmm_manager tree_buddy_pmm_manager = {
    .name = "tree_buddy_pmm_manager",
    .init = tree_buddy_init,
    .init_memmap = tree_buddy_init_memmap,
    .alloc_pages = tree_buddy_alloc_pages,
    .free_pages = tree_buddy_free_pages,
    .nr_free_pages = tree_buddy_nr_free_pages,
    .check = tree_buddy_check,
};
