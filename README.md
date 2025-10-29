# flutterpos

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Responsive & Orientation

This project now includes a small responsive helper widget to make the UI adapt
to portrait and landscape orientations and to different screen sizes (phone,
tablet, desktop).

- `lib/widgets/responsive_layout.dart` provides `ResponsiveLayout` which
	exposes simple breakpoints and a `columns` hint. Wrap pages or the app
	entry with `ResponsiveLayout` and adapt layouts using the `columns` value.

- `lib/main.dart` is updated to wrap the home screen with `ResponsiveLayout`.

Platform orientation tips:

- Android: The default activity allows both portrait and landscape. If you
	constrained orientation previously, remove `android:screenOrientation` or
	set it to `unspecified` in `android/app/src/main/AndroidManifest.xml`.

- iOS: In Xcode / `ios/Runner/Info.plist` ensure the supported interface
	orientations include both portrait and landscape entries (UIInterfaceOrientatio
	ns). For Flutter apps this is typically configured in the Xcode project
	deployment info.

Notes:
- The responsive helper is intentionally small — for full responsiveness you
	should audit key screens (product grid, cart sidebar, table grid) and use
	the `columns` or `isPortrait` values to switch between stacked and side-by-side
	layouts.
