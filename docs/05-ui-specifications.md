# Photo AI - UI Specifications

## Design Style

Clean, minimal, Apple Design Award-inspired:

- White/light gray background
- Indigo/purple accent gradient
- System fonts (SF Pro / Roboto)
- Generous whitespace
- Subtle shadows

## Color Palette

```dart
// Primary
primaryStart: Color(0xFF6366F1)  // Indigo
primaryEnd: Color(0xFF8B5CF6)    // Purple

// Background
background: Color(0xFFFAFAFA)
surface: Color(0xFFFFFFFF)

// Text
textPrimary: Color(0xFF1F2937)
textSecondary: Color(0xFF6B7280)

// States
error: Color(0xFFEF4444)
```

## Components

### Upload Card

**Empty state:**

- Dashed border, rounded corners (16px)
- Camera icon + "Tap to upload" text
- Aspect ratio 4:5

**With image:**

- Image fills card
- Small X button to remove

### Generate Button

- Full width, pill shape (height 56px)
- Gradient background when enabled
- Gray when disabled
- Shows spinner + "Creating..." when loading

### Image Grid

- 2 column grid
- 12px gap
- Each image: rounded corners, label overlay at bottom
- Labels: "Original", "Beach", "City", etc.

## States

**Loading:**

- Full screen overlay (white, 95% opacity)
- Centered spinner + "Creating your scenes..."

**Error:**

- Warning icon
- "Something went wrong"
- Retry button

**Empty (initial):**

- Upload card in empty state
- Disabled generate button
- No results grid

## Screen Layout

```
┌─────────────────────────┐
│  Photo AI               │  ← Simple title
├─────────────────────────┤
│  ┌───────────────────┐  │
│  │   Upload Card     │  │  ← Tap to pick image
│  └───────────────────┘  │
│                         │
│  [ Generate Button ]    │  ← Main action
│                         │
│  ┌─────┐  ┌─────┐      │
│  │ Img │  │ Img │      │  ← Results grid
│  └─────┘  └─────┘      │
│  ┌─────┐  ┌─────┐      │
│  │ Img │  │ Img │      │
│  └─────┘  └─────┘      │
└─────────────────────────┘
```
