# Campus Lost & Found

<p align="center">
  <img src="logo.png" alt="Campus Lost & Found Logo" width="160" />
</p>

A mobile app for college campuses that helps finders and claimants connect — without exposing item photos to potential scammers.

---

## The Problem

Standard lost & found boards backfire. The moment you post a photo of valuable earbuds or a watch, anyone can claim them by just looking at the picture. This app prevents that.

---

## How It Works

The core idea is simple: **the photo stays private until ownership is proven.**

```
Finder posts item (no photo shown publicly)
         │
Claimant submits a description — brand, color, scratches, anything unique
         │
Finder reads the description and decides: Accept or Reject
         │
If accepted → photo is privately revealed to the claimant only
         │
Claimant confirms: "It's mine" or "Not mine"
         │
If confirmed → both parties see each other's contact details
         │
They meet up and the item is marked as collected
```

Nobody ever sees the photo without first proving they know what the item looks like.

---

## Roles

**Finder** — Found something on campus? Post a listing with the item type, where you found it, and when. Upload a photo (kept private). Review incoming claims and decide who sounds credible.

**Claimant** — Lost something? Browse the public listings, find a match, and describe your item in detail. If your description convinces the finder, you'll get to see the photo to confirm it's yours.

---

## Key Details

- Item photos are never shown publicly — not in the feed, not anywhere.
- Contact details (phone number, class, branch) are only exchanged after both sides confirm the item is a match.
- A claimant can only submit one claim per item.
- Once an item is collected, all other pending claims for it are closed automatically.
- Finders can delete their own listings at any time.

---

## Tech Stack

- **Frontend**: Flutter
- **Backend**: Supabase (database, auth, private file storage)

---

## Getting Started

### Prerequisites

- Flutter SDK installed
- A Supabase project with the schema applied (see [`docs/db_schema.md`](docs/db_schema.md))
- Environment variables configured — copy `.env.example` to `.env` and fill in your Supabase URL and anon key

### Run

```bash
cd frontend
flutter pub get
flutter run
```

---

## Docs

| File | What's in it |
|------|-------------|
| [`docs/prd.md`](docs/prd.md) | Full product requirements and feature checklist |
| [`docs/db_schema.md`](docs/db_schema.md) | Database tables and columns |
| [`docs/apis.md`](docs/apis.md) | All API calls the app makes |
| [`docs/userflow.md`](docs/userflow.md) | Step-by-step user flow diagram |
| [`docs/ui_design_doc.md`](docs/ui_design_doc.md) | Screen layouts and UI decisions |