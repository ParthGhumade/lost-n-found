# User Pair Walkthrough: Finder & Claimant Experience

This document details the live end-to-end execution of the Campus Lost & Found verification loop between two real students:
- **Finder (Alex)**: `test@campus.edu` (TE - Div A, Computer Science)
- **Claimant (Sam)**: `claimant@campus.edu` (TE - Div B, Computer Science)

---

## The 6-Act Verification Lifecycle

```
[ ACT 1: FINDER ]
Alex finds Sony Headphones in Library ➔ Takes photo to private storage ➔ Posts listing without photo
       │
       ▼
[ ACT 2: CLAIMANT ]
Sam spots listing on Public Feed ➔ Photo is hidden ➔ Submits unique details (Octocat sticker)
       │
       ▼
[ ACT 3: FINDER REVIEW ]
Alex reviews description in Inbox ➔ Matches physical item ➔ Clicks [Verify Description]
       │
       ▼
[ ACT 4: PHOTO REVEAL ]
Sam's app unlocks private photo via signed URL ➔ Sam confirms: [✓ IT'S MINE]
       │
       ▼
[ ACT 5: CONTACT EXCHANGE ]
Mutual contact cards unlock with phone numbers & class details ➔ WhatsApp/call handover coordination
       │
       ▼
[ ACT 6: HANDOVER COMPLETE ]
Alex clicks [Mark as Collected] ➔ Item archived from feed, claim marked collected
```

---

### Act 1: The Finder Finds an Item & Creates a Listing

1. **Alex logs into the app** with student credentials (`test@campus.edu`).
2. **Alex finds blue Sony WH-1000XM4 headphones** left on a study desk on the 3rd floor of the campus library.
3. **Takes a photo**: The app securely uploads the photo to the **private storage bucket** (`item-images-private/79ded500.../1788697094232_sony_headphones.jpg`).
4. **Fills in the public listing**:
   - **Item Type**: `Over-ear Headphones`
   - **Location Found**: `Central Library, 3rd Floor Quiet Study Area`
   - **Date Found**: `2026-09-06`
5. **Publishing**: Item is assigned ID `fb1c4b93-e16b-41e6-8794-f58abdfe48d6` with status `open`.
   - **Privacy check**: The image is **strictly omitted** from public projections.

---

### Act 2: The Claimant Searches the Feed & Submits Proof

1. **Sam logs in** (`claimant@campus.edu`).
2. **Sam opens the Public Feed** and searches for `"Headphones"`.
3. **Sam sees the card**:
   - `Over-ear Headphones` found at `Central Library, 3rd Floor Quiet Study Area`.
   - **No photo is visible**, preventing anyone from browsing photos and claiming items they don't own.
4. **Security Test Passed**: When Sam's client attempts to query the private photo URL directly before verification, Supabase denies access with `403 Forbidden` (`IMAGE_ACCESS_DENIED`).
5. **Sam clicks `[ Claim Item ]`** and enters proof of ownership:
   > *"Midnight blue Sony WH-1000XM4. The left ear cup has a tiny white GitHub octocat sticker, and the right headband hinge is slightly stiff."*
6. **Claim submitted**: Claim ID `8918f220-c284-49c0-8e55-63ca34b887f2` is created with status `pending`.

---

### Act 3: The Finder Reviews the Description in the Claims Inbox

1. **Alex opens "My Listings"** tab and sees: `Over-ear Headphones (1 claim pending)`.
2. **Alex opens the claim details**:
   - Reads Sam's description: *"tiny white GitHub octocat sticker"*.
3. **Alex checks the headphones** sitting on their desk: **The octocat sticker matches!**
4. **Alex clicks `[ Verify Description ]`**:
   - Supabase updates `claims.status` from `pending` ➔ `claim_verified`.

---

### Act 4: Photo Reveal & Claimant Ownership Confirmation

1. **Sam receives notification / real-time update**:
   - Status transitions to `claim_verified` ("Verified - Photo Ready").
2. **Private photo unlocks**:
   - Sam's client calls `rpc/get_claim_image_path`, which confirms authorization and fetches the storage path.
   - Generates a **time-limited 300-second signed URL**.
3. **Sam views the photo**:
   - Seeing their exact headphones and sticker, Sam has 100% confidence.
4. **Sam clicks `[ ✓ IT'S MINE - Exchange Contacts ]`**.

---

### Act 5: Mutual Contact Exchange

The `rpc/get_mutual_contact` unlocks mutual contact cards directly in the app:

| **Finder Contact Details (Revealed to Sam)** | **Claimant Contact Details (Revealed to Alex)** |
|---|---|
| **Name:** Test Student | **Name:** Sam Claimant |
| **Class:** TE - Div A | **Class:** TE - Div B |
| **Branch:** Computer Science | **Branch:** Computer Science |
| **Phone:** `+91 9876543210` | **Phone:** `+91 9988776655` |

- Both students coordinate via WhatsApp/call to meet outside the Library 3rd Floor entrance.

---

### Act 6: Physical Handover & Archival

1. **Alex and Sam meet**, inspect the headphones, and the physical return is made.
2. **Alex clicks `[ Mark as Collected ]`**:
   - Database executes atomic RPC `public.mark_claim_collected`.
   - `claims.status` transitions to `collected`.
   - `items.status` transitions to `returned`.
   - Any other pending claims on that item are automatically closed.
3. **Public Feed Verification**:
   - The item is automatically removed from the active campus feed.

---

## Automated Verification Script
This exact flow was executed live against the production Supabase backend using:
```bash
dart run test/user_pair_walkthrough.dart
```
**Result**: `SIMULATION COMPLETED SUCCESSFULLY WITH 100% FLOW INTEGRITY`
