-- ============================================================
-- ScamShield Supabase Schema & Storage Configuration
-- ============================================================

-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ------------------------------------------------------------
-- 1. Profiles Table (User roles: 'admin', 'reporter', 'user')
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    role TEXT NOT NULL DEFAULT 'reporter' CHECK (role IN ('admin', 'reporter', 'user')),
    reputation_score INT DEFAULT 100,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2. Scam Reports Table
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.scam_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    scam_type TEXT NOT NULL CHECK (scam_type IN (
        'phishing', 
        'crypto_investment', 
        'impersonation', 
        'romance', 
        'fake_store', 
        'job_scam', 
        'caller_scam', 
        'other'
    )),
    target_phone TEXT,
    target_url TEXT,
    target_wallet TEXT,
    target_email TEXT,
    financial_loss NUMERIC DEFAULT 0.0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    risk_score INT DEFAULT 0,
    ai_analysis JSONB DEFAULT '{}'::jsonb,
    blockchain_tx_hash TEXT,
    blockchain_timestamp TIMESTAMPTZ,
    evidence_urls TEXT[] DEFAULT ARRAY[]::TEXT[],
    reporter_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    admin_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for lightning fast scam searches
CREATE INDEX IF NOT EXISTS idx_scam_reports_target_phone ON public.scam_reports(target_phone);
CREATE INDEX IF NOT EXISTS idx_scam_reports_target_url ON public.scam_reports(target_url);
CREATE INDEX IF NOT EXISTS idx_scam_reports_target_wallet ON public.scam_reports(target_wallet);
CREATE INDEX IF NOT EXISTS idx_scam_reports_scam_type ON public.scam_reports(scam_type);
CREATE INDEX IF NOT EXISTS idx_scam_reports_status ON public.scam_reports(status);
CREATE INDEX IF NOT EXISTS idx_scam_reports_risk_score ON public.scam_reports(risk_score);

-- ------------------------------------------------------------
-- 3. Row Level Security (RLS) Policies
-- ------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.scam_reports ENABLE ROW LEVEL SECURITY;

-- Profiles: Anyone authenticated can read profiles; users can update own profile
CREATE POLICY "Public profiles read access" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Scam Reports:
-- Anyone (public) can view approved reports for searching & dashboard
CREATE POLICY "Public approved scam reports view" ON public.scam_reports 
    FOR SELECT USING (status = 'approved' OR auth.role() = 'authenticated');

-- Authenticated users or anon reporters can insert reports
CREATE POLICY "Anyone can submit a scam report" ON public.scam_reports 
    FOR INSERT WITH CHECK (true);

-- Admins or reporters can update reports
CREATE POLICY "Admins or owners update scam reports" ON public.scam_reports 
    FOR UPDATE USING (
        auth.uid() = reporter_id OR 
        EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
    );

-- ------------------------------------------------------------
-- 4. Storage Bucket for Evidence Attachments
-- ------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public) 
VALUES ('scam-evidence', 'scam-evidence', true)
ON CONFLICT (id) DO NOTHING;

-- Storage RLS policy allowing upload & public read
CREATE POLICY "Public read for scam evidence" ON storage.objects 
    FOR SELECT USING (bucket_id = 'scam-evidence');
CREATE POLICY "Public upload for scam evidence" ON storage.objects 
    FOR INSERT WITH CHECK (bucket_id = 'scam-evidence');

-- ------------------------------------------------------------
-- 5. Initial Seed Data for Demo & Testing
-- ------------------------------------------------------------
INSERT INTO public.scam_reports (
    title, description, scam_type, target_url, target_phone, target_wallet, financial_loss, status, risk_score, ai_analysis, blockchain_tx_hash, blockchain_timestamp, evidence_urls
) VALUES 
(
    'Fake Bank Phishing Portal (SecureLogin-Alert)',
    'Received urgent SMS claiming my bank account is locked. Redirected to fake login form harvesting credentials and OTP.',
    'phishing',
    'http://secure-login-alert-bank.xyz/verify',
    '+18005550199',
    NULL,
    1500.00,
    'approved',
    95,
    '{"risk_level": "CRITICAL", "signals": ["Urgent SMS lure", "Domain spoofing", "Credential harvesting form"], "summary": "High confidence phishing domain targeting financial credentials."}'::jsonb,
    '0x7a8f9c2d1b3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9',
    NOW() - INTERVAL '2 days',
    ARRAY['https://picsum.photos/400/300']
),
(
    'Crypto Doubler Bot Scam',
    'Telegram bot guaranteed 200% returns in 24 hours on Ethereum deposits. Sent 0.5 ETH and contact blocked.',
    'crypto_investment',
    'https://t.me/eth_doubler_vip_bot',
    NULL,
    '0x32Be343B94f860124dC4fEe278FDCBD38C102D88',
    1800.00,
    'approved',
    92,
    '{"risk_level": "HIGH", "signals": ["Ponzi return guarantee", "Known scam smart contract pattern"], "summary": "Unrealistic yield promise combined with verified scam wallet address."}'::jsonb,
    '0x1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2',
    NOW() - INTERVAL '1 day',
    ARRAY['https://picsum.photos/400/301']
),
(
    'Fake Job Offer - Pay For Training Equipment',
    'Received remote data entry job offer via WhatsApp. Requested upfront wire transfer of $450 for laptop setup.',
    'job_scam',
    NULL,
    '+18889021234',
    NULL,
    450.00,
    'pending',
    82,
    '{"risk_level": "HIGH", "signals": ["Upfront payment for equipment", "Unverified recruiter phone"], "summary": "Typical advance-fee job recruitment fraud."}'::jsonb,
    NULL,
    NULL,
    ARRAY[]::TEXT[]
);
