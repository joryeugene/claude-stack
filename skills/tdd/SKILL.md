---
name: tdd
description: Use when writing any tests or implementing any feature. Write the failing test first. Never write implementation before a failing test exists.
---

# Test-Driven Development

Write the failing test first. This is not optional.

## The Cycle

**Red**: Write a test that fails for the right reason.
**Green**: Write the minimum code to make it pass.
**Refactor**: Clean up. Run it. Still passes.

Then repeat for the next behavior.

### Step 1: Write the failing test

Before touching implementation code, write a test that:
- Names the contract (what does this function promise?)
- Fails with a clear assertion error, not an import or syntax error
- Would pass if the correct implementation existed

Run it. Watch it fail. If it does not fail, the test is wrong.

### Step 2: Write minimum passing code

Write the smallest implementation that makes the test pass. No more.

Run it. Watch it pass.

### Step 3: Refactor

Clean up both test and implementation. No logic changes.

Run it. Still passes.

---

## Contract Checks (Before Any Test)

Answer these three questions before writing any test.

**1. The Contract Question**

"What does this code PROMISE to do?"

Not "what does it do" but "what would break downstream if it stopped doing it?"

**2. The Deletion Test**

"If I delete this code, does this test fail?"

If no: the test is useless. Don't write it.

**3. The Three-Bug Question**

"What three real bugs would this test catch?"

If you can't name three: the test is too weak. Redesign it.

---

## What a Real Test Looks Like

```python
# CONTRACT: process_order charges the card and creates a record
def test_process_order_charges_card_and_records():
    # Use a real test server or service stub, not a mock that returns what you told it
    result = process_order(order_id="123", amount=50.00)

    # Verify the contract (what callers actually depend on)
    assert result.status == "completed"
    assert result.charge_id is not None

    # Verify side effects
    assert db.get_order("123").status == "completed"
    assert payment_log.last_charge() == 50.00

    # BUGS THIS CATCHES:
    # 1. Wrong charge amount
    # 2. Missing database write
    # 3. Status not set after successful charge
```

This test fails if `process_order` is deleted, its charge logic is broken, or its database write is skipped.

---

## The Forbidden Pattern

```python
# FORBIDDEN: mock-returns-mock
mock_service.charge.return_value = {"id": "ch_123"}
result = process_order(order_id="123", amount=50.00)
assert result.charge_id == "ch_123"  # circular: tests the mock, not the code
```

This passes if the real code is deleted. It configures a mock to return X, then asserts the result is X. It tests nothing.

---

## Anti-Patterns

- Writing implementation before a failing test. The discipline is the point.
- Mock-returns-mock: configuring a mock to return X, then asserting the result is X.
- "Was called" assertions without verifying what was called with or what the result was.
- Only testing the happy path. Error paths have contracts too.
- Coupling tests to implementation details (internal calls, private state).
- Writing tests after the fact to hit coverage numbers. These pass without catching anything.

---

## The Floor

A test suite that passes when code is deleted is not a safety net. It is theater. The cycle is: failing test first, minimum code to pass, refactor. In that order, every time. The deletion test is the quality gate: if you cannot delete a function and watch a test fail, the test is not covering that function.
