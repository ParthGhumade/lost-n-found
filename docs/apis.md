# API & Interface Specification: Campus Lost & Found

This document specifies all interfaces and API contracts for the Campus Lost & Found application following the [API and Interface Design](file:///C:/Users/parth/.gemini/config/plugins/agent-skills/skills/api-and-interface-design/SKILL.md) guidelines:
- **Contract First**: Strict typed schemas for all requests, responses, and parameters.
- **Consistent Error Semantics**: Uniform error structure and status code conventions.
- **Boundaries & Access Rules**: Row Level Security (RLS) enforcement, authorization, and validation.
- **Predictable Naming**: Plural nouns for resources, camelCase for query parameters & response payloads.

---

## 1. Global Conventions & Standards

### 1.1 Base URLs & Headers
- **REST Base URL**: `https://<supabase-project-ref>.supabase.co/rest/v1` (Supabase PostgREST / custom Edge Functions)
- **Required Headers**:
  - `apikey: <SUPABASE_PUBLISHABLE_KEY>`
  - `Authorization: Bearer <USER_JWT_TOKEN>`
  - `Content-Type: application/json`
  - `Prefer: return=representation` (when inserting or updating)

### 1.2 Error Envelope
All error responses from custom endpoints/RPCs or PostgREST map to a predictable structure:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "The requested item does not exist or has already been collected.",
    "details": null
  }
}
```

| HTTP Status | Code | Meaning |
|---|---|---|
| `400 Bad Request` | `BAD_REQUEST` | Malformed body or missing mandatory fields |
| `401 Unauthorized` | `UNAUTHENTICATED` | Missing or invalid auth token |
| `403 Forbidden` | `UNAUTHORIZED` | RLS violation or non-permitted action (e.g. non-finder trying to verify claim) |
| `404 Not Found` | `RESOURCE_NOT_FOUND` | Item or claim ID not found |
| `409 Conflict` | `CLAIM_ALREADY_EXISTS` | User already has an active claim on this item |
| `422 Unprocessable`| `VALIDATION_ERROR` | Semantic validation failed (e.g. invalid status transition) |
| `500 Internal Error`| `INTERNAL_SERVER_ERROR` | Unexpected backend or database failure |

---

## 2. Authentication & Onboarding APIs (`contacts`)

### 2.1 Get Current User Profile
Retrieves the onboarded contact profile for the currently authenticated user.
- **Method & Endpoint**: `GET /rest/v1/contacts?contact_id=eq.{user_id}&select=*`
- **Auth**: Authenticated user (`auth.uid() = contact_id`)
- **Success Response (`200 OK`)**:
```json
{
  "contactId": "79ded500-23c2-4fd0-b8c2-8a58315c1dc5",
  "name": "Jane Doe",
  "class": "TE - Div A",
  "branch": "Computer Science",
  "contactNumber": "+91 9876543210",
  "createdAt": "2026-09-06T11:06:14.205Z"
}
```

### 2.2 Create / Onboard Contact Profile
Created on first-time signup before accessing the app features.
- **Method & Endpoint**: `POST /rest/v1/contacts`
- **Auth**: Authenticated user
- **Request Body**:
```json
{
  "contact_id": "79ded500-23c2-4fd0-b8c2-8a58315c1dc5",
  "name": "Jane Doe",
  "class": "TE - Div A",
  "branch": "Computer Science",
  "contact_number": "+91 9876543210"
}
```
- **Validation**:
  - `name`: String, 2 to 100 characters.
  - `class`, `branch`: Required strings.
  - `contact_number`: Valid E.164 phone string (e.g., `+91...`).
- **Success Response (`201 Created`)**: Returns created contact object.

### 2.3 Update Contact Profile
- **Method & Endpoint**: `PATCH /rest/v1/contacts?contact_id=eq.{user_id}`
- **Auth**: Authenticated user (`auth.uid() = contact_id`)
- **Request Body**: Partial update object (e.g., `{"contact_number": "+91 9999999999"}`).
- **Success Response (`200 OK`)**: Returns updated contact object.

---

## 3. Items API (`items`)

### 3.1 List Public Lost & Found Items (Public Feed)
Lists active, uncollected items. **Strict privacy**: `image_path` is omitted from public queries.
- **Method & Endpoint**: `GET /rest/v1/items`
- **Query Parameters**:
  - `status`: Default `eq.open`
  - `select`: `item_id,item_type,location_found,date_found,created_at`
  - `order`: `created_at.desc`
  - `limit`: Integer (default 20, max 50)
  - `offset`: Integer (default 0)
  - `item_type`: Optional filter (e.g., `eq.Earphones` or `ilike.*phone*`)
  - `location_found`: Optional filter (e.g., `ilike.*Library*`)
- **Success Response (`200 OK`)**:
```json
[
  {
    "itemId": "e3e8f810-951b-419b-a01c-6d814ec9fb3b",
    "itemType": "Earphones",
    "locationFound": "Room 6504",
    "dateFound": "2026-09-05",
    "createdAt": "2026-09-05T14:30:00Z"
  }
]
```

### 3.2 Get Single Item Details
- **Method & Endpoint**: `GET /rest/v1/items?item_id=eq.{item_id}`
- **Success Response (`200 OK`)**:
  - If caller is the **Finder**: returns full row including `finder_contact_id` and `image_path`.
  - If caller is a **Claimant**: returns public fields (`item_id`, `item_type`, `location_found`, `date_found`, `status`).

### 3.3 Create Item Listing (Finder)
- **Method & Endpoint**: `POST /rest/v1/items`
- **Auth**: Authenticated user (`finder_contact_id = auth.uid()`)
- **Request Body**:
```json
{
  "finder_contact_id": "79ded500-23c2-4fd0-b8c2-8a58315c1dc5",
  "item_type": "Earphones",
  "location_found": "Room 6504",
  "date_found": "2026-09-05",
  "image_path": "79ded500-23c2-4fd0-b8c2-8a58315c1dc5/item_123.jpg"
}
```
- **Validation**:
  - `item_type`: Required string.
  - `location_found`: Required string.
  - `date_found`: ISO 8601 date, cannot be in the future.
  - `image_path`: Required path referencing an uploaded image in `item-images-private`.
- **Success Response (`201 Created`)**: Returns created item record.

### 3.4 List My Listings (Finder's Dashboard)
- **Method & Endpoint**: `GET /rest/v1/items?finder_contact_id=eq.{user_id}&select=*,claims(count)&order=created_at.desc`
- **Auth**: Authenticated user
- **Success Response (`200 OK`)**: List of items posted by the current user along with count of received claims.

### 3.5 Delete Item Listing (Finder)
Allows the finder who posted an item to permanently delete the listing and its storage image. All associated claims cascade-delete automatically.
- **Method & Endpoint**: `DELETE /rest/v1/items?item_id=eq.{item_id}&finder_contact_id=eq.{user_id}`
- **Auth**: Authenticated user (`finder_contact_id = auth.uid()`)
- **Success Response (`204 No Content`)**: Item deleted successfully.

---

## 4. Claims API (`claims`)

### 4.1 Submit a Claim (Claimant)
Submits a free-form ownership description for a listed item.
- **Method & Endpoint**: `POST /rest/v1/claims`
- **Auth**: Authenticated user (`claimant_contact_id = auth.uid()`)
- **Request Body**:
```json
{
  "item_id": "e3e8f810-951b-419b-a01c-6d814ec9fb3b",
  "claimant_contact_id": "9a1e4c76-59b1-4f3e-9087-9bc401b31278",
  "claim_description": "Black OnePlus Nord Buds 2. Left earbud has a small scratch near the stem, and the case has an anime sticker on the bottom."
}
```
- **Validation**:
  - `claim_description`: Minimum 10 characters, maximum 1000 characters.
  - Caller cannot claim their own item (`finder_contact_id != claimant_contact_id`).
  - Item status must be `open`.
- **Conflict Rule (`409 Conflict`)**: Caller cannot submit more than 1 active claim for the same item.
- **Success Response (`201 Created`)**:
```json
{
  "claimId": "0f69a5e8-142c-473d-9d48-3a95c478a87b",
  "itemId": "e3e8f810-951b-419b-a01c-6d814ec9fb3b",
  "claimantContactId": "9a1e4c76-59b1-4f3e-9087-9bc401b31278",
  "claimDescription": "Black OnePlus Nord Buds 2...",
  "status": "pending",
  "createdAt": "2026-09-06T11:20:00Z",
  "updatedAt": "2026-09-06T11:20:00Z"
}
```

### 4.2 List My Claims (Claimant's Dashboard)
Lists all claims submitted by the current user.
- **Method & Endpoint**: `GET /rest/v1/claims?claimant_contact_id=eq.{user_id}&select=*,items(item_id,item_type,location_found,date_found,status)&order=created_at.desc`
- **Auth**: Authenticated user
- **Success Response (`200 OK`)**: List of user's claims with joined item summary and current claim status.

### 4.3 List Received Claims for an Item (Finder's View)
Lists all submitted claims for an item that the caller found.
- **Method & Endpoint**: `GET /rest/v1/claims?item_id=eq.{item_id}&select=claim_id,item_id,claim_description,status,created_at`
- **Auth**: Restricted to the Finder of the item via RLS.
- **Success Response (`200 OK`)**: Array of claims awaiting review.

### 4.4 Review Claim: Verify or Reject (Finder Action)
Finder evaluates the claimant's description and accepts or rejects.
- **Method & Endpoint**: `PATCH /rest/v1/claims?claim_id=eq.{claim_id}`
- **Auth**: Restricted to Finder of the parent item via RLS.
- **Request Body**:
```json
{
  "status": "claim_verified"
}
```
*(or `{"status": "claim_rejected"}`)*
- **Validation**: Current status must be `pending`.
- **Success Response (`200 OK`)**: Updated claim record.

### 4.5 Claimant Photo Decision: "IT'S MINE" vs "NOT MINE"
After reviewing the revealed photo, claimant confirms or closes the claim.
- **Method & Endpoint**: `PATCH /rest/v1/claims?claim_id=eq.{claim_id}`
- **Auth**: Restricted to Claimant (`claimant_contact_id = auth.uid()`).
- **Allowed Transitions**:
  - `claim_verified` ➔ `closed_by_claimant` ("NOT MINE")
  - `claim_verified` ➔ Stays `claim_verified` / triggers contact exchange confirmation
- **Success Response (`200 OK`)**: Updated claim record.

### 4.6 Mark Item as Collected (Handover Complete)
Atomic RPC / function executed when the physical return is complete.
- **Method & Endpoint**: `POST /rest/v1/rpc/mark_claim_collected`
- **Auth**: Authenticated Finder or Claimant.
- **Request Body**:
```json
{
  "p_claim_id": "0f69a5e8-142c-473d-9d48-3a95c478a87b"
}
```
- **Effects**:
  1. Sets target claim status to `collected`.
  2. Sets parent item status to `returned`.
  3. Auto-rejects or closes all other pending claims on that item to `claim_rejected`.
- **Success Response (`200 OK`)**:
```json
{
  "success": true,
  "itemId": "e3e8f810-951b-419b-a01c-6d814ec9fb3b",
  "status": "returned"
}
```

---

## 5. Secure Image & Storage APIs

### 5.1 Upload Item Image (Finder)
Uploads an item photograph to the private storage bucket before creating the listing.
- **Method & Endpoint**: `POST /storage/v1/object/item-images-private/{user_id}/{timestamp}_{filename}.jpg`
- **Auth**: Authenticated user (`user_id = auth.uid()`).
- **Headers**:
  - `Content-Type: image/jpeg` (or `image/png`, `image/webp`)
  - `x-upsert: false`
- **File Limit**: Max 10 MB.
- **Success Response (`200 OK`)**:
```json
{
  "Key": "item-images-private/79ded500-23c2-4fd0-b8c2-8a58315c1dc5/1788685000_headphones.jpg"
}
```

### 5.2 Get Image Signed URL (Revealed Photo Access)
Generates a time-limited signed URL for viewing the item photo.
- **Method & Endpoint**: `POST /rest/v1/rpc/get_claim_image_url`
- **Auth**: Authenticated user.
- **Request Body**:
```json
{
  "p_claim_id": "0f69a5e8-142c-473d-9d48-3a95c478a87b"
}
```
- **Access Rule**:
  - Allowed if `auth.uid() = items.finder_contact_id`.
  - Allowed if `auth.uid() = claims.claimant_contact_id` **AND** `claims.status IN ('claim_verified', 'collected')`.
  - Otherwise throws `403 Forbidden` (`IMAGE_ACCESS_DENIED`).
- **Success Response (`200 OK`)**:
```json
{
  "signedUrl": "https://<supabase-project-ref>.supabase.co/storage/v1/object/sign/item-images-private/...?token=ey...",
  "expiresAt": "2026-09-06T12:20:00Z"
}
```

---

## 6. Mutual Contact Exchange API

### 6.1 Get Mutual Contact Information
Retrieves contact information between Finder and Claimant once a claim is confirmed.
- **Method & Endpoint**: `GET /rest/v1/rpc/get_mutual_contact?p_claim_id={claim_id}`
- **Auth**: Authenticated user.
- **Access Rule**: Allowed **only** if caller is either the Finder or the Claimant, and the claim status is `claim_verified` or `collected`.
- **Success Response (`200 OK`)**:
```json
{
  "claimId": "0f69a5e8-142c-473d-9d48-3a95c478a87b",
  "status": "claim_verified",
  "finder": {
    "name": "Alex Smith",
    "class": "BE - Div B",
    "branch": "Mechanical",
    "contactNumber": "+91 9811122233"
  },
  "claimant": {
    "name": "Jane Doe",
    "class": "TE - Div A",
    "branch": "Computer Science",
    "contactNumber": "+91 9876543210"
  }
}
```
- **Error Response (`403 Forbidden`)**:
```json
{
  "error": {
    "code": "CONTACT_EXCHANGE_NOT_AVAILABLE",
    "message": "Contact details are only accessible after the claim is verified by the finder."
  }
}
```

---

## 7. Lifecycle State Machine

```
               [ ITEM POSTED (open, photo private) ]
                                 │
                                 ▼
                     [ CLAIM SUBMITTED (pending) ]
                                 │
                 ┌───────────────┴───────────────┐
                 │                               │
                 ▼                               ▼
       [ claim_rejected ]                [ claim_verified ]
  (Finder rejected description)     (Photo revealed via signed URL)
                                                 │
                                 ┌───────────────┴───────────────┐
                                 │                               │
                                 ▼                               ▼
                     [ closed_by_claimant ]         [ CONTACT EXCHANGE ]
                         ("NOT MINE")                  ("IT'S MINE")
                                                             │
                                                             ▼
                                                    [ collected / returned ]
                                                (Item closed & archived)
