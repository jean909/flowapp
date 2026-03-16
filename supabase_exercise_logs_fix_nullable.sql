-- Fix exercise_logs to make exercise_id nullable for custom exercises support
-- This must be run AFTER supabase_exercise_logs_custom_update.sql

-- First, drop the NOT NULL constraint on exercise_id
ALTER TABLE public.exercise_logs
ALTER COLUMN exercise_id DROP NOT NULL;

-- The check_exercise_reference constraint from supabase_exercise_logs_custom_update.sql
-- already ensures that either exercise_id OR custom_exercise_id is set

