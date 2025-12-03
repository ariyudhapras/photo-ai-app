# Photo AI

A single-screen Flutter application that generates AI-powered scene variations from portrait photos. Users upload one image and receive multiple travel/lifestyle scene outputs (beach, city, mountain, cafe) via Google Gemini.

> **Note:** This is intentionally a single-screen application, built to satisfy the technical brief which specifies "one main screen" with the core flow: upload → generate → save → view.

## Architecture

**Why Provider over BLoC/Riverpod?** — The app has one screen with a linear state flow (idle → uploading → generating → done/error). Provider is sufficient and avoids unnecessary complexity.

**Why Cloud Function as AI gateway?** — The brief prohibits API keys in client code. All Gemini calls route through a Cloud Function that validates auth, checks file ownership, and returns storage paths.

**Why storage paths instead of public URLs?** — Generated images remain protected by Firebase Security Rules. The client resolves download URLs via `getDownloadURL()` with authentication.

```text
Flutter App → Firebase Auth (anonymous) → Upload to Storage
           → Call Cloud Function → Gemini API → Save to Storage
           → Return paths → Client resolves URLs → Display
```

## Tech Stack

| Layer   | Choice             | Reasoning                                    |
| ------- | ------------------ | -------------------------------------------- |
| UI      | Flutter 3.38.3     | Required by brief                            |
| State   | Provider           | Simple, sufficient for single-screen         |
| Auth    | Firebase Anonymous | Required by brief                            |
| Storage | Firebase Storage   | Required by brief                            |
| Backend | Cloud Functions    | Required by brief, keeps secrets server-side |
| AI      | Gemini 2.0 Flash   | Image generation with inline image output    |

## Project Structure

```text
lib/
├── services/          # Auth, Storage, Functions (thin wrappers)
├── providers/         # AppProvider (single state machine)
├── screens/           # HomeScreen (only screen)
└── widgets/           # UploadCard, GenerateButton, ImageGrid

functions/src/
└── index.ts           # generateAIScenes callable function
```

## API Contract

### Cloud Function: `generateAIScenes`

**Request:**

```json
{
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "imagePath": "users/{uid}/originals/{filename}.jpg"
}
```

**Response (success):**

```json
{
  "success": true,
  "generationId": "gen_1234567890_abc123",
  "images": [
    {
      "path": "users/{uid}/generated/{generationId}/beach.png",
      "scene": "beach"
    },
    {
      "path": "users/{uid}/generated/{generationId}/city.png",
      "scene": "city"
    },
    {
      "path": "users/{uid}/generated/{generationId}/mountain.png",
      "scene": "mountain"
    },
    { "path": "users/{uid}/generated/{generationId}/cafe.png", "scene": "cafe" }
  ]
}
```

**Response (error):**

```json
{
  "error": {
    "code": "unauthenticated | permission-denied | invalid-argument | internal",
    "message": "Human-readable error message"
  }
}
```

## Security Implementation

1. **No client-side secrets** — Gemini API key stored in Firebase Secrets
2. **User isolation** — Storage/Firestore rules enforce `users/{uid}/` path ownership
3. **Server-side validation** — Cloud Function validates auth, path ownership, and MIME type
4. **Protected images** — Generated images require authentication to access

```typescript
if (!request.auth?.uid) throw HttpsError("unauthenticated");
if (!imagePath.startsWith(`users/${uid}/`))
  throw HttpsError("permission-denied");
if (!["image/jpeg", "image/png"].includes(contentType))
  throw HttpsError("invalid-argument");
```

## Error Handling

| Error Type             | Client Behavior              | User Feedback                          |
| ---------------------- | ---------------------------- | -------------------------------------- |
| No network             | Catch exception in provider  | "Something went wrong" + Retry button  |
| Auth failure           | Re-attempt anonymous sign-in | "Authentication failed"                |
| Upload failure         | Set error state              | "Upload failed: {message}"             |
| Generation failure     | Set error state              | "Generation failed: {message}"         |
| Invalid file type      | Rejected before upload       | "Only JPG and PNG files are allowed"   |
| File too large         | Rejected before upload       | "File size exceeds 10MB limit"         |
| Cloud Function timeout | HttpsError caught            | "Generation failed. Please try again." |

All errors are caught in `AppProvider`, which sets `AppState.error` and stores the error message for display.

## Technical Challenges & Solutions

| Challenge                                 | Solution                                                                              |
| ----------------------------------------- | ------------------------------------------------------------------------------------- |
| Gemini returns images inline, not as URLs | Extract base64 from response, upload to Storage, return path                          |
| MIME type validation was too strict       | Parse content-type header, strip charset params, normalize `image/jpg` → `image/jpeg` |
| Generated images were publicly accessible | Removed `makePublic()`, return storage paths, resolve URLs client-side with auth      |
| AI-generated images looked artificial     | Rewrote prompts to emphasize "candid", "natural lighting", "taken by a friend"        |

## Known Limitations

- **Single scene set** — Currently generates 4 fixed scenes (beach, city, mountain, cafe). Extensible by adding to the `SCENES` array in the Cloud Function.
- **No image editing** — Users cannot crop or adjust the uploaded image before generation.
- **No generation history** — Previous generations are stored in Firestore but not displayed in the UI.
- **Anonymous auth only** — Users lose access to their images if they clear app data or reinstall.
- **Gemini model availability** — Uses `gemini-2.0-flash-exp-image-generation` which is experimental and may have rate limits or availability issues.

## Setup

**Requirements:** Flutter 3.38.3, Firebase CLI, Node.js 18+

```bash
flutter --version  # Verify Flutter version
```

### Option A: With FVM (recommended)

```bash
git clone https://github.com/ariyudhapras/photo-ai-app.git
cd photo-ai-app
fvm use 3.38.3
fvm flutter pub get

firebase login
fvm flutter pub global activate flutterfire_cli
fvm flutter pub global run flutterfire_cli:flutterfire configure

firebase functions:secrets:set GEMINI_API_KEY

cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,storage

fvm flutter run
```

### Option B: Without FVM

```bash
git clone https://github.com/ariyudhapras/photo-ai-app.git
cd photo-ai-app
flutter pub get

firebase login
dart pub global activate flutterfire_cli
flutterfire configure

firebase functions:secrets:set GEMINI_API_KEY

cd functions && npm install && cd ..
firebase deploy --only functions,firestore:rules,storage

flutter run
```

## AI-Assisted Workflow

Per the brief's requirement, this project used AI-assisted development. AI helped with scaffolding and refactoring. Architecture decisions, security implementation, prompt engineering, and debugging were done manually.

---

**Author:** Ari Yudha Prasetyo  
**Submission:** Ergodic Apps Technical Test
