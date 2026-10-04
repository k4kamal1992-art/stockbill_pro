# Fixes applied to stockbill_pro_final

## Crash / build blockers
- `products` table had `shopId` twice -> database could not be created. Fixed.
- Tables `shops`, `staff`, `expenses`, `suppliers`, `supplier_products` were never created. Added (onCreate + migration, DB version 3).
- `isDeleted` was queried in ~25 places but no table had that column. Added to `products`, `bills`, `customers`.
- `BillModel.toMap()` included the `items` list, which sqflite cannot insert. Added `toDbMap()` and used it for the `bills` table.
- `pubspec.yaml`: declared `assets/lang/`; removed asset folders that don't exist; added `path`, `flutter_localizations`, `crypto`; `intl: any` (flutter_localizations decides the version); commented out unused `mobile_scanner` / `bluetooth_print`.
- `billing_service.dart`: missing `sqflite` import.
- `ShopProvider`, `StaffProvider`, `ExpenseProvider`, `SupplierProvider` registered in `AppProviders`.
- Missing methods added: `BillRepository.getBillByNumber`, `CustomerRepository.getTotalDueAmount`, `CustomerRepository.recordPayment`.

## Logic
- Credit sales now add the unpaid amount to the customer's due (creates the customer by phone if new). Returns reverse it.
- `processReturn` refuses a bill that was already returned; skips products that no longer exist.
- Bill numbers use a 3-letter prefix (GRO-0001, GAR-0001...) - the old 1-letter prefix made grocery/garments collide on the UNIQUE column.
- Customer due is consistently "current outstanding" (`totalDue`); `getCustomersWithDue` fixed to match the UI.
- `PRAGMA foreign_keys = ON` so ON DELETE CASCADE works.

## Security / release
- PIN: no more hard-coded `1234`. Salted SHA-256 hash in SharedPreferences, created on first run, 30s cool-down after 5 wrong tries.
- App flow wired: Splash -> (first run) business select -> store setup -> set PIN -> dashboard; later runs -> PIN -> dashboard.
- Keystore passwords removed from BUILD_GUIDE; uses `key.properties` (+ `.gitignore`).
- Removed `MANAGE_EXTERNAL_STORAGE`; backups go to the app's own folder.

## Tests
- Old tests called methods that didn't exist. Rewritten against the real API, plus `database_flow_test.dart` (sale, oversell, return, double return, due, payment).

## NOT done (still open)
- Barcode scanner screen and Bluetooth printing are still placeholders.
- Many UI strings are hard-coded Bengali instead of using the translation files.
- Store setup screen still shows sample values (not editable inputs).
- No Flutter SDK was available when these fixes were made: nothing has been compiled or run. Run `flutter pub get && flutter analyze && flutter test` first.

## GitHub
- Added `.github/workflows/flutter.yml` (analyze + test + debug APK on every push to `main`).
