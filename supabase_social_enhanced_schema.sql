-- Enhanced Social Media Schema
-- Add these to your existing supabase_social_complete_schema.sql

-- 1. Enhance profiles table with social fields
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS username TEXT UNIQUE,
ADD COLUMN IF NOT EXISTS bio TEXT,
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Create index for username search
CREATE INDEX IF NOT EXISTS idx_profiles_username ON public.profiles(username);

-- 2. Enhance social_posts with post types
ALTER TABLE public.social_posts
ADD COLUMN IF NOT EXISTS post_type TEXT DEFAULT 'text', -- 'text', 'image', 'meal', 'workout'
ADD COLUMN IF NOT EXISTS meal_id UUID REFERENCES public.daily_logs(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS workout_id UUID REFERENCES public.exercise_logs(id) ON DELETE SET NULL;

-- 3. Create stories table (24h temporary posts)
CREATE TABLE IF NOT EXISTS public.social_stories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now() + interval '24 hours') NOT NULL
);

-- 4. Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    type TEXT NOT NULL, -- 'like', 'comment', 'follow'
    post_id UUID REFERENCES public.social_posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES public.social_comments(id) ON DELETE CASCADE,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- RLS Policies for new tables
ALTER TABLE public.social_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Stories: Public can view non-expired stories
CREATE POLICY "Public Read Active Stories" ON public.social_stories 
FOR SELECT USING (expires_at > now());

-- Stories: Users can create their own
CREATE POLICY "Users Create Own Stories" ON public.social_stories 
FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Stories: Users can delete their own
CREATE POLICY "Users Delete Own Stories" ON public.social_stories 
FOR DELETE USING (auth.uid() = user_id);

-- Notifications: Users can only see their own
CREATE POLICY "Users Read Own Notifications" ON public.notifications 
FOR SELECT USING (auth.uid() = user_id);

-- Notifications: Users can update their own (mark as read)
CREATE POLICY "Users Update Own Notifications" ON public.notifications 
FOR UPDATE USING (auth.uid() = user_id);

-- Function to create notification on like
CREATE OR REPLACE FUNCTION notify_on_like()
RETURNS TRIGGER AS $$
BEGIN
  -- Don't notify if user likes their own post
  IF NEW.user_id != (SELECT user_id FROM social_posts WHERE id = NEW.post_id) THEN
    INSERT INTO notifications (user_id, actor_id, type, post_id)
    SELECT user_id, NEW.user_id, 'like', NEW.post_id
    FROM social_posts WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_like_notify
  AFTER INSERT ON public.social_likes
  FOR EACH ROW EXECUTE PROCEDURE notify_on_like();

-- Function to create notification on comment
CREATE OR REPLACE FUNCTION notify_on_comment()
RETURNS TRIGGER AS $$
BEGIN
  -- Don't notify if user comments on their own post
  IF NEW.user_id != (SELECT user_id FROM social_posts WHERE id = NEW.post_id) THEN
    INSERT INTO notifications (user_id, actor_id, type, post_id, comment_id)
    SELECT user_id, NEW.user_id, 'comment', NEW.post_id, NEW.id
    FROM social_posts WHERE id = NEW.post_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_comment_notify
  AFTER INSERT ON public.social_comments
  FOR EACH ROW EXECUTE PROCEDURE notify_on_comment();

-- Function to create notification on follow
CREATE OR REPLACE FUNCTION notify_on_follow()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO notifications (user_id, actor_id, type)
  VALUES (NEW.following_id, NEW.follower_id, 'follow');
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_follow_notify
  AFTER INSERT ON public.social_follows
  FOR EACH ROW EXECUTE PROCEDURE notify_on_follow();

-- Function to auto-delete expired stories (run this as a cron job or manually)
CREATE OR REPLACE FUNCTION delete_expired_stories()
RETURNS void AS $$
BEGIN
  DELETE FROM public.social_stories WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql;
