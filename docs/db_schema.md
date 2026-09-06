# Database schema

## contacts (Part of user onboarding)
- uuid contact_id (PK, references auth.users.id)
- text name
- text class
- text branch
- text prn
- text contact_number
- timestamptz created_at

## items (Posted by finder; image & details hidden from public)
- uuid item_id (PK, default gen_random_uuid())
- uuid finder_contact_id (FK references contacts.contact_id)
- text item_type (e.g. headphones, earbuds, book, bottle, backpack - publicly visible)
- text location_found (publicly visible)
- date date_found (publicly visible)
- text image_path (private Supabase storage bucket path)
- text status (open, returned)
- timestamptz created_at

## claims (Managed between claimant and finder)
- uuid claim_id (PK, default gen_random_uuid())
- uuid item_id (FK references items.item_id)
- uuid claimant_contact_id (FK references contacts.contact_id)
- text claim_description (free-form proof of ownership)
- text status (pending, claim_verified, claim_rejected, closed_by_claimant, collected)
- timestamptz created_at
- timestamptz updated_at
