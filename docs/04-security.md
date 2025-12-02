# Photo AI - Security

## Core Principles

1. No API keys in Flutter client
2. All AI calls go through Cloud Function
3. Users can only access their own data

## Firebase Security Rules

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/generations/{generationId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

### Storage Rules

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

## Cloud Function Security

```typescript
export const generateAIScenes = onCall(async (request) => {
  // 1. Validate auth
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError("unauthenticated", "Must be authenticated");
  }

  // 2. Validate image ownership
  const { imagePath } = request.data;
  if (!imagePath.startsWith(`users/${uid}/`)) {
    throw new HttpsError("permission-denied", "Invalid image");
  }

  // Continue with generation...
});
```

## API Key Storage

```bash
# Set secret via Firebase CLI
firebase functions:secrets:set GEMINI_API_KEY

# Access in function
const apiKey = process.env.GEMINI_API_KEY;
```

## Checklist

- [ ] API key in Firebase Secrets (not in code)
- [ ] Cloud Function validates `request.auth.uid`
- [ ] Cloud Function validates image path ownership
- [ ] Firestore rules deployed
- [ ] Storage rules deployed
