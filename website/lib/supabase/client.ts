import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL || 'https://zoaeypxhumpllhpasgun.supabase.co';
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY || 'sb_publishable_L_BB7F-9EGtXjvFV_h6R1Q_lDSo_qPB';

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

