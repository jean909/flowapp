-- ============================================
-- SUPABASE REALTIME SETUP FOR FLOW APP
-- ============================================
-- This script enables Realtime for social feed tables
-- Run this in Supabase SQL Editor

-- Enable Realtime for social_posts table
ALTER PUBLICATION supabase_realtime ADD TABLE social_posts;

-- Enable Realtime for social_likes table
ALTER PUBLICATION supabase_realtime ADD TABLE social_likes;

-- Enable Realtime for social_comments table
ALTER PUBLICATION supabase_realtime ADD TABLE social_comments;

-- Verify Realtime is enabled (optional check)
-- You can run this to see which tables have Realtime enabled:
-- SELECT schemaname, tablename 
-- FROM pg_publication_tables 
-- WHERE pubname = 'supabase_realtime';

-- ============================================
-- NOTES:
-- ============================================
-- 1. Realtime requires Row Level Security (RLS) to be enabled
-- 2. Make sure your RLS policies allow users to read the data they need
-- 3. Realtime works with INSERT, UPDATE, DELETE events
-- 4. For UPDATE events, you need to specify which columns to track
--    (by default, all columns are tracked)

-- ============================================
-- ALTERNATIVE: Enable via Supabase Dashboard
-- ============================================
-- 1. Go to Supabase Dashboard
-- 2. Navigate to: Database → Replication
-- 3. Find each table (social_posts, social_likes, social_comments)
-- 4. Toggle the switch to enable Realtime
-- 5. Click "Save"

