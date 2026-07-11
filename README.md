![Company Logo](assets/images/logo.png)

# SwiftAgents Core SDK

<!-- Ensure the asset path is declared in your pubspec.yaml, for example:
flutter:
  assets:
    - assets/images/logo.png
-->

SwiftAgents core flutter package for embedding AI support agents into Android, iOS and Web applications.

---

<video autoplay muted loop width="100%" preload="metadata">
  <source src="assets/videos/agent_001.mp4" type="video/mp4" />
  Your browser does not support the video tag.
</video>

## Required Platform Permissions

This SDK also uses the `image_picker` and `file_picker` packages; your app would need the following permissions for the SDK to work properly:

### Android

In your app module's `AndroidManifest.xml` add the following permissions under the top-level `<manifest>` tag.

Manifest example:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <!-- Android 13+ -->
    <uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
    <!-- Android 12 and below -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```

If your app targets Android 13+, the SDK uses `Permission.photos` and may also require storage permissions for backward compatibility.

### iOS

In `ios/Runner/Info.plist`, add these usage descriptions:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Add the following permissions -->
    <key>NSCameraUsageDescription</key>
    <string>SwiftAgents needs camera access to let users capture photos for chat attachments.</string>

    <key>NSPhotoLibraryUsageDescription</key>
    <string>SwiftAgents needs photo library access to let users select images from their gallery</string>
    
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>SwiftAgents needs permission to save or attach media from the photo library.</string>
</dict>
</plist>
```

<!-- ### pubspec.yaml

The SDK requires the following dependencies in your host app's `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_svg: ^2.3.0
  marqueer: ^2.5.0
  rive: ^0.14.7
  dio: ^5.9.2
  provider: ^6.1.5+1
  logger: ^2.7.0
  cached_network_image: ^3.4.1
  internet_connection_checker: ^3.0.1
  enhanced_paginated_view: ^2.0.3
  permission_handler: ^12.0.3
  device_info_plus: ^12.4.0
  image_picker: ^1.2.2
  file_picker: 10.3.10
  shimmer: ^3.0.0
  crypto: ^3.0.7
## Quick Start

Initialize the SDK in your `main.dart`:

--- -->

## Quick Start

initiate SwiftAgents in `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:swift_agents_core/swift_agents.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SwiftAgentsCore.init(
      companyId: 'your_company_id',
      apiKey: 'your_api_key',
  );
  runApp(const MyApp());
}
```

Create/Reuse context for a user or multiple users:

```dart
final sdkContext = SwiftAgentsCore.getContext(email: 'user@example.com');
final sdkContext2 = SwiftAgentsCore.getContext(email: 'user2@example.com');
```

Pass context into SwiftAgentsView, then show view

- As BottomSheet

```dart
FloatingActionButton(
  onPressed: () {
    SwiftAgentsView(
      sdkContext: sdkContext,
    ).show(context);
  },
  child: const Icon(Icons.chat),
),
```

- Or as a Widget

```dart
SwiftAgentsView(
    theme: SwiftAgentsThemeData.dark(),
    sdkContext: sdkContext,
),
```

---

## Theming

Optional theming is supported. Customize the UI with `SwiftAgentsThemeData`:

```dart
SwiftAgentsView(
    theme: SwiftAgentsThemeData.dark(),
    sdkContext: sdkContext,
),
```

Or use the light theme:

```dart
SwiftAgentsView(
    theme: SwiftAgentsThemeData.light(),
    sdkContext: sdkContext,
),
```
## Theming

SwiftAgents supports light, dark, and custom themes through `SwiftAgentsThemeData`.

### Light Theme

```dart
SwiftAgentsView(
  theme: SwiftAgentsThemeData.light(),
  sdkContext: sdkContext,
)
```

### Dark Theme

```dart
SwiftAgentsView(
  theme: SwiftAgentsThemeData.dark(),
  sdkContext: sdkContext,
)
```

## Custom Theme

```dart
SwiftAgentsView(
  sdkContext: sdkContext,
  theme: SwiftAgentsThemeData(
    sidebarBg: const Color(0xFF4F46E5),
    userBubble: const Color(0xFF2563EB),
    agentBubble: const Color(0xFFF3F4F6),
    background: Colors.white,
    foreground: Colors.black,
    border: const Color(0xFFE5E7EB),
  ),
)
```

### Theme Properties

| Property      | Type      | Description                   |
| ------------- | --------- | ----------------------------- |
| `sidebarBg`   | `Color`   | Sidebar color.                |
| `userBubble`  | `Color`   | User message bubble color.    |
| `agentBubble` | `Color`   | Agent message bubble color.   |
| `background`  | `Color`   | Main background color.        |
| `foreground`  | `Color`   | Icon color.                   |
| `border`      | `Color`   | Chat text field and suggestion chip color.     | 
| `avatar`      | `Widget?` | Optional custom agent avatar. | 

### Custom Avatar

```dart
SwiftAgentsView(
  sdkContext: sdkContext,
  theme: SwiftAgentsThemeData(
    avatar: const CircleAvatar(
      backgroundImage: AssetImage(
        'assets/images/support_agent.png',
      ),
    ),
  ),
)
```
You may also use network images, SVG widgets, animated widgets, user's profile, or any other Flutter widget to replace the avatar.


## Troubleshooting

- If `SwiftAgentsView` fails to load, confirm `SwiftAgentsCore.init(...)` completed properly.
- If camera/gallery access is blocked, verify your Android manifest and iOS `Info.plist` entries.
- If uploads fail, confirm storage permissions are granted for the device OS version.

---

## License

This repository is licensed under the terms of the included `LICENSE` file.
