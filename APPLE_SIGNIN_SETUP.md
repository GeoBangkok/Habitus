# Apple Sign-In Setup Instructions

To enable Apple Sign-In in your DreamHomes OS app, follow these steps:

## 1. Enable Sign in with Apple Capability

### In Xcode:
1. Select your **Habitus** project in the navigator
2. Select your **Habitus** target
3. Go to the **Signing & Capabilities** tab
4. Click the **+ Capability** button
5. Search for and add **"Sign in with Apple"**

## 2. Configure App ID (if needed)

### In Apple Developer Portal:
1. Go to [developer.apple.com](https://developer.apple.com)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Select **Identifiers**
4. Find your App ID (com.DreamHomesOS)
5. Edit it and enable **Sign in with Apple**
6. Save changes

## 3. Test Sign in with Apple

### On Simulator:
- Apple Sign-In works on iOS Simulator
- Use your Apple ID or create a test account
- The simulator will show the native Apple Sign-In flow

### On Device:
- Requires a real Apple ID
- Must be signed into iCloud on the device
- Will use Face ID/Touch ID for authentication

## 4. How It Works in the App

### First Time Users:
1. Tap "Sign in with Apple"
2. Authenticate with Face ID/Touch ID
3. Choose to share or hide email
4. App receives user ID, email (if shared), and name
5. Data is stored securely in Keychain
6. User is signed in and taken to MainTabView

### Returning Users:
1. Tap "Sign in with Apple"
2. Authenticate with Face ID/Touch ID
3. App receives only user ID (email/name not provided again)
4. App retrieves stored email/name from Keychain
5. User is signed in with their previous data

### Guest Users:
1. Tap "Continue as Guest"
2. A unique guest ID is generated
3. Can browse but with limited features
4. Can upgrade to Apple Sign-In later

## 5. Security Features Implemented

- **Nonce Generation**: Random nonce for each sign-in request
- **Keychain Storage**: Secure storage of user credentials
- **Session Persistence**: Users stay signed in between app launches
- **Error Handling**: Graceful handling of sign-in failures

## 6. Testing Checklist

- [ ] Apple Sign-In button appears on authentication screen
- [ ] Tapping button triggers native Apple Sign-In flow
- [ ] Successful sign-in navigates to main app
- [ ] User data persists after app restart
- [ ] Sign out clears all user data
- [ ] Guest mode works without authentication

## 7. Common Issues

### "Sign in with Apple isn't available"
- Ensure capability is added in Xcode
- Check that App ID has Sign in with Apple enabled
- Verify device/simulator is signed into iCloud

### "Sign in failed"
- Check network connection
- Ensure valid provisioning profile
- Verify bundle ID matches (com.DreamHomesOS)

### User data not persisting
- Keychain access may be restricted
- Check Keychain entitlements
- Ensure KeychainHelper has proper access

## Implementation Notes

The app implements:
- Proper Keychain storage for credentials
- Automatic session restoration
- Graceful fallback to guest mode
- Secure nonce generation
- Full error handling

No additional backend setup is required - the app handles everything locally using Keychain for secure storage.