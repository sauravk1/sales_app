-- Enable Realtime for products table (run in Supabase SQL Editor)
-- Only needed if not already enabled

ALTER PUBLICATION supabase_realtime ADD TABLE public.products;

-- Verify
SELECT tablename FROM pg_publication_tables
WHERE pubname = 'supabase_realtime';
