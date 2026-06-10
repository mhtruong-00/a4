# KIT305 Assignment 4 - Interior Design Quoting (Flutter)

A cross-platform Flutter port of my Assignment 3 iOS app. It's a quoting tool for
an interior fit-out business: you record customers (houses), the rooms in each
house, the windows and floor spaces in each room, pick a covering product for
each from the live product API, and then generate a shareable quote.

It reads and writes the **same Firestore database** as my Assignment 2/3 apps
(top-level `houses`, `rooms`, `windows`, `floorspaces` collections), so the data
model is shared across all three submissions.

## All the files were completed with support from coipilot

## Which device/simulator to test with

### Recommended platform (used during development)

Please test on **Web Chrome**, as this is the platform I primarily developed and tested on.

To run:

```bash
flutter pub get
flutter run -d chrome
```

### iOS Simulator

The app also supports the iOS Simulator. Firebase is configured using the provided
Firebase project (`test-minh-tute-5`), so Firestore works without additional setup.

To run on iOS:

```bash
flutter pub get
flutter run
```

(with an iOS Simulator already booted)

The app uses the **Photo Gallery** picker rather than the camera (per the A4 CRA
note regarding simulator camera limitations). The iOS Simulator includes sample
photos that can be used for testing image selection.

### Android

The Android `appId` in `firebase_options.dart` is intentionally a placeholder.
If you wish to run the application on Android, first configure Firebase for your
own project:

```bash
flutterfire configure
```

Without reconfiguring Firebase, Firestore connectivity will not work on Android.


## Screens and how they fit together

The app drills down through the data hierarchy House -> Room -> Window/Floor space,
then pulls in Products from the API and rolls everything up into a Quote.

1. **House list** (`house_list_screen.dart`) - home screen. Live list of every
   house from Firestore. `+` adds a house, the edit icon opens the editor, swipe
   left to delete. Tapping a house opens its **Room list**.
2. **House editor** (`house_edit_screen.dart`) - form to add/edit a house
   (customer name, address, notes).
3. **Room list** (`room_list_screen.dart`) - the rooms in one house. Add/edit/
   delete rooms. The app-bar receipt icon opens the **Quote** for the house.
   Tapping a room opens the **Room detail**.
4. **Room editor** (`room_edit_screen.dart`) - room name plus an optional room
   photo chosen from the gallery.
5. **Room detail** (`room_detail_screen.dart`) - two sections, **Windows** and
   **Floor Spaces**, for the room. Add/edit/delete items, each row showing its
   dimensions and chosen product.
6. **Window editor** (`window_edit_screen.dart`) - name, width/height (mm), a
   window product (opens the product picker, filtered for compatibility), a
   gallery photo, and a live price estimate.
7. **Floor space editor** (`floor_space_edit_screen.dart`) - the same idea but
   width/depth and floor products.
8. **Product picker** (`product_list_screen.dart`) - loads products from the
   KIT305 API for the right category, shows whether each window product fits the
   measured space, has a search box, and a variant chooser. Returns the choice
   to the editor.
9. **Quote** (`quote_screen.dart`) - loads all the rooms/windows/floors for the
   house, fetches product rates from the API (falling back to default rates if
   it's offline), and shows a per-room breakdown. You can toggle rooms in/out,
   enter a whole-house discount %, and share the result as a CSV file.

## References

- **KIT305 tutorial work** - the Flutter, Firestore and `image_picker` tutorials
  from the unit were used as the starting point (as allowed by the spec). The
  overall structure (models / services / screens, the Firestore listener
  pattern) follows the tutorial approach.
- **My own Assignment 3 (iOS) code** - I ported my own A3 Swift app to Flutter
  (same data model, product API, compatibility rules, quote maths and CSV
  format). Repo: https://github.com/mhtruong-00/kit305-Assignment3-mhtruong-00
- **Product API** - `https://utasbot.dev/kit305_2026/product` (provided by the
  unit) for the window/floor products and their prices.
- **GitHub Copilot** - I used GitHub Copilot inside the editor while porting the
  app from Swift to Dart. Because Copilot runs as an inline IDE assistant (not a
  chat transcript), there is no shareable conversation link to provide. I mainly
  used it to:
  - translate my Swift `QuoteCalculator`, `CompatibilityChecker` and
    `CSVExporter` logic into equivalent Dart,
  - scaffold the boilerplate of the `StatefulWidget` form screens, and
  - write the unit tests in `test/`.
  I reviewed and adjusted everything it suggested so it fit my data model and
  matched my A3 behaviour. I did not use ChatGPT for this assignment.

## Running the tests

The business logic (quote maths, product compatibility, JSON parsing and CSV
export) is covered by unit tests that don't need Firebase:

```bash
flutter test
```

## Third-party plugins

See `THIRD_PARTY_PLUGINS.md` for the list of pub.dev plugins, their authors, and
where each one is used.

## How the quote is calculated

The quote screen mirrors the maths from my Android/iOS apps:

- Each item's area is `width (m) x height-or-depth (m)`, and its cost is
  `area x rate`.
- The rate comes from the product's `price_per_sqm` (looked up from the API by
  product id). If a product has no rate, or the API is offline, a **default
  rate** is used: **$50/m² for windows, $100/m² for floors**.
- A room that has at least one measured, included item adds a **$200 labour**
  charge.
- The house **subtotal** is the sum of every included room's items + labour.
- A whole-house **discount %** is then applied to give the **final total**.

Rooms and individual items can be toggled out of the quote, and the result can
be shared as a CSV file.


