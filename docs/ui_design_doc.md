# Frontend UI Design Document: Minimalist Campus Lost & Found

## 1. Design Philosophy & Guidelines
- **Zero Redundant Actions & Linear Navigation**: Every button, tap target, and action has a single, non-circular purpose. There are **no duplicate buttons leading back to the current screen**, no redundant "refresh" buttons where reactive streams exist, and no decorative buttons without concrete state changes.
- **Production-Quality Minimalism (Anti-AI Aesthetic)**:
  - No generic purple/indigo gradients or bubbly `rounded-2xl` cards.
  - Strict semantic color palette: neutral slate/zinc base, high-contrast dark text, crisp borders (`1px solid #E2E8F0`), and a single intentional accent (`#0F172A` deep slate / `#2563EB` crisp sapphire).
  - Clear typography hierarchy with tight, intentional spacing (4px / 8px / 16px / 24px scale).
  - High information density with instant readability.

---

## 2. Information Architecture & Screen Hierarchy

```
                    ┌───────────────────────────┐
                    │         AuthGate          │
                    └─────────────┬─────────────┘
                                  │
                  ┌───────────────┴───────────────┐
                  ▼                               ▼
       ┌────────────────────┐          ┌────────────────────┐
       │     LoginPage      │          │     SignupPage     │
       └──────────┬─────────┘          └──────────┬─────────┘
                  │                               │
                  └───────────────┬───────────────┘
                                  ▼
                     ┌────────────────────────┐
                     │   Main Navigation Bar  │ (3 Core Tabs Only)
                     └────────────┬───────────┘
                                  │
          ┌───────────────────────┼───────────────────────┐
          ▼                       ▼                       ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ 1. Public Feed   │    │ 2. My Listings   │    │ 3. My Claims     │
│ (Browse & Claim) │    │ (Finder Review)  │    │ (Status Tracker) │
└─────────┬────────┘    └─────────┬────────┘    └─────────┬────────┘
          │                       │                       │
          ▼                       ▼                       ▼
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│ Claim Submission │    │ Claim Review     │    │ Verification &   │
│ Sheet / Modal    │    │ Detail Screen    │    │ Contact Exchange │
└──────────────────┘    └──────────────────┘    └──────────────────┘
```

---

## 3. Screen-by-Screen UI Specifications

### Screen 1: Public Feed (`FeedScreen` - Tab 1)
- **Purpose**: Browse recently reported lost items across campus without seeing private photos.
- **Top Bar**:
  - Clean title: `Campus Feed`.
  - Minimal search bar (instant filter by keyword e.g. "earphones", "keys").
  - Category pill filter row: `All`, `Audio`, `Electronics`, `Bottles`, `Bags`, `ID/Cards`.
- **Item Card Layout**:
  - Category badge + Date Found (`Sept 5`).
  - Item Type heading (`🎧 Earphones`).
  - Found Location (`Room 6504, 5th Floor Engineering Bldg`).
  - Single primary action: `[ Claim Item ]` button (disabled or replaced with `[ Already Claimed ]` if current user submitted a claim).
- **Anti-Circular Rule**:
  - The card itself does NOT open an identical duplicate details page if all public details are already on the card.
  - Tapping `[ Claim Item ]` slides up a bottom sheet directly.

---

### Screen 2: Claim Submission Modal (`ClaimSheet`)
- **Purpose**: Submit ownership proof for an item without seeing its image.
- **UI Elements**:
  - Header: `Claim: {item_type}` with found location reminder.
  - Informational alert banner: *"The finder has uploaded a photo. Describe distinguishing features (brand, model, stickers, scratches, case color) so the finder can verify you."*
  - Free-form `TextFormField`: 4–6 lines, autofocus, character counter.
  - Validation: Minimum 10 characters.
  - Single Submission Button: `[ Submit Claim for Review ]`.
- **Post-Submission Action**:
  - Bottom sheet closes, shows a 3-second SnackBar with a direct link `[ View in My Claims ]`, transitioning tab directly without redundant modals.

---

### Screen 3: Post an Item (`CreateItemScreen` - Floating Action / Direct Form)
- **Purpose**: A student who finds an unattended item creates a listing.
- **UI Elements**:
  - Category Dropdown.
  - Location Found (Input field with recent campus locations chips).
  - Date Found (Defaults to today).
  - Photo Attachment Box:
    - Clean dashed border with icon `[ Camera / Gallery ]`.
    - Shows local thumbnail preview once selected with a single remove button (`✕`).
    - Explicit note: *"Your photo is strictly hidden from the public feed to stop false claims."*
  - Single Submit Button: `[ Post Item Listing ]`.
