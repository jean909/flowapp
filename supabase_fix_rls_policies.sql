-- CRITICAL FIX: RLS Policies for Social Features
-- Run this in Supabase SQL Editor to fix all permission issues

-- 1. Fix Comments RLS (currently blocking inserts)
DROP POLICY IF EXISTS "Users Comment" ON public.social_comments;
CREATE POLICY "Users can comment" ON public.social_comments 
FOR INSERT WITH CHECK (
  auth.uid() = user_id
);

-- 2. Add missing SELECT policy for comments with profile join
DROP POLICY IF EXISTS "Public Read Comments" ON public.social_comments;
CREATE POLICY "Public can read comments" ON public.social_comments 
FOR SELECT USING (true);

-- 3. Fix Likes to prevent duplicates (already has UNIQUE constraint, but add policy)
DROP POLICY IF EXISTS "Users Toggle Like" ON public.social_likes;
CREATE POLICY "Users can like" ON public.social_likes 
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users Unlike" ON public.social_likes;
CREATE POLICY "Users can unlike" ON public.social_likes 
FOR DELETE USING (auth.uid() = user_id);

-- 4. Add DELETE policy for posts (users can delete their own)
DROP POLICY IF EXISTS "Users Delete Own Posts" ON public.social_posts;
CREATE POLICY "Users can delete own posts" ON public.social_posts 
FOR DELETE USING (auth.uid() = user_id);

-- 5. Ensure profiles are readable for joins
DROP POLICY IF EXISTS "Public can read profiles" ON public.profiles;
CREATE POLICY "Public can read profiles" ON public.profiles 
FOR SELECT USING (true);

-- 6. Fix chat policies to allow room creation
DROP POLICY IF EXISTS "Users can create chat rooms" ON public.chat_rooms;
CREATE POLICY "Users can create chat rooms" ON public.chat_rooms 
FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can add participants" ON public.chat_participants;
CREATE POLICY "Users can add participants" ON public.chat_participants 
FOR INSERT WITH CHECK (true);

-- 7. Allow users to read chat rooms they're part of
DROP POLICY IF EXISTS "Users can read own chat rooms" ON public.chat_rooms;
CREATE POLICY "Users can read own chat rooms" ON public.chat_rooms 
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM public.chat_participants 
    WHERE room_id = chat_rooms.id AND user_id = auth.uid()
  )
);

-- 8. Allow reading participants
DROP POLICY IF EXISTS "Users can read participants" ON public.chat_participants;
CREATE POLICY "Users can read participants" ON public.chat_participants 
FOR SELECT USING (true);

-- Verify all tables have RLS enabled
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
