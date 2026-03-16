-- FIX STORAGE BUCKET AND POLICIES FOR SOCIAL POSTS

-- 1. Create the bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('posts', 'posts', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Allow anyone to read from the 'posts' bucket
CREATE POLICY "Public Read Posts"
ON storage.objects FOR SELECT
USING (bucket_id = 'posts');

-- 3. Allow authenticated users to upload to their own folder in 'posts' bucket
CREATE POLICY "Authenticated Users Upload Posts"
ON storage.objects FOR INSERT
WITH CHECK (
    bucket_id = 'posts' AND
    auth.role() = 'authenticated' AND
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 4. Allow users to delete their own posts
CREATE POLICY "Users Delete Own Posts"
ON storage.objects FOR DELETE
USING (
    bucket_id = 'posts' AND
    auth.uid()::text = (storage.foldername(name))[1]
);
