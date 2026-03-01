# Kyrastay Backend (Foundation)

Rails API backend untuk KiraStay Property Management System.

## Tech Stack
- Ruby `2.7.8`
- Rails `6.1.7.10`
- PostgreSQL
- Redis + Sidekiq (job infrastructure)
- JWT Authentication
- Active Storage

## Implemented Foundation Modules
- Module 0: Auth + User CRUD + Log Activity write
- Module 1: Property Management (CRUD + detail tabs + CSV export)
- Module 2: Unit Management
- Module 3: Maintenance Requests
- Module 4: Financial Transactions
- Module 5: Billing & Payments (Xendit-ready + webhook endpoint)
- Module 6: Communication (scheduled/send-now foundation)
- Module 7: Log Activity list/filter

## Setup
```bash
bundle install
cp .env.example .env
bundle exec rails db:create db:migrate db:seed
bundle exec rails server
```

Base URL default:
`http://127.0.0.1:3000`

## Seed Accounts
- Admin: `admin@kyrastay.local` / `Password123!`
- Owner 1: `user1@kyrastay.local` / `Password123!`
- Owner 2: `user2@kyrastay.local` / `Password123!`
- Tenant 1: `tenant1@kyrastay.local` / `Password123!`
- Tenant 2: `tenant2@kyrastay.local` / `Password123!`
- Tenant Inactive: `tenant3@kyrastay.local` / `Password123!`

## Key API Groups
- Auth: `/api/v1/auth/*`
- Users: `/api/v1/users`
- Properties: `/api/v1/properties`
- Units: `/api/v1/units`
- Maintenance: `/api/v1/maintenance_requests`
- Financial: `/api/v1/financial_transactions`
- Payments: `/api/v1/payments`
- Communications: `/api/v1/communications`
- Log Activities: `/api/v1/log_activities`
- Webhook: `/api/v1/webhooks/xendit/invoice_paid`

## Postman
- Collection: `postman_collection.json`
- API + payload docs: `POSTMAN_COLLECTION.md`

## Notes
- `profile_picture` user bersifat opsional.
- Property mendukung field `rules`.
- Property `roomphotos` (alias foto properti) maksimum 10 file.
- Property `roomphotos` menerima: PDF, PNG, JPG, JPEG.
- Unit `roomphotos` (alias `photos`) menerima: PDF, PNG, JPG, JPEG.
