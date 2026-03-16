-- =============================================
-- FINAL RLS & PERMISSIONS FIX FOR FLOW APP
-- =============================================
-- Run this in Supabase SQL Editor to fix 403 errors and Onboarding bugs

-- 1) FOREIGN KEY CONSISTENCY (Point all to public.profiles)
-- This ensures joins with profiles (for usernames, avatars) work correctly
ALTER TABLE IF EXISTS public.social_posts DROP CONSTRAINT IF EXISTS social_posts_user_id_fkey;
ALTER TABLE IF EXISTS public.social_posts
  ADD CONSTRAINT social_posts_user_id_fkey FOREIGN KEY (user_id)
  REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.social_likes DROP CONSTRAINT IF EXISTS social_likes_user_id_fkey;
ALTER TABLE IF EXISTS public.social_likes
  ADD CONSTRAINT social_likes_user_id_fkey FOREIGN KEY (user_id)
  REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.chat_participants DROP CONSTRAINT IF EXISTS chat_participants_user_id_fkey;
ALTER TABLE IF EXISTS public.chat_participants
  ADD CONSTRAINT chat_participants_user_id_fkey FOREIGN KEY (user_id)
  REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.chat_messages DROP CONSTRAINT IF EXISTS chat_messages_sender_id_fkey;
ALTER TABLE IF EXISTS public.chat_messages
  ADD CONSTRAINT chat_messages_sender_id_fkey FOREIGN KEY (sender_id)
  REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.social_follows DROP CONSTRAINT IF EXISTS social_follows_follower_id_fkey;
ALTER TABLE IF EXISTS public.social_follows ADD CONSTRAINT social_follows_follower_id_fkey FOREIGN KEY (follower_id) REFERENCES public.profiles(id) ON DELETE CASCADE;
ALTER TABLE IF EXISTS public.social_follows DROP CONSTRAINT IF EXISTS social_follows_following_id_fkey;
ALTER TABLE IF EXISTS public.social_follows ADD CONSTRAINT social_follows_following_id_fkey FOREIGN KEY (following_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.social_reposts DROP CONSTRAINT IF EXISTS social_reposts_user_id_fkey;
ALTER TABLE IF EXISTS public.social_reposts ADD CONSTRAINT social_reposts_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS public.social_stories DROP CONSTRAINT IF EXISTS social_stories_user_id_fkey;
ALTER TABLE IF EXISTS public.social_stories ADD CONSTRAINT social_stories_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.profiles(id) ON DELETE CASCADE;

-- 2) ENABLE ROW LEVEL SECURITY
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_reposts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.social_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coin_transactions ENABLE ROW LEVEL SECURITY;

-- 3) PROFILES POLICIES
DROP POLICY IF EXISTS "Public can read profiles" ON public.profiles;
CREATE POLICY "Public can read profiles" ON public.profiles
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles
FOR UPDATE USING (auth.uid() = id);

-- 4) SOCIAL LIKES FIX
DROP POLICY IF EXISTS "Users can like" ON public.social_likes;
CREATE POLICY "Users can like" ON public.social_likes
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can unlike" ON public.social_likes;
CREATE POLICY "Users can unlike" ON public.social_likes
FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can read likes" ON public.social_likes;
CREATE POLICY "Public can read likes" ON public.social_likes
FOR SELECT USING (true);

