# Photo AI

Single-screen Flutter app that generates AI scene variations from portrait photos via Google Gemini. Core flow: **upload → generate → save → view**.

The app uses a single main screen intentionally, as specified in the technical brief requirements.

## What This App Demonstrates

- Clean separation of concerns using Provider + Services architecture
- Secure handling of API keys via Firebase Cloud Functions
- Firebase Security Rules for user data isolation
- Integration with Google Gemini for AI image generation
- Error handling and loading states in a production-ready manner

## Architecture Overview

Provider + Services pattern — chosen over BLoC/Riverpod because the app has one screen with linear state (idle → uploading → generating → done/error). Cloud Function acts as AI gateway to keep secrets server-side and validate ownership before processing.

```text
┌──────┐    ┌─────────┐    ┌─────────┐    ┌────────────────┐    ┌────────────┐
│ User │───▶│ Flutter │───▶│ Storage │───▶│ Cloud Function │───▶│ Gemini API │
└──────┘    │   App   │◀───│         │◀───│                │◀───│            │
            └─────────┘    └─────────┘    └────────────────┘    └────────────┘
```

## Tech Stack

| Layer   | Choice             | Reason                |
| ------- | ------------------ | --------------------- |
| UI      | Flutter 3.38.3     | Required              |
| State   | Provider           | Simple, single-screen |
| Auth    | Firebase Anonymous | Required              |
| Storage | Firebase Storage   | Required              |
| Backend | Cloud Functions    | Secrets server-side   |
| AI      | Gemini 2.0 Flash   | Image generation      |

## Project Structure

```text
lib/
├── config/         # AppTheme (colors, typography)
├── models/         # Generation data model
├── services/       # Auth, Storage, Functions
├── providers/      # AppProvider (state machine)
├── screens/        # HomeScreen
└── widgets/        # UploadCard, GenerateButton, ImageGrid

functions/src/
└── index.ts        # generateAIScenes
```

## Security

- **No client secrets** — Gemini key in Firebase Secrets, accessed only by Cloud Function
- **User isolation** — Storage/Firestore rules enforce `users/{uid}/` ownership
- **Server validation** — Auth, path ownership, MIME type checked before processing
- **Protected images** — No public URLs; client resolves via `getDownloadURL()` with auth

## Setup

**Requirements:** Flutter 3.38.3, Firebase CLI, Node.js 18+

### With FVM

```bash
git clone https://github.com/ariyudhapras/photo-ai-app.git && cd photo-ai-app
fvm use 3.38.3 && fvm flutter pub get
firebase login && fvm flutter pub global activate flutterfire_cli
fvm flutter pub global run flutterfire_cli:flutterfire configure
firebase functions:secrets:set GEMINI_API_KEY
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,storage
fvm flutter run
```

### Without FVM

```bash
git clone https://github.com/ariyudhapras/photo-ai-app.git && cd photo-ai-app
flutter pub get
firebase login && dart pub global activate flutterfire_cli && flutterfire configure
firebase functions:secrets:set GEMINI_API_KEY
cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,storage
flutter run
```

## Known Limitations

- 4 fixed scenes (beach, city, mountain, cafe) — extensible via `SCENES` array
- No image cropping before generation
- Anonymous auth — data lost on app reinstall
- Gemini model is experimental, may have availability limits

## AI-Assisted Workflow

Per the brief, this project used AI-assisted development for scaffolding and refactoring. Architecture, security, prompt engineering, and debugging were done manually.

---

## Appendix

### API Contract

**Request:**

```json
{ "imageUrl": "https://...", "imagePath": "users/{uid}/originals/{file}.jpg" }
```

**Response:**

```json
{
  "success": true,
  "generationId": "gen_123_abc",
  "images": [
    { "path": "users/{uid}/generated/{id}/beach.png", "scene": "beach" },
    { "path": "users/{uid}/generated/{id}/city.png", "scene": "city" }
  ]
}
```

### Error Handling

| Error               | Behavior                                               |
| ------------------- | ------------------------------------------------------ |
| Upload timeout      | 20 second timeout → "Upload timed out" message + retry |
| No network          | User-friendly message + retry button                   |
| Auth failure        | "Authentication failed. Please restart the app."       |
| Invalid file        | Rejected before upload (size >10MB, non-JPG/PNG)       |
| Storage quota       | "Storage quota exceeded" message                       |
| Generation fail     | Error message + retry button                           |
| Cloud Function fail | 5 minute timeout, graceful error handling              |

### Technical Notes

- Upload timeout: 20 seconds (production-ready, prevents infinite loading)
- Gemini returns base64 inline → extracted, uploaded to Storage, path returned
- MIME validation: strips charset params, normalizes `image/jpg` → `image/jpeg`
- Removed `makePublic()` for security; URLs resolved client-side with auth

---

**Author:** Ari Yudha Prasetyo  
**Submission:** Ergodic Apps Technical Test
