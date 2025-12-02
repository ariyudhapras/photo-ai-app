# Photo AI - Implementation Guide

## Development Phases (1-Day Delivery)

### Phase 1: Setup (30 min)

1. Create Flutter project: `fvm flutter create photo_ai_app --org com.photoai`
2. Set fvm: `fvm use 3.38.3`
3. Add dependencies to pubspec.yaml
4. Create folder structure
5. Setup Firebase project + `flutterfire configure`
6. Create firestore.rules and storage.rules

### Phase 2: Cloud Function (45 min)

1. Initialize: `firebase init functions` (TypeScript)
2. Implement `generateAIScenes` function:
   - Validate `request.auth.uid`
   - Validate image path ownership
   - Call Gemini API
   - Upload generated images to Storage
   - Return image URLs
3. Set API key: `firebase functions:secrets:set GEMINI_API_KEY`
4. Deploy: `firebase deploy --only functions`

### Phase 3: App Integration (2 hours)

1. **Services:**

   - `auth_service.dart` - anonymous sign in
   - `storage_service.dart` - upload image, get URL
   - `functions_service.dart` - call generateAIScenes

2. **Provider:**

   - `app_provider.dart` - state management (idle, uploading, generating, completed, error)

3. **UI:**

   - `home_screen.dart` - main screen layout
   - `upload_card.dart` - image picker
   - `generate_button.dart` - action button with states
   - `image_grid.dart` - display results

4. **Connect everything:**
   - Provider calls services
   - UI reacts to provider state

### Phase 4: Polish + Demo (45 min)

1. Test full flow
2. Handle error states
3. Write README.md
4. Record demo video (3-5 min)

---

## Dependencies (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.8.1
  firebase_auth: ^5.3.4
  firebase_storage: ^12.3.7
  cloud_firestore: ^5.5.1
  cloud_functions: ^5.1.6
  provider: ^6.1.2
  image_picker: ^1.1.2
  cached_network_image: ^3.4.1
  uuid: ^4.5.1
```

---

## Quick Commands

```bash
# Run app
fvm flutter run

# Deploy functions
firebase deploy --only functions

# Deploy rules
firebase deploy --only firestore:rules,storage

# Set secret
firebase functions:secrets:set GEMINI_API_KEY
```

---

## Checklist

- [ ] Flutter project created
- [ ] Firebase configured
- [ ] Cloud Function deployed
- [ ] Anonymous auth working
- [ ] Image upload working
- [ ] AI generation working
- [ ] Results displayed
- [ ] README written
- [ ] Demo recorded