- **Post-Submission Action**:
  - Pops directly to `My Listings` tab showing the newly active item.

---

### Screen 4: Finder's Dashboard (`MyListingsScreen` - Tab 2)
- **Purpose**: The Finder tracks items they reported and reviews incoming claims.
- **Item Row / Card**:
  - Item name, location, and date.
  - Status indicator: `Open (X claims pending)` or `Returned`.
  - Tapping opens the **Claims Inbox** for that item.
- **Claims Inbox Sheet (`ItemClaimsReviewScreen`)**:
  - Displays list of claimants' submitted descriptions.
  - For each claim:
    - Claimant description box (plain monospace / high-contrast card).
    - Timestamp.
    - Two explicit mutually-exclusive action buttons:
      - `[ Reject ]` (Turns status to `claim_rejected`, archives card).
      - `[ Verify Description ]` (Transitions status to `claim_verified`, granting claimant access to the private photo).

---

### Screen 5: Claimant's Dashboard & Verification (`MyClaimsScreen` - Tab 3)
- **Purpose**: Track status of items the user claimed.
- **States & Visual Indicators**:
  1. `pending`: Badge "Under Review by Finder". No action available.
  2. `claim_rejected`: Badge "Description did not match". Item archived.
  3. `claim_verified`: **Call to Action**: High-priority alert banner: *"Finder approved your description! Review the item photo below to confirm."*
  4. `collected`: Badge "Returned & Closed".
- **Claimant Photo Review Modal**:
  - Displays the unlocked photo loaded via secure signed URL.
  - Two explicit decision buttons:
    - `[ ✕ Not Mine ]`: Transitions status to `closed_by_claimant`. Revokes photo access.
    - `[ ✓ It's Mine - Exchange Contact ]`: Transitions claim to contact exchange stage.

---

### Screen 6: Mutual Contact Exchange Card (`ContactExchangeView`)
- **Purpose**: Display mutual contact details to coordinate handover once both parties agree.
- **UI Layout**:
  - Side-by-side or stacked clean identity cards:
    - **Finder Details**: Name, Class, Branch, Phone Number with direct `[ Call ]` / `[ WhatsApp ]` launch.
    - **Your Details**: Name, Class, Branch, Phone Number.
  - Handover Action:
    - Single button: `[ Mark as Collected / Returned ]`.
    - Confirmation alert: *"Has the item been physically returned? This will close the listing."*

---

## 4. Anti-Pattern & Usability Rules (Strict Enforcement)

| Rule | Bad Pattern to Avoid | Required Solution |
|---|---|---|
| **No Same-Page Loops** | A "Details" button inside a card that merely opens a page repeating the card's exact 3 lines. | Keep public items inline. The only button is `[ Claim ]`. |
| **No Orphaned Actions** | A "Save", "Bookmark", or "Share" button with no backend implementation. | Exclude all unimplemented decorative buttons entirely. |
| **No Circular Auth** | Redirecting back to Login after login, or showing Login buttons when already authenticated. | Reactive `StreamBuilder<AuthState>` dynamically swaps between `AuthGate` and root app shell. |
| **No Redundant Refreshes** | Adding manual "Refresh" icon buttons in app bars when Supabase real-time or pull-to-refresh exists. | Native `RefreshIndicator` or real-time PostgREST streams. |
| **No Multiple Back Buttons** | Embedding custom back buttons inside screens that already have `Scaffold.appBar.leading`. | Rely exclusively on standard platform AppBar back navigation. |

---

## 5. Visual Hierarchy & Design System Tokens

```css
/* Color Palette */
--bg-primary: #F8FAFC (slate-50)
--surface: #FFFFFF
--border: #E2E8F0 (slate-200)
--text-primary: #0F172A (slate-900)
--text-secondary: #64748B (slate-500)
--accent-primary: #0F172A (slate-900)
--accent-brand: #2563EB (blue-600)
--success: #16A34A (green-600)
--danger: #DC2626 (red-600)

/* Spacing Scale */
--space-1: 4px
--space-2: 8px
--space-3: 12px
--space-4: 16px
--space-6: 24px

/* Border Radius */
--radius-sm: 6px
--radius-md: 10px
--radius-lg: 14px
```

---

## 6. Implementation Phasing
1. **Phase 1**: Authentication & Onboarding (`LoginPage`, `SignupPage`). *(Completed)*
2. **Phase 2**: Minimal bottom navigation shell (`FeedScreen`, `MyListingsScreen`, `MyClaimsScreen`).
3. **Phase 3**: Item posting form with private storage upload.
4. **Phase 4**: Claim submission sheet & Claimant/Finder real-time review loop.
5. **Phase 5**: Photo signed URL reveal & mutual contact exchange view.
