# Hotel Booking API — QA Testing & Defect Analysis Report

**Project:** Zunft Hotel Booking API  
**Repository:** https://github.com/Zunft-Inc/qa-home-task  
**Testing type:** Manual API testing, automated testing, static source code review  
**Environment:** Local development environment  
**Base URL:** `http://localhost:3001`  
**Report date:** November 6, 2026

---

# 1. Executive Summary

The Zunft Hotel Booking API was evaluated through manual API testing, automated tests using Python and pytest, and static analysis of the API route implementation.

The testing focused on:
- Authentication and authorization.
- Reservation creation, retrieval, updating, and deletion.
- Input validation.
- HTTP response codes.
- Query parameters and filtering.
- API contract compliance.
- Potential security vulnerabilities.

The automated test execution produced the following results:

| Result | Count |
|---|---:|
| Tests collected | 8 |
| Passed | 5 |
| Failed | 3 |

The failed tests exposed discrepancies between the documented API behavior and actual responses.

Additional manual testing identified an incorrect DELETE response status and unexpected behavior in reservation filtering.

Static source code analysis identified 10 potential defects, including authentication weaknesses, validation issues, incorrect filtering logic, and HTTP status code inconsistencies.

**Important:** Runtime-confirmed findings and source-code-only findings are reported separately. Static findings have not all been reproduced against the running API.

# 2. Testing Environment

| Component | Configuration |
|---|---|
| Operating system | Windows |
| API environment | Local server |
| API address | localhost:3001 |
| Programming language | Python |
| Test framework | pytest 9.2.0 |
| Python version | 3.14.0 |
| HTTP testing | PowerShell / curl |
| Source reviewed | routes/index.js |
| Repository branch reviewed | main |

# 3. Testing Scope

The following areas were covered:

1. Authentication — valid and invalid login credentials.
2. Authorization — access to protected reservation operations.
3. GET operations — retrieving reservations and filtering.
4. POST operations — creating reservations and checking validation.
5. PATCH operations — updating reservation data.
6. DELETE operations — deleting existing reservations.
7. Negative scenarios — invalid credentials, missing records, and invalid input.
8. Static analysis — reviewing route implementations against the documented API contract.

# 4. Confirmed Runtime Defects

These findings are supported by actual HTTP responses from the running API or automated test execution.

## BUG-001 — Reservation filtering returns unexpected results

**Severity:** Medium (subject to confirmation of the exact filter semantics)  
**Priority:** P2  
**Endpoint:** GET /reservations?checkIn=...

**Expected:** Reservations should match the documented checkIn filtering criteria.

**Actual:** A request for `checkIn=2021-01-02` returned reservation IDs `[1, 4, 5, 6, 8, 10]`.

Further investigation showed that reservation 1 had:
- Actual checkIn: `2024-08-10`
- Actual checkOut: `2026-08-03`

**HTTP status:** 200 OK

**Impact:** The returned collection may not correspond to the requested filter criteria.

**Evidence:** Actual HTTP response and subsequent retrieval of reservation 1.

**Note:** The source implementation uses a strict greater-than comparison for checkIn. The exact expected filtering semantics should be interpreted against the task README before final severity is assigned.

## BUG-002 — Invalid login returns HTTP 200 instead of HTTP 401

**Severity:** Medium  
**Priority:** P2  
**Endpoint:** POST /login

**Expected:** Invalid credentials should return:

`HTTP 401 Unauthorized`

Response body:

```json
{
  "reason": "Bad credentials"
}
```

**Actual:** Invalid credentials return:

`HTTP 200 OK`

Response body:

```json
{
  "reason": "Bad credentials"
}
```

**Test scenarios:**
- Valid username with incorrect password.
- Invalid username with an incorrect password.

Both scenarios returned HTTP 200.

Valid documented credentials were also tested and returned HTTP 200 with a non-empty authentication token.

**Impact:** Clients relying on HTTP status codes may incorrectly interpret failed authentication as a successful HTTP operation.

**Evidence:** Manual HTTP requests and automated pytest execution.

## BUG-003 — Retrieving a nonexistent reservation returns HTTP 200 with reservation data

