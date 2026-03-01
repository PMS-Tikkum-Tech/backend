# Kyrastay - Foundation API (Module 0-8)

Base URL:
`http://127.0.0.1:3000`

Gunakan token sesuai role:
- Admin endpoints: `Authorization: Bearer {{token-admin}}`
- Tenant endpoints: `Authorization: Bearer {{token-tenant}}`
- Owner endpoints: `Authorization: Bearer {{token-owner}}`

## Login Post-response Script (Postman)
Pasang script ini di endpoint login:

```javascript
const body = pm.response.json();
const token = body?.data?.token;
const role = body?.data?.user?.role;

if (token) pm.environment.set("token", token);
if (role === "admin" && token) pm.environment.set("token-admin", token);
if (role === "tenant" && token) pm.environment.set("token-tenant", token);
if (role === "owner" && token) pm.environment.set("token-owner", token);
```

## Module 0 - Auth & User Management

### Auth
- `POST /api/v1/auth/login`
- `GET /api/v1/auth/me`
- `DELETE /api/v1/auth/logout`

### User CRUD
- `GET /api/v1/users`
- `GET /api/v1/users/tenant`
- `GET /api/v1/users/admin`
- `GET /api/v1/users/owner`
- `GET /api/v1/users/:id`
- `POST /api/v1/users`
- `PATCH /api/v1/users/:id`
- `DELETE /api/v1/users/:id`

Role list endpoint:
- `/api/v1/users/tenant` hanya data user role `tenant`.
- `/api/v1/users/admin` hanya data user role `admin`.
- `/api/v1/users/owner` hanya data user role `owner`.
- Tetap support `page` dan `per_page`.

Create User payload:
```json
{
  "user": {
    "full_name": "Tenant Baru",
    "email": "tenant.baru@kyrastay.local",
    "password": "Password123!",
    "phone_number": "081234567890",
    "emergency_contact_name": "Ahmad",
    "emergency_contact_number": 81234567890,
    "relationship": "father",
    "nik": 32011906030003,
    "role": "tenant",
    "account_status": "active"
  }
}
```

Catatan field tambahan user:
- `emergency_contact_name` opsional.
- `emergency_contact_number` opsional (angka).
- `relationship` opsional.
- `nik` opsional (angka).

## Module 1 - Property Management

### Property CRUD
- `GET /api/v1/properties` (default `per_page=8`)
- `GET /api/v1/properties/:id`
- `POST /api/v1/properties`
- `PATCH /api/v1/properties/:id`
- `DELETE /api/v1/properties/:id`

Create Property payload:
```json
{
  "property": {
    "name": "Kinara Signature Kost",
    "property_type": "kost",
    "address": "Jl. Baru No. 1, Bandung",
    "description": "Properti baru untuk pengujian",
    "condition": "good",
    "facilities": ["wifi", "parking_area", "kitchen"],
    "rules": "don't smoke",
    "roomphotos": "",
    "user_id": 2
  }
}
```

Catatan upload:
- `roomphotos` bisa lebih dari 1 file.
- Format file: `pdf`, `png`, `jpg`, `jpeg`.
- Untuk upload file gunakan `form-data` key `property[roomphotos][]`.
- `user_id` pada property harus mengarah ke user dengan role `owner`.

### Property Detail Tabs
- `GET /api/v1/properties/:id/tenants` (default `per_page=5`)
- `GET /api/v1/properties/:id/units` (default `per_page=5`)
- `GET /api/v1/properties/:id/maintenance` (default `per_page=6`)

### Export CSV
- `GET /api/v1/properties/:id/export_tenants`
- `GET /api/v1/properties/:id/export_units`
- `GET /api/v1/properties/:id/export_maintenance`

## Module 2 - Unit Management

- `GET /api/v1/units`
- `GET /api/v1/units/property/:property_id`
- `GET /api/v1/units/:id`
- `POST /api/v1/units`
- `PATCH /api/v1/units/:id`
- `DELETE /api/v1/units/:id`

Create Unit payload:
```json
{
  "unit": {
    "property_id": 1,
    "name": "Unit New",
    "unit_type": "premium",
    "status": "vacant",
    "people_allowed": 2,
    "price": 5000000,
    "roomphotos": []
  }
}
```

Catatan upload unit photo:
- `roomphotos` bisa lebih dari 1 file.
- Format file: `pdf`, `png`, `jpg`, `jpeg`.
- Untuk upload file gunakan `form-data` key `unit[roomphotos][]`.

## Module 3 - Maintenance Requests

- `GET /api/v1/maintenance_requests` (default `per_page=8`)
- `GET /api/v1/maintenance_requests/:id`
- `POST /api/v1/maintenance_requests`
- `PATCH /api/v1/maintenance_requests/:id`
- `DELETE /api/v1/maintenance_requests/:id`
- `GET /api/v1/maintenance_requests/export`

Create Maintenance payload:
```json
{
  "maintenance_request": {
    "property_id": 1,
    "unit_id": 1,
    "tenant_id": 4,
    "issue": "Lampu mati",
    "category": "electrical",
    "description": "Lampu kamar tidak menyala",
    "priority": "medium",
    "status": "unassigned"
  }
}
```

## Module 4 - Financial Report

- `GET /api/v1/financial_transactions`
- `GET /api/v1/financial_transactions/dashboard`
- `GET /api/v1/financial_transactions/:id`
- `POST /api/v1/financial_transactions`
- `PATCH /api/v1/financial_transactions/:id`
- `DELETE /api/v1/financial_transactions/:id`
- `GET /api/v1/financial_transactions/export`

Create Financial payload:
```json
{
  "financial_transaction": {
    "property_id": 1,
    "unit_id": 1,
    "category": "income",
    "transaction_date": "2026-02-26",
    "amount": 3500000,
    "description": "Pembayaran sewa bulanan",
    "notes": "Transfer bank"
  }
}
```