```

---

## 8. Summary Table of Endpoints

| Resource / Scope | Method | Path / RPC | Description | Access |
|---|---|---|---|---|
| **Contacts** | `GET` | `/rest/v1/contacts` | Get user profile | Own profile (`auth.uid()`) |
| **Contacts** | `POST` | `/rest/v1/contacts` | Create profile on onboarding | Authenticated user |
| **Contacts** | `PATCH` | `/rest/v1/contacts` | Update profile | Own profile |
| **Items** | `GET` | `/rest/v1/items` | List public items feed (no photos) | Authenticated |
| **Items** | `POST` | `/rest/v1/items` | Create item listing + photo reference | Finder |
| **Items** | `GET` | `/rest/v1/items` | List Finder's own items | Finder |
| **Claims** | `POST` | `/rest/v1/claims` | Submit free-form claim description | Claimant |
| **Claims** | `GET` | `/rest/v1/claims` | View my submitted claims | Claimant |
| **Claims** | `GET` | `/rest/v1/claims` | View claims received for an item | Finder |
| **Claims** | `PATCH` | `/rest/v1/claims` | Verify or reject claim | Finder |
| **Claims** | `PATCH` | `/rest/v1/claims` | Confirm ownership or close ("NOT MINE") | Claimant |
| **Workflow** | `POST` | `/rpc/mark_claim_collected` | Atomic handover completion | Finder / Claimant |
| **Storage** | `POST` | `/storage/v1/object/...` | Upload item photo to private bucket | Finder |
| **Storage** | `POST` | `/rpc/get_claim_image_url` | Get signed photo URL for verification | Finder / Verified Claimant |
| **Contacts** | `GET` | `/rpc/get_mutual_contact` | Reveal mutual contact info | Finder & Verified Claimant |