**Severity:** High  
**Priority:** P1  
**Endpoint:** GET /reservations/:id

**Expected:** A nonexistent reservation should return:

`HTTP 404 Not Found`

**Actual:** A request for:

`GET /reservations/999999`

returned:

`HTTP 200 OK`

The response contained reservation data, including:

- First name: QA
- Last name: AutomationTest
- Total price: 250
- Check-in: 2027-01-01
- Check-out: 2027-01-05

**Impact:** Clients may receive incorrect reservation information when requesting a nonexistent resource. This creates a serious data integrity and API reliability concern.

**Evidence:** Automated pytest execution.

## BUG-004 — DELETE returns HTTP 201 instead of HTTP 204

**Severity:** Medium  
**Priority:** P2  
**Endpoint:** DELETE /reservations/:id

**Expected:** Successful deletion should return:

`HTTP 204 No Content`

with an empty response body.

**Actual:** Successful deletion returned:

`HTTP 201 Created`

Response body:

`Created`

**Reproduction evidence:**

```text
LOGIN: 200
CREATE: 200
DELETE: 201
DELETE BODY: 'Created'
```

A dedicated reservation was created for the test and then deleted.

**Impact:** The response contradicts the expected API contract and incorrectly indicates resource creation rather than successful deletion.

**Evidence:** Captured HTTP response from the local API.

# 5. Additional Static Source Code Findings

The following findings were identified by reviewing `routes/index.js` on the main branch.

They are additional candidates for defects and must not be interpreted as individually runtime-verified.

## BUG-005 — Health endpoint returns HTTP 201 instead of HTTP 200

**Severity:** Low  
**Priority:** P3  
**Endpoint:** GET /health  
**Source:** routes/index.js, line 67

**Expected:** HTTP 200 OK.

**Actual in source:** `res.sendStatus(201)`.

**Impact:** Monitoring systems expecting the standard health-check response may interpret the response as unexpected.

**Verification:** Static source review only.

## BUG-006 — Login accepts a password prefix

**Severity:** High  
**Priority:** P1  
**Endpoint:** POST /login  
**Source:** routes/index.js, line 675

**Expected:** The supplied password must match the configured password exactly.

**Actual in source:**

```javascript
MANAGER_PASSWORD.startsWith(password)
```

The comparison checks whether the configured password begins with the supplied password rather than checking exact equality.

For example, the supplied password `Hotel` would satisfy the prefix condition for `Hotel2024!`.

The authentication logic may therefore issue a valid session token for an incomplete password.

**Impact:** Potential authentication bypass and unauthorized access to protected operations.

**Verification:** Static source review only.

## BUG-007 — Basic Authentication ignores the password

**Severity:** Critical  
**Priority:** P1  
**Endpoints:** PUT, PATCH, DELETE /reservations/:id  
**Source:** routes/index.js, lines 38–43

**Expected:** Both username and password must be validated.

**Actual in source:** The `isAuthorised()` function extracts the username from the decoded Basic Authorization header and checks only whether it matches `MANAGER_USERNAME`.

The password is not compared against the configured password.

**Impact:** Potential authentication bypass affecting protected reservation operations.

**Verification:** Static source review only.

## BUG-008 — Last-name filtering is applied to firstName

**Severity:** Medium  
**Priority:** P2  
**Endpoint:** GET /reservations?lastName=...  
**Source:** routes/index.js, line 122

**Expected:** The lastName query parameter should filter reservations using the lastName field.

**Actual in source:**

```javascript
query.firstName = req.query.lastName;
```

**Impact:** Last-name searches may return incorrect results or fail to find matching reservations.

**Verification:** Static source review only.

## BUG-009 — Date filters exclude exact boundary dates

**Severity:** Medium  
**Priority:** P2  
**Endpoint:** GET /reservations  
**Source:** routes/index.js, lines 126–131

**Expected:** According to the reviewed contract, boundary dates should be included in the corresponding date filters.

**Actual in source:** The implementation uses strict `$gt` and `$lt` comparisons.

**Impact:** Reservations matching the exact boundary dates may be excluded from query results.

