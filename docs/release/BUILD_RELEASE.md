# Build a release App Bundle

## 1. Firebase

```bash
# From docs/FIREBASE_SETUP.md
flutterfire configure --project=YOUR_PROJECT_ID --platforms=android,ios
firebase deploy --only firestore:rules,firestore:indexes
```

Ensure `android/app/google-services.json` exists (enables Crashlytics Gradle plugin).

## 2. Upload keystore (once)

```bash
mkdir -p android/keystore
keytool -genkey -v \
  -keystore android/keystore/business-buddy-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias businessbuddy
```

Copy `android/key.properties.example` → `android/key.properties` and fill in passwords/paths.

Never commit `key.properties` or the `.jks` file.

## 3. Build

```bash
flutter clean
flutter pub get
flutter analyze lib test
flutter test
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

## 4. Upload

Play Console → your app → **Closed testing** → create release → upload AAB → add tester emails → roll out.
