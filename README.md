# MEDPASS — Flutter Project

"Med‑Pass — Your Medical Passport in your pocket."

This repository contains the Flutter source for the Med‑Pass mobile application. Below is a repo-accurate README that includes a Design section where you can add the Figma link and guidance for contributors on how to reference Figma frames in PRs.

---

## Table of contents

- Project summary
- Design (Figma)
- Repository files to read
- Dependencies (from pubspec.yaml)
- Prerequisites
- Quick start — clone & run locally
- Firebase / platform notes
- Build commands
- Tests & static analysis
- Assets

---

## Project summary

Med‑Pass provides a portable, secure way to store and manage medical documents and emergency information. The repo contains Flutter app code (under `lib/`), platform folders, Firebase configuration, and Firestore/Storage rules. The package name in `pubspec.yaml` is `projet` and the SDK constraint is ">=3.3.0 <4.0.0".

---

## Design (Figma)

Add the Figma project URL below so designers and implementers can reference the source-of-truth.

Figma project: <https://www.figma.com/design/NoarAu2yp05qQebAY5pnrm/flutter?node-id=4-22&t=7QxcjagTMyl30FSU-1>

---

## Repository files to read

- `.env.example` — example environment variables  
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/.env.example
- `pubspec.yaml` — dependencies and assets  
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/pubspec.yaml
- `firebase.json` / `.firebaserc` — Firebase CLI config
- `firestore.rules` — Firestore security rules  
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/firestore.rules
- `storage.rules` — Storage security rules  
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/storage.rules
- `cors.json` — CORS configuration  
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/cors.json
- `analysis_options.yaml` — analyzer / lint rules  
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/analysis_options.yaml
- `lib/` — application source (inspect for exact file locations)

---

## Dependencies (from pubspec.yaml)

Key dependencies (see `pubspec.yaml` for full list):
- provider, firebase_core, cloud_firestore, firebase_auth, firebase_storage
- flutter_doc_scanner, google_mlkit_text_recognition, google_mlkit_translation
- pdf, flutter_pdfview, qr_flutter, flutter_dotenv, file_picker, image_picker
- permission_handler, share_plus, shared_preferences, and others

See the authoritative list and versions:
https://github.com/wiameadnane/medpass-flutter-application/blob/main/pubspec.yaml

---

## Prerequisites

- Flutter SDK (compatible with the SDK constraint in `pubspec.yaml`)
- Android SDK / Android Studio for Android builds
- Xcode for iOS builds (macOS)
- (Optional) Firebase CLI if deploying or running emulators

---

## Quick start — clone & run locally

1. Clone:
   ```
   git clone https://github.com/wiameadnane/medpass-flutter-application.git
   cd medpass-flutter-application
   ```

2. Create `.env`:
   ```
   cp .env.example .env
   # Edit .env to provide required values
   ```

3. Install dependencies:
   ```
   flutter pub get
   ```

4. (Optional — Firebase) Add platform config:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist` and run `pod install` in `ios/`

5. Run:
   ```
   flutter devices
   flutter run
   ```

Notes:
- Without platform Firebase files, Firebase features (auth, Firestore, storage) will not work. Local UI-only flows (QR generation, local scan preview) can still be inspected where implemented.
- Ensure camera and storage permissions are granted when testing scanning or file upload flows.

---

## Firebase / platform notes

Files in this repo for Firebase and deployment:
- `firebase.json`, `.firebaserc`
- `firestore.rules`, `storage.rules`
- `cors.json`

---

## Build commands

- Android APK:
  ```
  flutter build apk --release
  ```

- Android App Bundle:
  ```
  flutter build appbundle --release
  ```

- iOS (macOS/signing required):
  ```
  flutter build ios --release
  ```

---

## Tests & static analysis

- Run tests:
  ```
  flutter test
  ```

- Static analysis:
  ```
  flutter analyze
  ```

- Format:
  ```
  dart format .
  ```

`analysis_options.yaml` is included to enforce lint rules.

---

## Assets

`pubspec.yaml` declares `assets/` — ensure required art and icon files are present under `assets/` prior to running.

---

## Where to look next

- Check `pubspec.yaml` for dependencies and assets:
  https://github.com/wiameadnane/medpass-flutter-application/blob/main/pubspec.yaml

---
