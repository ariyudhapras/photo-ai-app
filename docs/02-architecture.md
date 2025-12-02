# Photo AI - Architecture

## Project Structure

```
photo_ai_app/
├── lib/
│   ├── main.dart                    # Entry point, Firebase init, Provider setup
│   ├── config/
│   │   └── app_theme.dart           # Colors, typography, spacing
│   ├── models/
│   │   └── generation.dart          # Single model for generation data
│   ├── services/
│   │   ├── auth_service.dart        # Anonymous auth
│   │   ├── storage_service.dart     # Upload & download images
│   │   └── functions_service.dart   # Cloud Function calls
│   ├── providers/
│   │   └── app_provider.dart        # Single provider for all state
│   ├── screens/
│   │   └── home_screen.dart         # Main (only) screen
│   └── widgets/
│       ├── upload_card.dart         # Image upload UI
│       ├── generate_button.dart     # Action button
│       └── image_grid.dart          # Results display
│
├── functions/
│   └── src/
│       └── index.ts                 # generateAIScenes function
│
├── firestore.rules
├── storage.rules
└── pubspec.yaml
```

## Data Flow

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  UI Layer   │ ──▶ │  Provider   │ ──▶ │  Services   │
│ HomeScreen  │ ◀── │ AppProvider │ ◀── │ Auth/Store  │
└─────────────┘     └─────────────┘     └─────────────┘
                                              │
                                              ▼
                                     ┌─────────────────┐
                                     │ Cloud Function  │
                                     │ → Gemini API    │
                                     └─────────────────┘
```

## State (AppProvider)

```dart
enum AppState { idle, uploading, generating, completed, error }

class AppProvider {
  AppState state;
  File? selectedImage;
  String? uploadedImageUrl;
  List<String> generatedImageUrls;
  String? errorMessage;
}
```

## Services

| Service          | Responsibility                        |
| ---------------- | ------------------------------------- |
| AuthService      | Sign in anonymously, get user ID      |
| StorageService   | Upload image, get download URL        |
| FunctionsService | Call generateAIScenes, parse response |

## Screen Composition

```
HomeScreen
├── UploadCard (tap to pick image, shows preview)
├── GenerateButton (disabled/ready/loading states)
└── ImageGrid (shows original + generated images)
```
