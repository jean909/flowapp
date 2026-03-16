-- ============================================
-- SUPABASE REALTIME SETUP FOR DASHBOARD
-- ============================================
-- This script enables Realtime for dashboard tables
-- Run this in Supabase SQL Editor
--
-- IMPORTANT: Make sure you have run supabase_daily_journal_entries_schema.sql first
-- if you want to enable Realtime for daily_journal_entries table

-- Enable Realtime for daily_logs table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'daily_logs') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE daily_logs;
        RAISE NOTICE 'Realtime enabled for daily_logs';
    ELSE
        RAISE NOTICE 'Table daily_logs does not exist, skipping...';
    END IF;
END $$;

-- Enable Realtime for exercise_logs table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'exercise_logs') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE exercise_logs;
        RAISE NOTICE 'Realtime enabled for exercise_logs';
    ELSE
        RAISE NOTICE 'Table exercise_logs does not exist, skipping...';
    END IF;
END $$;

-- Enable Realtime for water_logs table
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'water_logs') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE water_logs;
        RAISE NOTICE 'Realtime enabled for water_logs';
    ELSE
        RAISE NOTICE 'Table water_logs does not exist, skipping...';
    END IF;
END $$;

-- Enable Realtime for daily_journal_entries table (optional, for future use)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'daily_journal_entries') THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE daily_journal_entries;
        RAISE NOTICE 'Realtime enabled for daily_journal_entries';
    ELSE
        RAISE NOTICE 'Table daily_journal_entries does not exist, skipping...';
    END IF;
END $$;

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
-- 4. Users will only receive events for their own data (due to RLS)
--
-- ============================================
-- ALTERNATIVE: Enable via Supabase Dashboard
-- ============================================
-- 1. Go to Supabase Dashboard
-- 2. Navigate to: Database → Replication
-- 3. Find each table (daily_logs, exercise_logs, water_logs, daily_journal_entries)
-- 4. Toggle the switch to enable Realtime
-- 5. Click "Save"

