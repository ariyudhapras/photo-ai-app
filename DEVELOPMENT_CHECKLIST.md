# Photo AI - Development Checklist

> Technical Test Submission - Structured Development Guide
> Author: Ari Yudha Prasetyo

---

## Progress Overview

| Phase                    | Status       | Progress |
| ------------------------ | ------------ | -------- |
| Phase 1: Setup           | ✅ Completed | 100%     |
| Phase 2: Cloud Function  | ⏳ Pending   | 0%       |
| Phase 3: App Integration | ⏳ Pending   | 0%       |
| Phase 4: Polish + Demo   | ⏳ Pending   | 0%       |

---

## Phase 1: Setup ✅ COMPLETED

- [x] Flutter project created
- [x] FVM configured (3.38.3)
- [x] Firebase project configured (`flutterfire configure`)
- [x] Dependencies added (firebase_core, firebase_auth, cloud_firestore, firebase_storage, cloud_functions, provider, image_picker, cached_network_image, uuid)
- [x] Folder structure created (`lib/config`, `lib/models`, `lib/services`, `lib/providers`, `lib/screens`, `lib/widgets`)
- [x] Firebase initialization in `main.dart`
- [x] App tested on macOS
- [x] App tested on iOS Simulator

---

## Phase 3: App Integration - Development Steps

### Step 1: Security Rules

**Estimated Time:** 5 min

**Files to Create:**

- [ ] `firestore.rules`
- [ ] `storage.rules`

**Tasks:**

- [ ] Create Firestore security rules (users can only access their own data)
- [ ] Create Storage security rules (users can only access their own files)
- [ ] Verify rules syntax

**Commit Message:**

```
feat(security): add Firestore and Storage security rules
```

**Test:** N/A (rules deployed later)

---

### Step 2: App Theme

**Estimated Time:** 10 min

**Files to Create:**

- [ ] `lib/config/app_theme.dart`

**Tasks:**

- [ ] Define color palette (primary indigo/purple gradient, background, text colors)
- [ ] Define text styles
- [ ] Define spacing constants
- [ ] Export theme data

**Commit Message:**

```
feat(config): add app theme with colors and typography
```

**Test:** Visual inspection after Step 9

---

### Step 3: Data Model

**Estimated Time:** 10 min

**Files to Create:**

- [ ] `lib/models/generation.dart`

**Tasks:**

- [ ] Create `GenerationStatus` enum (pending, completed, failed)
- [ ] Create `GeneratedImage` class (url, scene)
- [ ] Create `Generation` class (id, originalImageUrl, generatedImages, status, errorMessage)
- [ ] Implement `fromJson` and `toJson` methods

**Commit Message:**

```
feat(models): add Generation data model
```

**Test:** Unit test (optional)

---

### Step 4: Auth Service

**Estimated Time:** 15 min

**Files to Create:**

- [ ] `lib/services/auth_service.dart`

**Tasks:**

- [ ] Implement `signInAnonymously()` method
- [ ] Implement `getCurrentUser()` method
- [ ] Implement `getUserId()` getter
- [ ] Handle auth state changes

**Commit Message:**

```
feat(services): add AuthService for anonymous authentication
```

**Test:**

- [ ] Run app and verify anonymous sign-in works
- [ ] Check Firebase Console for new anonymous user

---

### Step 5: Storage Service

**Estimated Time:** 15 min

**Files to Create:**

- [ ] `lib/services/storage_service.dart`

**Tasks:**

- [ ] Implement `uploadImage(File file, String userId)` method
- [ ] Generate unique file path: `users/{userId}/originals/{timestamp}.jpg`
- [ ] Return download URL after upload
- [ ] Handle upload errors

**Commit Message:**

```
feat(services): add StorageService for image upload
```

**Test:**

- [ ] Upload test image
- [ ] Verify image appears in Firebase Storage Console

---

### Step 6: Functions Service

**Estimated Time:** 10 min

**Files to Create:**

- [ ] `lib/services/functions_service.dart`

**Tasks:**

- [ ] Implement `generateAIScenes(String imageUrl, String imagePath)` method
- [ ] Call `generateAIScenes` Cloud Function
- [ ] Parse response and return list of generated image URLs
- [ ] Handle function errors

**Commit Message:**

```
feat(services): add FunctionsService for Cloud Function calls
```

**Test:** After Cloud Function is deployed (Step 10)

---

### Step 7: App Provider

**Estimated Time:** 20 min

**Files to Create:**

- [ ] `lib/providers/app_provider.dart`

**Tasks:**

- [ ] Define `AppState` enum (idle, uploading, generating, completed, error)
- [ ] Create `AppProvider` class extending `ChangeNotifier`
- [ ] Implement state variables (state, selectedImage, uploadedImageUrl, generatedImageUrls, errorMessage)
- [ ] Implement `selectImage()` method
- [ ] Implement `clearImage()` method
- [ ] Implement `generateScenes()` method (orchestrates upload → function call → update state)
- [ ] Implement `reset()` method

**Commit Message:**

```
feat(providers): add AppProvider for state management
```

**Test:** After UI is connected (Step 9)

---

### Step 8: UI Widgets

**Estimated Time:** 30 min