Filter list financial:
- `category` = `income`/`expense`
- `property_id`
- `unit_id`
- `period` = `this_week`/`this_month`/`last_month`
- `date_from`, `date_to`
- `search`, `sort`, `page`, `per_page`

Dashboard chart:
- Endpoint: `GET /api/v1/financial_transactions/dashboard`
- Filters: `property_id`, `unit_id`, `period`, `date_from`, `date_to`, `search`
- Response:
  - `data.summary` untuk card:
    - `total_revenue`
    - `total_expenses`
    - `net_operating_income`
    - `outstanding_balances` (manual dari transaksi dengan kata
      `outstanding` pada `description/notes`)
  - `data.charts.monthly_revenue_vs_expense` untuk line chart bulanan
  - `data.charts.revenue_breakdown_by_category` untuk pie chart

Response list financial (`GET /api/v1/financial_transactions`) sekarang
memuat ringkasan dashboard pada `meta.summary`:
- `total_revenue`
- `total_expenses`
- `net_operating_income`
- `outstanding_balances`

Catatan upload receipt:
- Upload receipt gunakan `form-data`.
- Key file: `financial_transaction[receipt]`
- Format: `pdf`, `png`, `jpg`, `jpeg`.

Export:
- Endpoint `GET /api/v1/financial_transactions/export` mengembalikan file
  Excel `.xls`.

## Module 5 - Billing & Payments

- `GET /api/v1/payments`
- `GET /api/v1/payments/:id`
- `POST /api/v1/payments`
- `PATCH /api/v1/payments/:id`
- `DELETE /api/v1/payments/:id`
- `POST /api/v1/payments/:id/push_invoice`

Webhook:
- `POST /api/v1/webhooks/xendit/invoice_paid`

Create Payment payload:
```json
{
  "payment": {
    "property_id": 1,
    "unit_id": 1,
    "tenant_id": 4,
    "status": "waiting",
    "amount": 3500000,
    "due_date": "2026-03-10",
    "description": "Tagihan sewa bulanan"
  }
}
```

## Module 6 - Communication

- `GET /api/v1/communications`
- `GET /api/v1/communications/:id`
- `POST /api/v1/communications`
- `PATCH /api/v1/communications/:id`
- `DELETE /api/v1/communications/:id`

Create Communication payload:
```json
{
  "communication": {
    "property_id": 1,
    "audience_type": "some_tenants",
    "subject": "Pemberitahuan",
    "message": "Akan ada maintenance besok pagi",
    "send_schedule": "send_now",
    "tenant_ids": [4, 5]
  }
}
```

Contoh kirim terjadwal:
```json
{
  "communication": {
    "property_id": 1,
    "audience_type": "some_tenants",
    "subject": "Pengingat Pembayaran",
    "message": "Pembayaran sewa jatuh tempo tanggal 5.",
    "send_schedule": "schedule",
    "scheduled_at": "2026-03-05T09:00:00+07:00",
    "tenant_ids": [4, 5]
  }
}
```

Filter list communication:
- `status` = `scheduled`/`sent`/`failed`
- `property_type` (mendukung format UI: `Apartment` atau
  `studio apartment`; alias key `propertyType` juga didukung)
- `property_id`
- `audience_type`
- `date_from`, `date_to`
- `search` (subject, message, property)
- `sort` = `newest`/`oldest`/`scheduled_asc`/`scheduled_desc`
- `page`, `per_page`

Catatan send schedule:
- `send_schedule: "send_now"` untuk langsung kirim.
- `send_schedule: "schedule"` + `scheduled_at` untuk kirim terjadwal.
- `send_now: true` juga didukung sebagai alternatif.

Response list communication kini memuat field UI:
- `target_property` (nama properti atau `All Properties`)
- `audience_label` (`All Tenants`, `Private`, `Specific Tenants`)
- `audience` (alias dari `audience_label`)
- `date`, `time`, `date_time`, `recipient_count`

## Module 7 - Log Activities

- `GET /api/v1/log_activities` (default `per_page=12`)
- `GET /api/v1/log_activities/:id`

Filter yang tersedia:
- `module_name` / `module_page`
- `admin_id` / `admin_name`
- `log_action` (`create`/`update`/`delete`)
  : `action` tetap didukung jika dikirim sebagai query string.
- `date_from`, `date_to`
- `search` / `q` (description, admin, module, action)
- `sort` = `newest`/`oldest`/`timestamp_asc`
- `page`, `per_page`

Contoh query UI:
- `GET /api/v1/log_activities?page=1&per_page=12&sort=newest`
- `GET /api/v1/log_activities?module_page=Transaction&admin_name=Admin`

Field response untuk table UI:
- `timestamp` (`dd/mm/yyyy, hh:mm`)
- `admin_name`
- `module_page`
- `description` (ringkas, human-friendly)
- `action_label` + `action_badge_color`

Field response untuk detail/audit (`GET /api/v1/log_activities/:id`):
- `description` (ringkas)
- `description_detail` (lebih detail, dilokalkan)
- `description_raw` (teks asli dari log)

Meta pagination untuk footer UI:
- `showing_from`
- `showing_to`
- `total_count`

## Utility
- `GET /api/v1/health`

---

## Seed Accounts
- Admin: `admin@kyrastay.local` / `Password123!`
- User 1: `user1@kyrastay.local` / `Password123!`
- User 2: `user2@kyrastay.local` / `Password123!`
- Tenant 1: `tenant1@kyrastay.local` / `Password123!`
- Tenant 2: `tenant2@kyrastay.local` / `Password123!`
- Tenant Inactive: `tenant3@kyrastay.local` / `Password123!`
