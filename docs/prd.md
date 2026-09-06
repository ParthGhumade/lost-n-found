# Product Requirements Document (PRD): Campus Lost & Found

## 1. Overview & Vision
A zero-friction, anti-fraud campus Lost & Found application designed for university students. 
Traditional lost & found systems suffer from false claims when photos of valuable items (earbuds, watches, calculators, etc.) are posted publicly. 

This platform prevents false claims through an **asymmetric verification loop**:
1. Finders post an item listing **without** exposing the image publicly.
2. Claimants submit proof of ownership by describing specific unique details in a free-form description.
3. If the Finder accepts the description, the private image is revealed to that specific claimant for confirmation.
4. If verified by both parties, mutual contact details are exchanged to coordinate physical return, culminating in marking the item as `collected`.

---

## 2. Core Personas
- **Finder**: Any campus student/staff member who finds an unattended item, uploads a photo to private storage, tags the location/category, and reviews incoming claims.
- **Claimant**: Any campus student/staff member who lost an item, browses public listings, submits descriptive claims, and reviews image verification.

---

## 3. System Architecture & Entity Relationships

```
┌──────────────────────┐         1:N         ┌──────────────────────┐
│       contacts       │ ──────────────────< │        items         │
│ (User Profiles/Auth) │                     │ (Finder posts item)  │
└──────────┬───────────┘                     └──────────┬───────────┘
           │                                            │
           │ 1:N                                        │ 1:N
           ▼                                            ▼
┌───────────────────────────────────────────────────────────────────┐
│                              claims                               │
│ (Claimant links to contact + item, tracks verification lifecycle)  │
└───────────────────────────────────────────────────────────────────┘
```

### 3.1 Database Schema Reference
- **`contacts`**
  - `contact_id` (uuid, PK, references `auth.users.id`)
  - `name` (text, not null)
  - `class` (text, not null)
  - `branch` (text, not null)
  - `prn` (text, unique, student registration number)
  - `contact_number` (text, not null)
  - `created_at` (timestamptz)

- **`items`**
  - `item_id` (uuid, PK, default `gen_random_uuid()`)
  - `finder_contact_id` (uuid, FK references `contacts.contact_id`, not null)
  - `item_type` (text, e.g. "Earphones", "Water Bottle", "Backpack", not null)
  - `location_found` (text, e.g. "Room 6504", "Library 2nd Floor", not null)
  - `date_found` (date, not null)
  - `image_path` (text, private storage path in Supabase bucket, hidden from public)
  - `status` (text: `open`, `returned`)
  - `created_at` (timestamptz)

- **`claims`**
  - `claim_id` (uuid, PK, default `gen_random_uuid()`)
  - `item_id` (uuid, FK references `items.item_id`, not null)
  - `claimant_contact_id` (uuid, FK references `contacts.contact_id`, not null)
  - `claim_description` (text, free-form description of unique marks, colors, models)
  - `status` (text: `pending`, `claim_verified`, `claim_rejected`, `closed_by_claimant`, `collected`)
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

---

## 4. Detailed Feature Requirements & Checklist

### Phase 1: Authentication & Onboarding
- [ ] **Auth Integration**: Supabase authentication for student accounts.
- [ ] **Mandatory Profile Setup**: First-time login forces completion of contact profile:
  - [ ] Full Name
  - [ ] College PRN (Permanent Registration Number)
  - [ ] Class / Year
  - [ ] Branch / Department
  - [ ] Active Phone / WhatsApp Number
- [ ] **Profile Management**: Ability to view and update contact details.

### Phase 2: Item Listing & Anti-Fraud Upload (Finder)
- [ ] **Create Listing Form**:
  - [ ] Category / Item Type selector (e.g., Electronics, Audio, Stationery, ID Cards, Bags, Other).
  - [ ] Location Found (text input with common campus locations or room numbers).
  - [ ] Date Found picker (defaults to current date).
  - [ ] Mandatory Image Capture/Upload.