**Verification:** Static source review only.

## BUG-010 — POST validation failures return HTTP 500 instead of HTTP 400

**Severity:** Medium  
**Priority:** P2  
**Endpoint:** POST /reservations  
**Source:** routes/index.js, lines 348–365

**Expected:** Invalid client input should return HTTP 400 Bad Request.

**Actual in source:** The validation error branch calls:

```javascript
res.sendStatus(500);
```

**Impact:** Client-side input errors are incorrectly reported as server-side failures.

**Verification:** Static source review only.

## BUG-011 — PATCH does not explicitly invoke update validation

**Severity:** High  
**Priority:** P1  
**Endpoint:** PATCH /reservations/:id  
**Source:** routes/index.js, lines 563–581

**Expected:** Supplied fields should be validated before persistence. Partial updates should preserve omitted reservation fields.

**Actual in source:** The PATCH route calls `Reservation.update()` directly without invoking `validator.scrubAndValidateUpdate()`.

The PUT route invokes this validator.

**Impact:** Invalid reservation data may bypass route-level validation.

**Verification:** Static source review only. The model's internal validation behavior has not been established.

## BUG-012 — DELETE of a nonexistent reservation returns HTTP 405 instead of HTTP 404

**Severity:** Medium  
**Priority:** P2  
**Endpoint:** DELETE /reservations/:id  
**Source:** routes/index.js, lines 621–628

**Expected:** HTTP 404 Not Found.

**Actual in source:** The route returns HTTP 405 when the reservation cannot be found.

**Impact:** Incorrect HTTP status semantics make it harder for API clients to distinguish between a missing resource and an unsupported HTTP method.

**Verification:** Static source review only.

# 6. Automated Test Execution

Command:

```powershell
py -m pytest tests/test_api.py -v
```

Execution summary:

```text
8 collected
5 passed
3 failed
```

The three failures were associated with:

1. A nonexistent reservation returning HTTP 200 instead of HTTP 404.
2. Invalid password returning HTTP 200 instead of HTTP 401.
3. Invalid username returning HTTP 200 instead of HTTP 401.

These failures represent observed discrepancies between the expected behavior encoded in the tests and the actual API responses.

The test suite is not fully passing because the API currently exhibits the reported defects. The failing tests should be retained as regression checks rather than modified to accept the incorrect behavior.

# 7. Overall Findings

The assessment identified several areas requiring improvement.

**Authentication and authorization**
- Incorrect HTTP status for invalid login attempts.
- Potential password-prefix authentication bypass.
- Potential Basic Authentication password validation bypass.

**Reservation management**
- Unexpected reservation filtering results.
- Incorrect response for nonexistent reservation IDs.
- Incorrect successful DELETE response status.
- Potential PATCH validation bypass.

**Input validation and HTTP semantics**
- Potential incorrect validation failure status.
- Incorrect date boundary comparisons.
- Incorrect status codes for missing resources.
- Incorrect health endpoint status.

The authentication-related static findings deserve particular attention because they may affect the security of protected reservation operations.

# 8. Limitations

- Not all static findings were reproduced against a running API.
- Static analysis was based on the `routes/index.js` implementation on the main branch.
- The complete model-level validation behavior was not established.
- The automated suite contains 8 tests and does not provide exhaustive endpoint coverage.
- The public GitHub fork and publication of the final package have not been confirmed.
- No claim is made that all possible API defects have been identified.

# 9. Conclusion

The QA assessment demonstrated practical experience with manual API testing, automated test execution, HTTP response analysis, negative testing, and static source code review.

Several discrepancies were reproduced against the running API, while additional potential defects were identified through source inspection.

The most significant concerns relate to authentication validation, incorrect handling of nonexistent resources, and inconsistent HTTP response codes.

The findings have been organized according to their verification status to ensure transparency and prevent unverified source-code observations from being presented as confirmed runtime defects.

**Final assessment:** The API requires further investigation and corrective action, particularly in authentication, reservation retrieval, input validation, and HTTP status code handling.

---

**Prepared as part of the Zunft Hotel Booking API QA Home Assignment.**