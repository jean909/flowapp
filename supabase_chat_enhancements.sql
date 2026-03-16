-- =============================================
-- CHAT ENHANCEMENTS: VOICE MESSAGES & SPEED
-- =============================================

-- 1. Add support for message types and audio
ALTER TABLE public.chat_messages 
ADD COLUMN IF NOT EXISTS message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'audio', 'image', 'video')),
ADD COLUMN IF NOT EXISTS audio_url TEXT,
ADD COLUMN IF NOT EXISTS duration_seconds INTEGER;

-- 2. Optimize Last Message sync (Speed up)
-- We'll use a trigger to update last_message on chat_rooms automatically
-- This is faster than doing it from the client side in a second request

CREATE OR REPLACE FUNCTION update_chat_room_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.chat_rooms
    SET 
        last_message = CASE 
            WHEN NEW.message_type = 'text' THEN NEW.content 
            WHEN NEW.message_type = 'audio' THEN '🎤 Voice message'
            WHEN NEW.message_type = 'image' THEN '📷 Photo'
            ELSE 'New message'
        END,
        last_message_at = NEW.created_at
    WHERE id = NEW.room_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_chat_message_inserted ON public.chat_messages;
CREATE TRIGGER on_chat_message_inserted
AFTER INSERT ON public.chat_messages
FOR EACH ROW EXECUTE PROCEDURE update_chat_room_last_message();

-- 3. Ensure Storage for Audio
-- You must manually create 'chat_attachments' bucket or similar if preferred
-- Policy: Participants can read/upload voice messages
CREATE POLICY "Users can upload chat attachments" ON storage.objects 
FOR INSERT WITH CHECK ( bucket_id = 'chat_attachments' );

CREATE POLICY "Users can view chat attachments" ON storage.objects 
FOR SELECT USING ( bucket_id = 'chat_attachments' );
