# Photo AI - Data Models

## Flutter Model

```dart
// lib/models/generation.dart

enum GenerationStatus { pending, completed, failed }

class Generation {
  final String id;
  final String originalImageUrl;
  final List<GeneratedImage> generatedImages;
  final GenerationStatus status;
  final String? errorMessage;

  // Constructor, fromJson, toJson
}

class GeneratedImage {
  final String url;
  final String scene;  // beach, city, roadtrip, cafe

  // Constructor, fromJson, toJson
}
```

## Firestore Structure

```
users/{userId}/generations/{generationId}
{
  "id": "abc123",
  "originalImageUrl": "https://...",
  "generatedImages": [
    { "url": "https://...", "scene": "beach" },
    { "url": "https://...", "scene": "city" }
  ],
  "status": "completed",
  "errorMessage": null
}
```

## Storage Structure

```
users/{userId}/
├── originals/{timestamp}.jpg
└── generated/{generationId}/
    ├── beach.jpg
    ├── city.jpg
    ├── roadtrip.jpg
    └── cafe.jpg
```

## Cloud Function Contract

### Request (from Flutter)

```typescript
{
  imageUrl: string,   // Storage URL
  imagePath: string   // For ownership validation
}
```

Note: `userId` comes from `request.auth.uid`, not from client.

### Response

```typescript
// Success
{
  success: true,
  generationId: string,
  images: [{ url: string, scene: string }]
}

// Error
{
  success: false,
  error: { code: string, message: string }
}
```

## Validation

**Client-side:**

- Max file size: 10MB
- Allowed types: jpg, png

**Server-side:**

- `request.auth.uid` must exist
- `imagePath` must start with `users/{uid}/`
