---
name: performance
description: Use when code is slow, queries are taking too long, or you suspect N+1 queries, O(n squared) loops, missing indexes, or unbounded result sets.
---

# Performance

Measure first. Name the pattern. Fix one thing. Measure again.

Optimizing without a baseline is not performance work. It is guessing.

## Step 1: Measure First

Get a number before touching any code. The right tool depends on the layer:

| Layer | Tool |
|-------|------|
| Database query | `EXPLAIN ANALYZE` (Postgres), `EXPLAIN` (MySQL) |
| Python | `cProfile`, `py-spy` (sampling), `line_profiler` |
| Node.js | `--prof`, `clinic.js`, Chrome DevTools flame graph |
| HTTP endpoints | `ab`, `wrk`, `k6`, `hyperfine` |
| Frontend | Chrome Performance panel, Lighthouse |

Write down the number. Every optimization is measured against it.

## Step 2: Name the Pattern

AI-generated code produces the same performance failures repeatedly. Name the pattern before fixing it.

### N+1 Queries

One query fires to get N items. Then N more queries fire to get related data for each item.

```python
# N+1: one query per user
users = db.query("SELECT * FROM users")
for user in users:
    orders = db.query("SELECT * FROM orders WHERE user_id = ?", user.id)
    # With 1000 users: 1001 queries total.
```

```python
# Fixed: one JOIN
users = db.query("""
    SELECT u.*, o.id as order_id, o.total
    FROM users u
    LEFT JOIN orders o ON o.user_id = u.id
""")
```

Signs of N+1: query count in logs equals N+1 where N is a result set size. Response time grows linearly with data volume.

---

### O(n squared) Hidden in Loops

Nested iteration over the same collection. Quadratic growth. 100 items = 10,000 operations. 1000 items = 1,000,000.

```python
# O(n^2): finding duplicates by nested scan
duplicates = []
for i, item in enumerate(items):
    for j, other in enumerate(items):
        if i != j and item.id == other.id:
            duplicates.append(item)
```

```python
# O(n): use a set
seen = set()
duplicates = []
for item in items:
    if item.id in seen:
        duplicates.append(item)
    seen.add(item.id)
```

Signs of O(n squared): performance cliff when data size grows. A 10x larger dataset takes 100x longer.

---

### Missing Indexes

Queries that scan entire tables because the WHERE or JOIN column has no index.

```sql
-- Slow: full table scan
SELECT * FROM orders WHERE customer_email = 'user@example.com';
-- EXPLAIN shows: Seq Scan on orders, rows=500000
```

```sql
-- Fixed
CREATE INDEX idx_orders_customer_email ON orders (customer_email);
-- EXPLAIN now shows: Index Scan, rows=3
```

Which columns need indexes: foreign key columns, columns used in WHERE clauses, columns used in JOIN conditions. Use EXPLAIN to confirm.

---

### Unbounded Result Sets

Fetching all rows, then filtering in application code. Moves work from the database (optimized) to the application (unoptimized).

```python
# Unbounded: fetch everything, filter in Python
all_users = db.query("SELECT * FROM users")
active = [u for u in all_users if u.active and u.created_at > cutoff]
```

```python
# Fixed: filter in the database
active = db.query("""
    SELECT * FROM users
    WHERE active = true AND created_at > ?
    LIMIT 100
""", cutoff)
```

Signs: queries with no WHERE clause, SELECT * returning thousands of rows, result sets growing proportionally with table size.

---

### Synchronous I/O in Hot Paths

A blocking call (database query, HTTP request, file read) inside a request handler or tight loop.

```python
# Blocking: sequential external calls
def get_dashboard(user_id):
    profile = fetch_profile(user_id)       # 50ms
    orders = fetch_orders(user_id)          # 80ms
    notifications = fetch_notifications(user_id)  # 40ms
    return render(profile, orders, notifications)  # total: 170ms
```

```python
# Fixed: concurrent
async def get_dashboard(user_id):
    profile, orders, notifications = await asyncio.gather(
        fetch_profile(user_id),
        fetch_orders(user_id),
        fetch_notifications(user_id),
    )
    return render(profile, orders, notifications)  # total: ~80ms (longest call)
```

---

## Step 3: Fix One Thing

Fix the highest-impact pattern identified. Do not fix multiple patterns in the same change. This makes the measurement in Step 4 meaningful.

## Step 4: Measure Again

Get the same number captured in Step 1. Compare against the baseline.

If the number improved: the fix worked. Document what changed and by how much.

If the number did not improve: the pattern was named incorrectly. Return to Step 1 with the actual bottleneck.

---

## Anti-Patterns

- Optimizing without a baseline measurement. You cannot know if the fix worked.
- Fixing multiple patterns at once. You cannot attribute the improvement.
- Caching as a first resort. Cache correctness is hard. Fix the query first.
- Adding indexes speculatively. Each index slows writes. Add indexes for observed slow queries only.
- Rewriting in a faster language before profiling. 80% of performance problems are in 20% of the code. Find it first.

---

## The Floor

Performance work that does not start with a measurement is speculation. Name the pattern, fix one thing, measure. That is the whole protocol. If the number does not change, the pattern was named wrong. Start over with actual data.
