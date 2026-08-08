# Recycler

**Role:** `RECYCLER` · **Created by:** Municipal Admin · **Cannot self-register**

Buys segregated waste from citizens through the marketplace.

---

## Tasks

| # | Task | API | Status |
| --- | --- | --- | --- |
| 1 | Log in | `POST /auth/login` | Done |
| 2 | Browse recyclable material for sale | `GET /api/v1/listings` | Done |
| 3 | See one listing in detail | `GET /api/v1/listings/{id}` | Done |
| 4 | Express interest / purchase | `POST /api/v1/listings/{id}/interested` | Done |
| 5 | See everything they have bought | `GET /api/v1/listings/mine` | Done |
| 6 | Transaction history and balance | `GET /api/v1/wallet` | Done |

### Rules that apply

- Only a `RECYCLER` may buy (`403` for anyone else).
- Buying is an **atomic claim** — concurrent taps give exactly one buyer, the rest `409`.
- A seller cannot buy their own listing (`403`).
- On purchase, in one transaction: listing → `SOLD`, seller **credited**, buyer **debited**,
  and a `wallet_transactions` row is written for **both** sides.
- Recyclers are given a dummy float at registration (`RECYCLER_STARTING_BALANCE`, default
  10,000) so their first purchase does not push the balance negative.

### What a listing carries

Material, weight, price, derived `pricePerKg`, the scan photo when there is one (otherwise a
placeholder), a description, and the seller's name.

---

## Not built yet

| Task | Note |
| --- | --- |
| Real payments | The wallet is a dummy ledger — no gateway is integrated |
| Make an offer / negotiate price | Purchase is at the asking price only |
| Bulk purchase across listings | One listing per transaction |
| Recycler → collector pickup request | A recycler cannot request transport of what they bought |
| Material certificates / compliance docs | No document model |
