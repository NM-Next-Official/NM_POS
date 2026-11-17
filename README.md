# NM POS

Flutter point-of-sale and inventory app backed by PostgreSQL.

## First run

1. Start PostgreSQL and confirm the existing `users` table is available to the
   configured app account.
2. Run `flutter pub get`.
3. Start the app. After login, it creates the POS tables in `public`. To create
   them manually in pgAdmin, run [`database/pos_schema.sql`](database/pos_schema.sql).
4. Open **Inventory** and add products with a unique barcode, cost, selling
   price, opening quantity and reorder level.
5. Open **Point of sale**. Search and tap a product, use the phone camera where
   available, or scan through a USB/Bluetooth HID keyboard scanner. Configure
   the scanner to append Enter/CR after each scan.
6. In **Devices**, scan for a compatible thermal printer, choose it and send a
   test receipt. Completed sales print automatically when a default printer is
   selected.

## Database behavior

Products and sales are isolated per signed-in account. Checkout locks stock
rows, verifies availability, writes the sale and item snapshots, deducts
inventory, records stock movements and calculates discount and gross profit in
one PostgreSQL transaction.

## Hardware support

Barcode/QR scanners that act as a keyboard over USB HID or Bluetooth HID work
through the focused scan field. Camera scanning is available on supported phone
platforms. A serial-only scanner needs a device-specific integration.

The receipt integration prints ESC/POS-compatible thermal printers. USB is
supported on Android, Windows and macOS; Bluetooth Low Energy (BLE) is supported
on mobile and desktop platforms. iOS USB printing is not supported, and
Bluetooth Classic-only SPP printers may need a different integration. Use the
**Devices** screen's test receipt before taking sales.

## Current production boundary

The Flutter app still opens PostgreSQL connections directly using the
development settings in `lib/config/db_config.dart`. This is suitable only for
local development; a deployed app needs an authenticated backend API for all
database operations. The Gmail API OTP mailer setup is in
[`backend/README.md`](backend/README.md). Its OAuth client credentials and
refresh token belong in `backend/.env`, never in Flutter or source control. The
mail server must be running while the desktop app sends OTP email.
