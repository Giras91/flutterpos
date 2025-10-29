# FlutterPOS

FlutterPOS is a cross-platform Point-of-Sale application built with Flutter. It
supports three business modes (Retail, Cafe, Restaurant) and is designed to
work on desktop (Windows, Linux, macOS), mobile (Android/iOS) and web with a
focus on responsive layouts so the same app can be used on phones, tablets,
and fixed POS terminals.

This repository contains the application code, local persistence (SQLite
via `sqflite`/FFI and SharedPreferences), and a small visual/functional test
harness used during development.

## Key features

- Multi-mode POS
  - Retail mode: direct checkout and a cart sidebar
  - Cafe mode: order-by-number workflow with active orders list
  - Restaurant mode: table management and per-table orders
- Pricing & charges
  - Tax and service charge support (toggleable in Business Info)
  - Subtotal / tax / service / total calculation pattern centralized via
    `BusinessInfo` settings
- Persistence
  - Local SQLite database (schema, migrations, seeded defaults)
  - SharedPreferences for simple app-level flags (first-run setup, tutorial)
- Import / export
  - Import items from CSV/JSON
  - Export orders to CSV with metadata
- Printing & hardware
  - Receipt and kitchen printer configurations (network/USB/Bluetooth)
  - Dual-display customer screen support (for supported hardware)
- Responsive UI
  - Defensive, scrollable layouts for small/narrow viewports (phone portrait)
  - `lib/widgets/responsive_layout.dart` provides small helpers and breakpoints
- Developer & testing
  - Visual/responsive tests (widget tests sized for phones/tablets/desktops)
  - Helper commands and a `Setup` flow for first-run configuration

## Project structure (high level)

```
lib/
  main.dart                 # App entry and startup wiring
  models/                   # Data models (Product, CartItem, Table, etc.)
  screens/                  # All UI screens (POS, Settings, Management)
  services/                 # DB helpers, ConfigService, ResetService, etc.
  widgets/                  # Reusable components (ProductCard, CartItemWidget)
test/                       # Widget/unit/visual tests
docs/                       # PR drafts, design notes
```

## Running locally

1. Install Flutter and required platform toolchains. See https://flutter.dev
2. Resolve dependencies:

```bash
flutter pub get
```

3. Run analyzer and tests:

```bash
flutter analyze
flutter test
```

4. Run the app (desktop example on Linux):

```bash
flutter run -d linux
```

Or run on an attached Android device:

```bash
flutter devices
flutter run -d <device-id>
```

## First run / Setup

On first start the app displays a lightweight `Setup` flow to collect your
store name and an initial admin account. These values are stored in
`SharedPreferences` and the admin account is persisted to the local database.
You can reset this with the Settings -> Reset Setup option (it supports an
optional database backup before resetting).

## Tests

- Widget tests live in `test/` and include responsive/visual checks. Run them
  with `flutter test`.
- If you modify layout code that affects screen size behavior, run the
  responsive widget tests at small sizes (360x800 or similar) to detect
  overflows early.

## Contributing

Contributions are welcome. Typical workflow:

1. Fork the repo and create a branch from `main`.
2. Make changes and add tests for new behavior.
3. Run `flutter analyze` and `flutter test` locally.
4. Push the branch and open a PR with a clear description. See
   `docs/PR_DRAFT.md` for a sample PR body used in this project.

## Where to look next

- `lib/screens/*` — POS screens and management UIs
- `lib/services/*` — Database helper, `ConfigService`, `ResetService`
- `lib/widgets/responsive_layout.dart` — small helper for breakpoints

## License & credits

This project is provided as-is for demonstration and development. Check the
repository for a LICENSE file if you plan to redistribute or relicense.

If you want me to push changes or open a PR (I already pushed `responsive/layout-fixes`), I can help with the PR description or CI next.
