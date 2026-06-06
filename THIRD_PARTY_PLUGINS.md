# Third-Party Plugins

These are the pub.dev packages used in this assignment. All are added through
`pubspec.yaml`. Firebase and `image_picker` come from the KIT305 tutorial work.

| Plugin | Link | Author / Publisher | Where it's used |
| --- | --- | --- | --- |
| firebase_core | https://pub.dev/packages/firebase_core | Google / Invertase (firebase.google.com) | Initialises Firebase on startup in `main.dart`. |
| cloud_firestore | https://pub.dev/packages/cloud_firestore | Google / Invertase (firebase.google.com) | The shared database for houses, rooms, windows and floor spaces (`firestore_service.dart`). |
| image_picker | https://pub.dev/packages/image_picker | Flutter team (flutter.dev) | Picks a photo from the gallery for rooms, windows and floor spaces (`image_helper.dart`). |
| http | https://pub.dev/packages/http | Dart team (dart.dev) | Calls the KIT305 product API in `product_api.dart`. |
| share_plus | https://pub.dev/packages/share_plus | Flutter Community (fluttercommunity.dev) | Opens the system share sheet to share the quote CSV (`quote_screen.dart`). |
| path_provider | https://pub.dev/packages/path_provider | Flutter team (flutter.dev) | Gets a temp directory to write the quote CSV file before sharing (`quote_screen.dart`). |
| cupertino_icons | https://pub.dev/packages/cupertino_icons | Flutter team (flutter.dev) | Provides the iOS-style icon font (default Flutter dependency). |

