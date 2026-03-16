---
name: security-review
description: Use before shipping any feature that handles user input, authentication, file paths, database queries, or sensitive data.
---

# Security Review

AI-generated code produces the same security failures repeatedly. This skill names them so they can be found before they ship.

## The Protocol

1. Enumerate trust boundaries: what data comes from users?
2. Trace each input from entry point to sink.
3. Check each named pattern against the code.

---

## Named Patterns

### SQL Injection

User input flows into a query via string formatting instead of parameterized statements.

```python
# Vulnerable
query = f"SELECT * FROM users WHERE email = '{user_input}'"
db.execute(query)
# Input: x' OR '1'='1 returns all rows.
# Input: '; DROP TABLE users; -- destroys data.
```

```python
# Safe
db.execute("SELECT * FROM users WHERE email = ?", (user_input,))
```

Every database driver supports parameterized queries. String formatting into SQL is never acceptable.

---

### Path Traversal

User input is used in a file path without normalization. Allows reading files outside the intended directory.

```python
# Vulnerable
filename = request.args.get("file")
path = f"/app/uploads/{filename}"
return open(path).read()
# Input: ../../etc/passwd reads system files.
```

```python
# Safe
import os
filename = request.args.get("file")
base = "/app/uploads"
path = os.path.realpath(os.path.join(base, filename))
if not path.startswith(base + os.sep):
    raise ValueError("Path traversal detected")
return open(path).read()
```

---

### IDOR (Insecure Direct Object Reference)

An object is accessed by ID without verifying the requesting user owns it.

```python
# Vulnerable
order = db.get_order(request.args["order_id"])
return render_order(order)
# Any authenticated user can read any order by guessing IDs.
```

```python
# Safe
order = db.get_order(request.args["order_id"])
if order.user_id != current_user.id:
    return 403
return render_order(order)
```

IDOR is the most common access control bug in AI-generated code. Check ownership on every object retrieval.

---

### Missing Rate Limits

Authentication and sensitive endpoints accept unlimited requests. Enables credential stuffing and brute force.

```python
# Vulnerable
@app.route("/login", methods=["POST"])
def login():
    user = authenticate(request.json["email"], request.json["password"])
    # No rate limiting. 10,000 password attempts per second is possible.
```

```python
# Safe
@app.route("/login", methods=["POST"])
@limiter.limit("5 per minute")
def login():
    user = authenticate(request.json["email"], request.json["password"])
```

Rate limits belong on: login, password reset, signup, OTP verification, any endpoint that sends email/SMS or burns API quota.

---

### Sensitive Data in Logs

Passwords, tokens, PII, and secrets printed to console or written to log files.

```python
# Vulnerable
logger.info(f"Login attempt: email={email}, password={password}")
logger.debug(f"Auth token: {token}")
```

```python
# Safe
logger.info(f"Login attempt: email={email}")
# Never log passwords, tokens, SSNs, credit card numbers, or health data.
```

Logging frameworks often serialize entire request objects. Confirm serializers exclude sensitive fields before shipping.

---

### TOCTOU (Time-of-Check-Time-of-Use)

A condition is checked, then the world changes before the action executes. The action runs on stale assumptions.

```python
# Vulnerable
if user.credits > 0:
    # Another request can decrement credits here before this line executes
    user.credits -= 1
    db.save(user)
    fulfill_order(user)
```

```python
# Safe: atomic check-and-decrement
rows_updated = db.execute("""
    UPDATE users SET credits = credits - 1
    WHERE id = ? AND credits > 0
""", user.id)
if rows_updated == 0:
    raise InsufficientCreditsError()
fulfill_order(user)
```

TOCTOU appears in: balance checks before charges, inventory checks before reservations, file existence checks before writes.

---

## Checklist

Before shipping any feature touching user input, auth, files, or databases:

- [ ] All SQL uses parameterized queries, no string formatting into queries
- [ ] All file paths are normalized and checked against a base directory
- [ ] Every object retrieval verifies ownership against the current user
- [ ] Auth and sensitive endpoints have rate limits
- [ ] No passwords, tokens, or PII appear in log statements
- [ ] Shared state mutations are atomic (no check-then-act on mutable shared state)

---

## Anti-Patterns

- Sanitizing input as the primary defense. Parameterization is the defense. Sanitization is a supplement.
- Checking authorization at the route level only. Ownership must be checked at the object level.
- Trusting data from your own database without re-checking permissions. The data was written in one context; the read may occur in another.
- Logging "for debugging" without removing it before shipping. Debug logs reach production.

---

## The Floor

Security is not added after features are built. Each named pattern above is an architectural decision made at implementation time. Find them in the diff before they ship. A single SQL injection in production costs more than reviewing every query in the PR.
