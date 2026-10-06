# Material Requisition System

## Project layout

```text
backend/                 PHP and MySQL API shared by the web admin and Flutter app
web/                     PHP admin website
flutter_application_1/   Flutter client application
```

## MySQL configuration

Set the database connection once in `backend/config.php`. The API connects through
`backend/core/database.php`; both the admin website and Flutter app use that API.

The database schema used by the current API is documented in [`database/schema.sql`](database/schema.sql).
It covers user/admin accounts and sessions, categories, products (with current stock on the product row), requisitions and
line items, pickup QR/code records, status history, inventory movements, and notifications.
The schema file creates missing tables for a fresh database; it does not migrate or reconcile
an existing database. Back up an existing database and compare its table definitions before
applying structural changes, since the application may already have live records.
For installations that use the previous `inventory` table, the stock merge is prepared in
[`database/migrations/001_merge_inventory_into_products.sql`](database/migrations/001_merge_inventory_into_products.sql).
It copies stock into `products.stock_quantity` and drops `inventory`, so take a verified backup
and confirm that migration matches the current database before running it.
The five requisition states are `PENDING`, `APPROVED`, `ISSUED`, `CANCELLED`, and `REJECTED`.
For the previous MySQL schema, migrate existing status values with
[`database/migrations/002_simplify_requisition_status.mysql.sql`](database/migrations/002_simplify_requisition_status.mysql.sql).
Stock reservations use `products.reserved_quantity`; existing databases add it and reserve
pending requests with [`database/migrations/003_add_stock_reservations.mysql.sql`](database/migrations/003_add_stock_reservations.mysql.sql).
Run migrations 001, 002, and 003 in order after taking a verified backup. Check the final query
in migration 003 for older pending requests that together reserve more than physical stock.

## Local PHP server

From the project root, run:

```sh
php -S localhost:8000 -t .
```

Open `http://localhost:8000/web/`. The API is available under `/backend/`.

When deploying, publish `web/` and `backend/` under the same site root. Keep the
Flutter app's `AppConfig.baseUrl` pointed at the deployed `/backend` URL.
