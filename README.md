# Photo AI

A Flutter mobile application that transforms portrait photos into AI-generated travel and lifestyle scenes. Upload a selfie and get Instagram-ready photos of yourself at the beach, city, mountains, or cafe!

## Demo

https://github.com/user-attachments/assets/demo-video-placeholder

## Features

- 📸 Upload portrait photos from gallery
- 🤖 AI-powered scene generation (Beach, City, Mountain, Cafe)
- 🔐 Secure anonymous authentication
- ☁️ Cloud-based image processing
- 📱 Clean, modern UI (Apple Design Award-inspired)
- ⚡ Real-time loading states and error handling

## Tech Stack

| Technology               | Purpose                               |
| ------------------------ | ------------------------------------- |
| Flutter 3.38.3           | Cross-platform mobile framework       |
| Firebase Anonymous Auth  | User authentication                   |
| Firebase Storage         | Image storage (originals + generated) |
| Firebase Firestore       | Metadata persistence                  |
| Firebase Cloud Functions | Serverless backend API                |
| Google Gemini API        | AI image generation                   |
| Provider                 | State management                      |

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Flutter App                             │
│  ┌─────────┐    ┌─────────────┐    ┌──────────────────┐    │
│  │   UI    │ -> │  Provider   │ -> │    Services      │    │
│  │ Widgets │ <- │ (AppState)  │ <- │ Auth/Storage/Fn  │    │
│  └─────────┘    └─────────────┘    └──────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Firebase Services                         │
│  ┌──────────┐  ┌───────────┐  ┌────────────────────────┐   │
│  │   Auth   │  │  Storage  │  │    Cloud Functions     │   │
│  │(Anonymous)│  │ (Images)  │  │  (generateAIScenes)   │   │
│  └──────────┘  └───────────┘  └────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Google Gemini API                         │
│              (Image Generation via Cloud Function)           │
└─────────────────────────────────────────────────────────────┘
```

## Data Flow

1. User uploads portrait photo
2. Image uploaded to Firebase Storage (`users/{uid}/originals/`)
3. Cloud Function called with image URL
4. Gemini API generates 4 scene variations
5. Generated images saved to Storage (`users/{uid}/generated/`)
6. Metadata saved to Firestore
7. Results displayed in app

## Project Structure

```
photo_ai_app/
├── lib/
│   ├── main.dart                 # App entry point
│   ├── config/
│   │   └── app_theme.dart        # Colors, typography, spacing
│   ├── models/
│   │   └── generation.dart       # Data models
│   ├── services/
│   │   ├── auth_service.dart     # Anonymous authentication
│   │   ├── storage_service.dart  # Image upload/download
│   │   └── functions_service.dart # Cloud Function calls
│   ├── providers/
│   │   └── app_provider.dart     # State management
│   ├── screens/
│   │   └── home_screen.dart      # Main screen
│   └── widgets/
│       ├── upload_card.dart      # Image upload UI
│       ├── generate_button.dart  # Action button
│       └── image_grid.dart       # Results display
├── functions/
│   └── src/
│       └── index.ts              # generateAIScenes function
├── firestore.rules               # Firestore security rules
└── storage.rules                 # Storage security rules
```

## Security Approach

### API Key Protection

- Gemini API key stored in Firebase Secrets (not in client code)
- All AI calls go through Cloud Function (server-side only)

### Firebase Security Rules

- Users can only access their own data
- Path validation: `users/{userId}/...` must match authenticated user
- Both Firestore and Storage rules enforce user isolation

### Cloud Function Validation

```typescript
// 1. Validate authentication
if (!request.auth?.uid) throw new HttpsError("unauthenticated", ...);

// 2. Validate image ownership
if (!imagePath.startsWith(`users/${uid}/`))
  throw new HttpsError("permission-denied", ...);
```

## Setup Instructions

### Prerequisites

- Flutter SDK (3.38.3 recommended, use FVM)
- Firebase CLI
- Node.js 18+
- Google Cloud account with Gemini API access

### 1. Clone Repository

```bash
git clone https://github.com/ariyudhapras/photo-ai-app.git
cd photo-ai-app
```

### 2. Install Flutter Dependencies

```bash
fvm use 3.38.3
fvm flutter pub get
```

### 3. Firebase Setup

```bash
# Login to Firebase
firebase login

# Configure Firebase for Flutter
flutterfire configure
```

### 4. Set Gemini API Key

```bash
# Get API key from https://aistudio.google.com/app/apikey
firebase functions:secrets:set GEMINI_API_KEY
```

### 5. Deploy Cloud Functions

```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

### 6. Deploy Security Rules

```bash
firebase deploy --only firestore:rules,storage
```

### 7. Run the App

```bash
fvm flutter run
```

## AI Tools Used

This project was developed with assistance from:

- **Kiro AI** - Code generation, architecture design, debugging
- **Google Gemini API** - AI image generation (gemini-2.0-flash-exp-image-generation)

## Author

**Ari Yudha Prasetyo**

Technical Test Submission for Ergodic Apps

---

## License

This project is for evaluation purposes only.
