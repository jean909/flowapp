-- Fix relationship between chat_participants and profiles to allow joining
-- This resolves the "Could not find a relationship" error in the Messages list

-- 1. Drop existing constraint
ALTER TABLE public.chat_participants
DROP CONSTRAINT IF EXISTS chat_participants_user_id_fkey;

-- 2. Add new constraint pointing to public.profiles
ALTER TABLE public.chat_participants
ADD CONSTRAINT chat_participants_user_id_fkey
FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 3. Also fix chat_messages sender_id just in case
ALTER TABLE public.chat_messages
DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey;

ALTER TABLE public.chat_messages
ADD CONSTRAINT chat_messages_sender_id_fkey
FOREIGN KEY (sender_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
