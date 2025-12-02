# Photo AI

## Project Overview

Photo AI is a Flutter mobile application that allows users to upload portrait photos and generate AI-powered scene variations. The app integrates Firebase services (Anonymous Auth, Firestore, Storage, Cloud Functions) with an AI image generation API to deliver a seamless image transformation experience. This project is a technical test submission for Ergodic Apps.

## Planned Features

- Anonymous user authentication via Firebase Auth
- Image upload with client-side validation (file size, type)
- AI-powered scene generation via Firebase Cloud Functions
- Secure API key management using Firebase Secrets
- Generated images stored in Firebase Storage
- Metadata persistence in Firestore
- Real-time UI state management with Provider
- Responsive image grid display with loading and error states

## Tech Stack

- **Flutter** – Cross-platform mobile framework (Stable channel via FVM)
- **Firebase Anonymous Auth** – User authentication
- **Firebase Firestore** – NoSQL database for metadata
- **Firebase Storage** – Image storage (originals + generated)
- **Firebase Cloud Functions** – Serverless backend API
- **AI Image Generation API** – Via Firebase Cloud Functions
- **Provider** – State management

## Project Structure

The project will follow a modular structure similar to:

```
photo_ai_app/
├── lib/              # Flutter application code
│   ├── config/       # Theme and app configuration
│   ├── models/       # Data models
│   ├── services/     # Firebase service integrations
│   ├── providers/    # State management
│   ├── screens/      # UI screens
│   └── widgets/      # Reusable UI components
├── functions/        # Firebase Cloud Functions (TypeScript)
├── docs/             # Technical documentation
├── firestore.rules   # Firestore security rules
└── storage.rules     # Storage security rules
```

## Documentation

Technical documentation is available in the `./docs` folder:

- **01-project-overview.md** – Project goals and constraints
- **02-architecture.md** – System design and data flow
- **03-data-models.md** – Data structures and contracts
- **04-security.md** – Security rules and best practices
- **05-ui-specifications.md** – Design system and components
- **06-implementation-guide.md** – Development phases and checklist

## Setup Instructions

Setup instructions will be updated as implementation progresses.

**Prerequisites:**

- Flutter (Stable channel via FVM)
- Firebase CLI
- Firebase project configured

## Status

**In development** – Technical test submission for Ergodic Apps.

---

Author: Ari Yudha Prasetyo
