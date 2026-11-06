# Hotel Booking API — QA home task

A small Node/Express reservation API used as a **test object for a QA
assignment**. The API is intentionally shipped with defects. Your job is to
find and report them.

This README and the generated API documentation at `/apidoc` describe the
**expected** behaviour. Any difference between that specification and what the
running API actually does is a bug.

## Running it

Requirements: Node 22 (or Docker).

```
npm install
npm start
```

The API listens on http://localhost:3001 and `/` opens the API docs. The data
store is in memory and is seeded with 10 random reservations on every start;
restart the server to reset.

With Docker:

```
docker-compose build
docker-compose up
```

## Endpoints at a glance

| Method | Path               | Auth | Success | Errors                      |
|--------|--------------------|------|---------|-----------------------------|
| GET    | /health            | no   | 200     |                             |
| POST   | /login             | no   | 200 `{token}` | 401 `{reason}`        |
| GET    | /reservations      | no   | 200 `[{reservationId}]` | 400 bad date filter |
| GET    | /reservations/:id  | no   | 200 reservation | 404, 406            |
| POST   | /reservations      | no   | 200 `{reservationId, reservation}` | 400, 406 |
| PUT    | /reservations/:id  | yes  | 200 reservation | 400, 403, 404, 406  |
| PATCH  | /reservations/:id  | yes  | 200 reservation | 403, 404, 406       |
| DELETE | /reservations/:id  | yes  | 204 empty | 403, 404                  |

Anything not listed returns 404.

## Specification

### Authentication

`POST /login` with JSON `{"username": "manager", "password": "Hotel2024!"}`
returns `200` and `{"token": "<15 hex chars>"}`. Both values must match
exactly (case-sensitive, no partial matches). Any other credentials return
`401` with `{"reason": "Bad credentials"}`.

Write endpoints (PUT, PATCH, DELETE) accept **either**:

* a cookie `token=<token>` issued by `/login`, or
* `Authorization: Basic <base64(manager:Hotel2024!)>`.

A missing or invalid credential returns `403`. The Basic header must carry the
correct username *and* password.

### Reservation resource

```json
{
  "firstName": "Anna",
  "lastName": "Novak",
  "totalPrice": 111.5,
  "depositPaid": true,
  "stay": { "checkIn": "2013-02-23", "checkOut": "2014-10-23" },
  "specialRequests": "Late check-in"
}
```

Validation rules (apply to POST and PUT):

* `firstName`, `lastName`: required, non-empty strings. Surrounding whitespace
  is trimmed before storing.
* `totalPrice`: required number, `>= 0`. Decimal values are allowed and
  preserved exactly.
* `depositPaid`: required boolean. The stored value is always echoed back
  exactly as sent (in every response, including the create response).
* `stay.checkIn` and `stay.checkOut`: required, `CCYY-MM-DD`.
  `checkOut` must not be before `checkIn`.
* `specialRequests`: optional string.
* Unknown fields, including `reservationId`, are ignored.

A validation failure returns `400`.

### Ids

`reservationId` is assigned by the server, is a positive integer, is unique
and is **never reused**, even after a delete. A client can never choose or
overwrite an id. An id in the URL that is not a positive integer (e.g.
`/reservations/1abc`, `/reservations/-1`) is treated as not found (`404`).

### Listing and filtering: `GET /reservations`

Returns the ids of **all** reservations (no implicit limit). Optional query
parameters narrow the result; multiple parameters are combined with AND:

| Param       | Matches reservations whose…                                |
|-------------|------------------------------------------------------------|
| `firstName` | first name equals the value (case-insensitive, literal)    |
| `lastName`  | last name equals the value (case-insensitive, literal)     |
| `checkIn`   | check-in date is **on or after** the given `CCYY-MM-DD`    |
| `checkOut`  | check-out date is **on or before** the given `CCYY-MM-DD`  |

A `checkIn`/`checkOut` value that is not a valid date returns `400`.

### Content negotiation

Request bodies may be sent as `application/json`, `text/xml`,
`application/xml` (XML wrapped in a `<reservation>` element) or
`application/x-www-form-urlencoded`.

Responses honour the `Accept` header: `application/json` (default, also used
for `*/*` or no header), `application/xml`, `application/x-www-form-urlencoded`.
Standard `Accept` syntax must work (e.g. `application/json; charset=utf-8`,
`application/xml, text/plain`). The response `Content-Type` always matches the
format actually returned. An unsupported `Accept` value returns `406`.

### Update semantics

* `PUT /reservations/:id` replaces the reservation **in full**. Fields omitted
  from the payload (such as `specialRequests`) are removed from the stored
  reservation.
* `PATCH /reservations/:id` merges the supplied fields into the stored
  reservation. The merge is deep: `{"stay": {"checkIn": "2020-01-01"}}`
  changes only `checkIn` and keeps the existing `checkOut`.
* `DELETE /reservations/:id` removes the reservation and returns `204` with an
  empty body. A later `GET /reservations/:id` returns `404`.

Full request/response examples for every endpoint are in `/apidoc`
(`npm run build_docs` regenerates them from the comments in `routes/index.js`).

## Writing tests

`mocha`, `chai` and `supertest` are installed as dev dependencies. Put your
specs in `tests/` and run `npm test`.
