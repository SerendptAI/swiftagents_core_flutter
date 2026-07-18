![SwiftAgents Logo](https://github.com/user-attachments/assets/24906828-76d4-4da5-80f6-85720f266d7a)

# SwiftAgents Core SDK

SwiftAgents core flutter package for embedding AI support agents into Android, and iOS applications.

---
<!-- Demo video -->
![SwiftAgents demo](https://github.com/user-attachments/assets/dcc2974b-7dfd-461e-95d6-97ceb5a5d4f7)

## Getting Started

To get started with SwiftAgents, first [Sign up](https://swiftagents.org/en/signup) to create your account. Then, retrieve your `companyId` and `apiKey` from [https://swiftagents.org/en/dashboard/settings/api-keys](https://swiftagents.org/en/dashboard/settings/api-keys). You'll need these credentials to initialize the SDK in your application.

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

## Quick Start

initiate SwiftAgents in `main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:swift_agents_core/swift_agents_core.dart';

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
    sdkContext: sdkContext,
),
```

---
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

- If `SwiftAgentsView` fails to load, confirm `SwiftAgentsCore.init(...)` method has the `companyId` and `apiKey`.
- If camera/gallery access is blocked, verify your Android manifest and iOS `Info.plist` entries.
- If uploads fail, confirm storage permissions are granted for the device OS version.

---

## License

This repository is licensed under the terms of the included `LICENSE` file.
