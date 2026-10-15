-- Houserent Backend — Supabase Schema
-- Run this in your Supabase SQL Editor

-- ─── Users ───────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email       TEXT UNIQUE NOT NULL,
    password    TEXT NOT NULL,     -- NOTE: store hashed passwords in production
    name        TEXT NOT NULL,
    phone       TEXT,
    role        TEXT NOT NULL DEFAULT 'tenant' CHECK (role IN ('tenant', 'owner')),
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Listings ─────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS listings (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       TEXT NOT NULL,
    description TEXT,
    price       NUMERIC NOT NULL,
    type        TEXT NOT NULL DEFAULT 'apartment' CHECK (type IN ('apartment', 'villa', 'house')),
    bedrooms    INTEGER,
    bathrooms   INTEGER,
    area        INTEGER,           -- sq ft
    address     TEXT NOT NULL,
    city        TEXT NOT NULL,
    latitude    DOUBLE PRECISION,
    longitude   DOUBLE PRECISION,
    amenities   TEXT[] DEFAULT '{}',
    images      TEXT[] DEFAULT '{}',  -- Supabase Storage public URLs
    furnished   BOOLEAN DEFAULT FALSE,
    available   BOOLEAN DEFAULT TRUE,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index for geo queries (/api/listings/nearby)
CREATE INDEX IF NOT EXISTS listings_geo_idx   ON listings (latitude, longitude);
CREATE INDEX IF NOT EXISTS listings_owner_idx ON listings (owner_id);
CREATE INDEX IF NOT EXISTS listings_city_idx  ON listings (city);

-- ─── Favorites ────────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS favorites (
    id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    listing_id  UUID NOT NULL REFERENCES listings(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, listing_id)
);

-- ─── Row Level Security ───────────────────────────────────────────────────────
-- RLS is enabled on all tables. Our Cloudflare Worker is the sole client
-- (uses anon key), so policies allow the anon role to do what the API needs.
-- The Worker enforces all business logic (ownership checks, auth, etc.).

ALTER TABLE users    ENABLE ROW LEVEL SECURITY;
ALTER TABLE listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- Users
CREATE POLICY "anon can insert users" ON users FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon can read users"   ON users FOR SELECT TO anon USING (true);

-- Listings
CREATE POLICY "anon can read listings"   ON listings FOR SELECT TO anon USING (true);
CREATE POLICY "anon can insert listings" ON listings FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon can update listings" ON listings FOR UPDATE TO anon USING (true);
CREATE POLICY "anon can delete listings" ON listings FOR DELETE TO anon USING (true);

-- Favorites
CREATE POLICY "anon can read favorites"   ON favorites FOR SELECT TO anon USING (true);
CREATE POLICY "anon can insert favorites" ON favorites FOR INSERT TO anon WITH CHECK (true);
CREATE POLICY "anon can delete favorites" ON favorites FOR DELETE TO anon USING (true);

-- ─── Storage — Listing Images ─────────────────────────────────────────────────
-- Creates a public bucket for listing image uploads.
INSERT INTO storage.buckets (id, name, public)
VALUES ('listing-images', 'listing-images', true)
ON CONFLICT (id) DO NOTHING;

-- Allow anon (our Worker) to upload images
CREATE POLICY "anon can upload listing images"
    ON storage.objects FOR INSERT TO anon
    WITH CHECK (bucket_id = 'listing-images');

-- Allow anyone to view images (public bucket)
CREATE POLICY "public can read listing images"
    ON storage.objects FOR SELECT TO anon
    USING (bucket_id = 'listing-images');

-- Allow anon to delete images (for owners editing/deleting listings)
CREATE POLICY "anon can delete listing images"
    ON storage.objects FOR DELETE TO anon
    USING (bucket_id = 'listing-images');