**Files to Create:**

- [ ] `lib/widgets/upload_card.dart`
- [ ] `lib/widgets/generate_button.dart`
- [ ] `lib/widgets/image_grid.dart`

**Tasks:**

**UploadCard:**

- [ ] Empty state: dashed border, camera icon, "Tap to upload" text
- [ ] With image: show image preview with remove button
- [ ] Handle tap to pick image

**GenerateButton:**

- [ ] Disabled state (gray, no image selected)
- [ ] Ready state (gradient background)
- [ ] Loading state (spinner + "Creating...")

**ImageGrid:**

- [ ] 2-column grid layout
- [ ] Display original image with "Original" label
- [ ] Display generated images with scene labels (Beach, City, etc.)
- [ ] Use cached_network_image for loading

**Commit Message:**

```
feat(widgets): add UploadCard, GenerateButton, and ImageGrid components
```

**Test:** Visual inspection in Step 9

---

### Step 9: Home Screen & Main Integration

**Estimated Time:** 20 min

**Files to Create/Update:**

- [ ] `lib/screens/home_screen.dart`
- [ ] Update `lib/main.dart`

**Tasks:**

**HomeScreen:**

- [ ] Scaffold with app bar "Photo AI"
- [ ] UploadCard widget
- [ ] GenerateButton widget
- [ ] ImageGrid widget (conditional, only when results exist)
- [ ] Loading overlay when generating
- [ ] Error display with retry option

**Main.dart Updates:**

- [ ] Wrap app with `ChangeNotifierProvider`
- [ ] Initialize AuthService on startup
- [ ] Replace placeholder HomeScreen with actual HomeScreen

**Commit Message:**

```
feat(screens): add HomeScreen with full UI integration
```

**Test:**

- [ ] Run app on iOS Simulator
- [ ] Verify UI matches design spec
- [ ] Test image picker
- [ ] Test button states
- [ ] Verify anonymous auth works

---

## Phase 2: Cloud Function

### Step 10: Cloud Function Implementation

**Estimated Time:** 45 min

**Files to Create:**

- [ ] `functions/src/index.ts`
- [ ] `functions/package.json`
- [ ] `functions/tsconfig.json`

**Tasks:**

- [ ] Run `firebase init functions` (TypeScript)
- [ ] Implement `generateAIScenes` callable function
- [ ] Validate `request.auth.uid`
- [ ] Validate image path ownership (`users/{uid}/...`)
- [ ] Call Gemini API with image
- [ ] Generate 4-6 scene variations
- [ ] Upload generated images to Storage
- [ ] Return image URLs
- [ ] Set GEMINI_API_KEY secret: `firebase functions:secrets:set GEMINI_API_KEY`
- [ ] Deploy: `firebase deploy --only functions`

**Commit Message:**

```
feat(functions): add generateAIScenes Cloud Function with Gemini API integration
```

**Test:**

- [ ] Full end-to-end test: Upload → Generate → Display results
- [ ] Verify generated images in Firebase Storage
- [ ] Verify error handling

---

## Phase 4: Polish + Demo

### Step 11: Final Polish

**Estimated Time:** 30 min

**Tasks:**

- [ ] Test full flow multiple times
- [ ] Handle all error states gracefully
- [ ] Improve loading UX
- [ ] Code cleanup and comments
- [ ] Update README.md with final documentation

**Commit Message:**

```
docs: update README with setup instructions and architecture overview
```

---

### Step 12: Deploy Security Rules

**Estimated Time:** 5 min

**Tasks:**

- [ ] Deploy Firestore rules: `firebase deploy --only firestore:rules`
- [ ] Deploy Storage rules: `firebase deploy --only storage`
- [ ] Verify rules in Firebase Console

**Commit Message:**

```
chore(firebase): deploy security rules to production
```

---

### Step 13: Demo Video

**Estimated Time:** 15 min

**Tasks:**

- [ ] Record 3-5 minute demo video
- [ ] Show: App launch → Upload image → Generate → View results
- [ ] Explain architecture briefly
- [ ] Mention AI tools used

**Deliverable:** Demo video file or link

---

## Quick Reference Commands

```bash
# Run app
fvm flutter run

# Run on specific device
fvm flutter run -d ios
fvm flutter run -d macos

# Analyze code
fvm flutter analyze

# Run tests
fvm flutter test

# Deploy Cloud Functions
firebase deploy --only functions

# Deploy security rules
firebase deploy --only firestore:rules,storage

# Set secret
firebase functions:secrets:set GEMINI_API_KEY

# View logs
firebase functions:log
```

---

## Commit Convention

Format: `type(scope): description`

**Types:**

- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `chore` - Maintenance
- `refactor` - Code refactoring
- `test` - Tests

**Examples:**

```
feat(services): add AuthService for anonymous authentication
feat(widgets): add UploadCard component
fix(provider): handle null image state
docs: update README with setup instructions
chore(ios): update deployment target to iOS 15.0
```

---

## Notes

- Always run `fvm flutter analyze` before committing
- Test on iOS Simulator after each major feature
- Keep commits atomic (one feature per commit)
- Push after each successful commit for backup

---

Last Updated: December 3, 2025
