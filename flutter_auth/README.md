# Flutter Auth0 Authentication App

A Flutter application demonstrating authentication using Auth0, featuring multiple login methods, biometric authentication, session management, and user profile management.

## Features

- **Multiple Authentication Methods**
  - Email/Password login
  - Google OAuth login
  - Biometric authentication (Face ID/Touch ID)
  - Sign up functionality

- **Session Management**
  - Automatic session timeout (30 minutes)
  - Session expiry warnings (5 minutes before expiry)
  - Session refresh capability
  - "Remember Me" functionality

- **User Profile Management**
  - View profile information
  - Update profile details
  - Email verification status
  - Last updated timestamp

- **Security Features**
  - Secure credential storage
  - Biometric authentication
  - Proper session cleanup on logout

- **User Experience**
  - Dark mode support
  - Loading indicators
  - Error handling with user-friendly messages
  - Responsive design

## Getting Started

### Prerequisites

- Flutter SDK (version 3.2.3 or higher)
- iOS Simulator or Android Emulator
- Auth0 account and application

### Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/flutter_auth.git
   cd flutter_auth
   ```

2. Install dependencies:
   ```
   flutter pub get
   ```

3. Configure Auth0:
   - Create an Auth0 application in your Auth0 dashboard
   - Update the `lib/auth0_config.dart` file with your Auth0 domain and client ID
   - Configure the allowed callback URLs in your Auth0 dashboard

4. Run the application:
   ```
   flutter run
   ```

## Configuration

### Auth0 Setup

1. Create a new application in your Auth0 dashboard
2. Configure the following settings:
   - Application Type: Native
   - Token Endpoint Authentication Method: None
   - Allowed Callback URLs: `parkenstein.88.flutter-auth://hpark-sample-app.us.auth0.com/ios/parkenstein.88.flutter-auth/callback`
   - Allowed Logout URLs: `parkenstein.88.flutter-auth://hpark-sample-app.us.auth0.com/ios/parkenstein.88.flutter-auth/callback`

3. Update the `lib/auth0_config.dart` file with your Auth0 credentials:
   ```dart
   class Auth0Config {
     static const String domain = 'your-tenant.auth0.com';
     static const String clientId = 'your-client-id';
   }
   ```

### iOS Configuration

For iOS, you need to configure URL schemes in your `Info.plist` file:

```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>parkenstein.88.flutter-auth</string>
    </array>
  </dict>
</array>
```

### Android Configuration

For Android, you need to configure the manifest in your `AndroidManifest.xml` file:

```xml
<activity>
  <intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
      android:host="hpark-sample-app.us.auth0.com"
      android:pathPrefix="/android/parkenstein.88.flutter-auth/callback"
      android:scheme="parkenstein.88.flutter-auth" />
  </intent-filter>
</activity>
```

## Architecture

The application follows a simple architecture:

- **Screens**: UI components for login, signup, and user profile
- **Services**: Authentication service that handles Auth0 integration
- **Models**: Data models for user profiles and credentials

### Key Components

- **AuthService**: Handles all authentication operations with Auth0
- **LoginScreen**: Provides login options (email/password, Google, biometric)
- **SignupScreen**: Allows new users to create accounts
- **UserProfileScreen**: Displays and manages user profile information

## Dependencies

- **auth0_flutter**: Official Auth0 SDK for Flutter
- **local_auth**: For biometric authentication
- **flutter_svg**: For SVG image support

## Limitations

- Profile updates are not fully implemented due to Auth0 API limitations
- Biometric authentication requires saved credentials
- Session refresh functionality is a placeholder and needs backend implementation

## Future Improvements

- Implement backend API for profile updates
- Add more social login providers
- Enhance session management with refresh tokens
- Add password reset functionality
- Implement email verification flow

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Auth0 for providing the authentication infrastructure
- Flutter team for the amazing framework