-- 5) CHAT SYSTEM FIX
DROP POLICY IF EXISTS "Users can create chat rooms" ON public.chat_rooms;
CREATE POLICY "Users can create chat rooms" ON public.chat_rooms
FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can read own chat rooms" ON public.chat_rooms;
CREATE POLICY "Users can read own chat rooms" ON public.chat_rooms
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can add participants" ON public.chat_participants;
CREATE POLICY "Users can add participants" ON public.chat_participants
FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Users can read participants" ON public.chat_participants;
CREATE POLICY "Users can read participants" ON public.chat_participants
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Participants Read Messages" ON public.chat_messages;
CREATE POLICY "Participants Read Messages" ON public.chat_messages
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Participants Send Messages" ON public.chat_messages;
CREATE POLICY "Participants Send Messages" ON public.chat_messages
FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- 6) COIN TRANSACTIONS FIX
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.coin_transactions;
CREATE POLICY "Users can view their own transactions" ON public.coin_transactions
FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can create transactions" ON public.coin_transactions;
CREATE POLICY "Users can create transactions" ON public.coin_transactions
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 7) SOCIAL COMMENTS FIX
DROP POLICY IF EXISTS "Users can comment" ON public.social_comments;
CREATE POLICY "Users can comment" ON public.social_comments
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can read comments" ON public.social_comments;
CREATE POLICY "Public can read comments" ON public.social_comments
FOR SELECT USING (true);

-- 8) SOCIAL POSTS FIX
DROP POLICY IF EXISTS "Public Read Posts" ON public.social_posts;
DROP POLICY IF EXISTS "Public can read posts" ON public.social_posts;
CREATE POLICY "Public can read posts" ON public.social_posts
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users Create Posts" ON public.social_posts;
DROP POLICY IF EXISTS "Users can create posts" ON public.social_posts;
CREATE POLICY "Users can create posts" ON public.social_posts
FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users Delete Own Posts" ON public.social_posts;
DROP POLICY IF EXISTS "Users can delete own posts" ON public.social_posts;
CREATE POLICY "Users can delete own posts" ON public.social_posts
FOR DELETE USING (auth.uid() = user_id);

-- 9) SOCIAL FOLLOWS FIX
DROP POLICY IF EXISTS "Public can read follows" ON public.social_follows;
CREATE POLICY "Public can read follows" ON public.social_follows
FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can follow" ON public.social_follows;
CREATE POLICY "Users can follow" ON public.social_follows
FOR INSERT WITH CHECK (auth.uid() = follower_id);

DROP POLICY IF EXISTS "Users can unfollow" ON public.social_follows;
CREATE POLICY "Users can unfollow" ON public.social_follows
FOR DELETE USING (auth.uid() = follower_id);

-- 10) REPOSTS & STORIES
DROP POLICY IF EXISTS "Public can read reposts" ON public.social_reposts;
CREATE POLICY "Public can read reposts" ON public.social_reposts FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can repost" ON public.social_reposts;
CREATE POLICY "Users can repost" ON public.social_reposts FOR INSERT WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Users can remove repost" ON public.social_reposts;
CREATE POLICY "Users can remove repost" ON public.social_reposts FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Public can read stories" ON public.social_stories;
CREATE POLICY "Public can read stories" ON public.social_stories FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can add stories" ON public.social_stories;
CREATE POLICY "Users can add stories" ON public.social_stories FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 11) GRANTS
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.social_likes TO authenticated;
GRANT SELECT, INSERT ON public.chat_rooms TO authenticated;
GRANT SELECT, INSERT ON public.chat_participants TO authenticated;
GRANT SELECT, INSERT ON public.chat_messages TO authenticated;
GRANT SELECT, INSERT ON public.social_comments TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.social_posts TO authenticated;
GRANT SELECT, INSERT ON public.coin_transactions TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.social_follows TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.social_reposts TO authenticated;
GRANT SELECT, INSERT ON public.social_stories TO authenticated;

-- 12) INDEXES
CREATE INDEX IF NOT EXISTS idx_profiles_id ON public.profiles(id);
CREATE INDEX IF NOT EXISTS idx_social_posts_user_id ON public.social_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_social_likes_user_id ON public.social_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON public.chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_user_id ON public.coin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_social_comments_user_id ON public.social_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_social_follows_follower_id ON public.social_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_social_follows_following_id ON public.social_follows(following_id);
CREATE INDEX IF NOT EXISTS idx_social_reposts_user_id ON public.social_reposts(user_id);
CREATE INDEX IF NOT EXISTS idx_social_stories_user_id ON public.social_stories(user_id);