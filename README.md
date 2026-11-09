# Cloud Courier — Firebase Cloud Messaging

**CSC 4360 — Mobile App Development**  
**In-Class Activity 14**

## Overview

Cloud Courier is a Flutter application that receives Firebase Cloud Messaging (FCM) notifications and updates the interface based on the message data.

The app handles notifications in foreground, background, and terminated states.

## Features

- Receives Firebase Cloud Messaging notifications
- Handles foreground messages using `onMessage`
- Handles background notification taps using `onMessageOpenedApp`
- Handles notification-triggered launches using `getInitialMessage`
- Registers a separate background message handler
- Changes visible content based on the message payload
- Rejects unsupported payload values without crashing
- Displays the last handler, receipt count, message ID, and diagnostic feedback
- Checks notification permission and FCM token availability

## Technologies

- Flutter and Dart
- Firebase Core
- Firebase Cloud Messaging
- Android

## Project Structure

- `lib/main.dart` — Firebase initialization, background handler, and application interface
- `lib/fcm_service.dart` — FCM permission requests, token retrieval, and message listeners
- `lib/firebase_options.dart` — Firebase project configuration

## Message Payload

The app supports these custom data values:

```json
{
  "action": "update_ui",
  "asset": "promo"
}
```

The `asset` value can be `default` or `promo`.

Unsupported values display a diagnostic message while keeping the previous content unchanged.

## Testing

| Test | Handler | Result |
|---|---|---|
| T1 — Foreground | `onMessage` | Passed |
| T2 — Background notification tap | `onMessageOpenedApp` | Passed |
| T3 — Terminated-state notification tap | `getInitialMessage` | Passed |
| T4 — Invalid payload | `onMessage` | Passed |

All four tests were performed on an Android phone using Firebase Console test notifications.

## How to Run

Install Flutter and configure Firebase for your Android application.

```bash
flutter pub get
flutter run
```

Enable notification permissions and send a Firebase Console test message to the current device's FCM registration token.

## Notes

The application uses built-in Flutter icons rather than image assets to demonstrate visible UI changes.

The FCM registration token is not displayed in the interface to avoid exposing it in screenshots.

## References

- [Firebase Cloud Messaging for Flutter](https://firebase.google.com/docs/cloud-messaging/flutter/client)
- [Flutter Documentation](https://docs.flutter.dev/)