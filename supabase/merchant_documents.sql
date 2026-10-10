-- ============================================================
-- merchant_documents: durable home for merchant compliance uploads
-- ============================================================
-- The KYC vault used to write into audit_logs, whose RLS is
-- staff-only (auth_is_staff()), so a merchant could never read
-- back or persist what they uploaded. This table is owned by the
-- merchant who owns the business.

CREATE TABLE IF NOT EXISTS public.merchant_documents (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id      UUID        NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  doc_type         TEXT        NOT NULL CHECK (doc_type IN ('business_registration', 'health_certificate', 'tax_clearance')),
  reference_number TEXT        NOT NULL DEFAULT '',
  file_url         TEXT        NOT NULL DEFAULT '',
  status           TEXT        NOT NULL DEFAULT 'submitted' CHECK (status IN ('submitted', 'under_review', 'verified', 'rejected')),
  reviewer_note    TEXT,
  uploaded_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (business_id, doc_type)
);

CREATE INDEX IF NOT EXISTS idx_merchant_documents_business
  ON public.merchant_documents (business_id);

ALTER TABLE public.merchant_documents ENABLE ROW LEVEL SECURITY;

-- Merchant: manage documents for a business you own
DROP POLICY IF EXISTS "merchant_docs_select_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_select_owner" ON public.merchant_documents
  FOR SELECT TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
  ));

DROP POLICY IF EXISTS "merchant_docs_insert_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_insert_owner" ON public.merchant_documents
  FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
  ));

DROP POLICY IF EXISTS "merchant_docs_update_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_update_owner" ON public.merchant_documents
  FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
  ))
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
  ));

DROP POLICY IF EXISTS "merchant_docs_delete_owner" ON public.merchant_documents;
CREATE POLICY "merchant_docs_delete_owner" ON public.merchant_documents
  FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.businesses b
    WHERE b.id = merchant_documents.business_id AND b.owner_id = auth.uid()
  ));

-- Admin / super admin: full access for compliance review
DROP POLICY IF EXISTS "merchant_docs_staff_all" ON public.merchant_documents;
CREATE POLICY "merchant_docs_staff_all" ON public.merchant_documents
  FOR ALL TO authenticated
  USING (public.auth_is_staff())
  WITH CHECK (public.auth_is_staff());

-- ============================================================
-- businesses: a contact number merchants actually control
-- ============================================================
-- There was no phone column, so the app fell back to a hardcoded
-- number that customers were told to call.

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS phone TEXT NOT NULL DEFAULT '';

-- A brand new store has no reviews yet, so it must not arrive
-- pre-rated at a perfect 5.00.
ALTER TABLE public.businesses
  ALTER COLUMN rating SET DEFAULT 0.00;

UPDATE public.businesses SET rating = 0.00
WHERE rating = 5.00
  AND NOT EXISTS (SELECT 1 FROM public.reviews r WHERE r.business_id = businesses.id);
