# Photo AI - Project Overview

## Core Flow

```
Upload portrait → Cloud Function → Gemini API → Store images → Display results
```

Single screen. One workflow. Minimal features.

## Mandatory Tech Stack

| Technology               | Purpose       |
| ------------------------ | ------------- |
| Flutter (3.38.3)         | Client app    |
| Firebase Anonymous Auth  | User auth     |
| Firebase Storage         | Image storage |
| Firebase Firestore       | Metadata      |
| Firebase Cloud Functions | Backend API   |
| Google Gemini API        | AI generation |

**No alternatives allowed.**

## Constraints

**Do:**

- Single screen only
- Upload → Generate → Display flow
- 4-6 AI scene variations
- Loading & error states
- Clean UI, responsive
- Secure (no client-side secrets)

**Don't:**

- Expose API keys in client
- Direct AI calls from client
- Multi-screen navigation
- Over-engineer

## Deliverables

1. GitHub repo (Flutter + Cloud Functions)
2. README (setup, architecture, security, AI tools used)
3. Demo video (3-5 min)

## Evaluation

- Working flow: Upload → Generate → Store → Display
- Code quality & structure
- Correct tech stack usage
- Security implementation
- UI/UX quality
- AI tool effectiveness