- [ ] **Secure Storage & Privacy**:
  - [ ] Images are uploaded exclusively to a **private** Supabase Storage bucket (`item-images-private`).
  - [ ] Row Level Security (RLS) restricts read access to:
    - The original Finder (`finder_contact_id = auth.uid()`).
    - Claimants whose claim has been transitioned to `claim_verified`.
- [ ] **Public Feed / Listing View**:
  - [ ] Public cards show: Item Type icon & title, Location Found, Date Found, and "CLAIM" button.
  - [ ] ❌ Strictly NO photo preview displayed on the public card or public details view.
  - [ ] Filter items by Category, Date, and Location.
  - [ ] Search items by type or location.

### Phase 3: Claim Submission (Claimant)
- [ ] **Claim Modal / Page**:
  - [ ] Prompts claimant to provide proof of ownership.
  - [ ] Free-form description textarea (with placeholder hints: *"Mention brand, color, scratch marks, stickers, case type, or lock-screen details"*).
  - [ ] One active claim per user per item limit (prevents spamming).
- [ ] **Claims Dashboard (Claimant View)**:
  - [ ] "My Claims" tab displaying status tags:
    - `pending` (Awaiting finder review)
    - `claim_verified` (Finder accepted description - photo ready for review!)
    - `claim_rejected` (Finder rejected description)
    - `closed_by_claimant` (Claimant indicated photo didn't match)
    - `collected` (Successfully returned)

### Phase 4: Claim Review & Image Reveal (Finder Loop)
- [ ] **Finder Claims Inbox**:
  - [ ] "My Listings" tab showing active items and claim counts.
  - [ ] Incoming claims list displaying claimant's free-form description.
- [ ] **Finder Action on Claims**:
  - [ ] **Reject Claim**: Transitions status to `claim_rejected`. (Item remains open to other claims).
  - [ ] **Verify Claim**: Transitions status to `claim_verified`.
- [ ] **Secure Image Reveal (Claimant Photo Review)**:
  - [ ] Once status is `claim_verified`, the claimant gains access to view the uploaded item photo via a signed URL.
  - [ ] Claimant is presented with two explicit choices:
    - **"NOT MINE"**: Sets status to `closed_by_claimant`. Image access is revoked. Finder is notified.
    - **"IT'S MINE"**: Confirms ownership. Unlocks mutual contact exchange.

### Phase 5: Mutual Contact Exchange & Item Return
- [ ] **Contact Exchange Screen**:
  - [ ] Shown to both Finder and Claimant once claimant confirms "IT'S MINE".
  - [ ] Reveals Finder's details to Claimant: Name, Class, Branch, Contact Number.
  - [ ] Reveals Claimant's details to Finder: Name, Class, Branch, PRN, Contact Number.
- [ ] **Meet & Handover Confirmation**:
  - [ ] Either party (or Finder) marks item as `collected`.
  - [ ] Marking `collected` automatically updates the parent item status to `returned`.
  - [ ] Automatically auto-closes/rejects any remaining pending claims for that item.
  - [ ] Listing is archived from the active public feed.

---

## 5. Security & Edge Cases Checklist
- [ ] **RLS Policies**:
  - [ ] `items`: Anyone authenticated can read `item_type`, `location_found`, `date_found`. Only Finder can update/delete their own listing.
  - [ ] `contacts`: User can only edit their own contact row. Other users can only read specific contact info if linked by an approved claim exchange.
  - [ ] `claims`: Claimant can only read/edit their own claim. Finder can read claims associated with items they created.
- [ ] **Storage Security**:
  - [ ] Supabase storage bucket is private.
  - [ ] Signed URL generation requires validated RPC or authenticated edge function ensuring `claims.status IN ('claim_verified', 'collected')`.
- [ ] **Concurrency Handling**:
  - [ ] Multiple claims can coexist as `pending`.
  - [ ] If Item A is marked `collected` by Claimant 1, any other pending or verified claims for Item A transition to `closed`.
- [ ] **Audit Trail & Timestamps**:
  - [ ] All table records record `created_at` and `updated_at`.
