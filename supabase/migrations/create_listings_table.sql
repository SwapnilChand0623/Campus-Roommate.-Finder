-- Create listings table for marketplace
CREATE TABLE IF NOT EXISTS public.listings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    seller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    seller_name TEXT NOT NULL,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    photo_urls TEXT[] DEFAULT '{}',
    category TEXT NOT NULL,
    is_sold BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on seller_id for faster queries
CREATE INDEX IF NOT EXISTS idx_listings_seller_id ON public.listings(seller_id);

-- Create index on category for filtering
CREATE INDEX IF NOT EXISTS idx_listings_category ON public.listings(category);

-- Create index on is_sold for filtering active listings
CREATE INDEX IF NOT EXISTS idx_listings_is_sold ON public.listings(is_sold);

-- Create index on created_at for sorting
CREATE INDEX IF NOT EXISTS idx_listings_created_at ON public.listings(created_at DESC);

-- Enable Row Level Security
ALTER TABLE public.listings ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view active listings
CREATE POLICY "Anyone can view active listings"
ON public.listings
FOR SELECT
USING (is_sold = FALSE OR seller_id = auth.uid());

-- Policy: Users can view their own listings (including sold ones)
CREATE POLICY "Users can view their own listings"
ON public.listings
FOR SELECT
USING (seller_id = auth.uid());

-- Policy: Users can create their own listings
CREATE POLICY "Users can create their own listings"
ON public.listings
FOR INSERT
WITH CHECK (seller_id = auth.uid());

-- Policy: Users can update their own listings
CREATE POLICY "Users can update their own listings"
ON public.listings
FOR UPDATE
USING (seller_id = auth.uid())
WITH CHECK (seller_id = auth.uid());

-- Policy: Users can delete their own listings
CREATE POLICY "Users can delete their own listings"
ON public.listings
FOR DELETE
USING (seller_id = auth.uid());

-- Create storage bucket for listing photos
INSERT INTO storage.buckets (id, name, public)
VALUES ('listings', 'listings', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policy: Anyone can view listing photos
CREATE POLICY "Anyone can view listing photos"
ON storage.objects
FOR SELECT
USING (bucket_id = 'listings');

-- Storage policy: Users can upload their own listing photos
CREATE POLICY "Users can upload their own listing photos"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'listings' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage policy: Users can update their own listing photos
CREATE POLICY "Users can update their own listing photos"
ON storage.objects
FOR UPDATE
USING (
    bucket_id = 'listings' 
    AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'listings' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Storage policy: Users can delete their own listing photos
CREATE POLICY "Users can delete their own listing photos"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'listings' 
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to automatically update updated_at
CREATE TRIGGER update_listings_updated_at
BEFORE UPDATE ON public.listings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
