-- Add Reposts functionality to social posts

-- 1. Add reposts_count to social_posts table
ALTER TABLE public.social_posts
ADD COLUMN IF NOT EXISTS reposts_count INTEGER DEFAULT 0;

-- 2. Create social_reposts table
CREATE TABLE IF NOT EXISTS public.social_reposts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    post_id UUID REFERENCES public.social_posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, post_id)
);

-- 3. Enable RLS
ALTER TABLE public.social_reposts ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies
CREATE POLICY "Public can view reposts" ON public.social_reposts
FOR SELECT USING (true);

CREATE POLICY "Logged in users can repost" ON public.social_reposts
FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can remove their repost" ON public.social_reposts
FOR DELETE USING (auth.uid() = user_id);

-- 5. Trigger to update reposts_count on social_posts
CREATE OR REPLACE FUNCTION update_reposts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF (TG_OP = 'INSERT') THEN
        UPDATE public.social_posts
        SET reposts_count = reposts_count + 1
        WHERE id = NEW.post_id;
    ELSIF (TG_OP = 'DELETE') THEN
        UPDATE public.social_posts
        SET reposts_count = GREATEST(0, reposts_count - 1)
        WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_repost_change
AFTER INSERT OR DELETE ON public.social_reposts
FOR EACH ROW EXECUTE PROCEDURE update_reposts_count();
