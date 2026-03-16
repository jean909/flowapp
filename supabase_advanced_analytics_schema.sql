-- ============================================
-- ADVANCED ANALYTICS SYSTEM
-- ============================================

-- Analytics Reports Table
CREATE TABLE IF NOT EXISTS analytics_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
    report_date DATE NOT NULL,
    report_type TEXT DEFAULT 'weekly', -- 'daily', 'weekly', 'monthly'
    insights JSONB DEFAULT '{}'::jsonb, -- AI-generated insights
    recommendations JSONB DEFAULT '[]'::jsonb, -- AI-generated recommendations
    trends JSONB DEFAULT '{}'::jsonb, -- Trend analysis data
    summary TEXT, -- Text summary of the report
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, report_date, report_type)
);

-- Enable RLS
ALTER TABLE analytics_reports ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can manage own analytics reports" 
ON analytics_reports FOR ALL 
USING (auth.uid() = user_id);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_analytics_reports_user_date ON analytics_reports(user_id, report_date DESC);
CREATE INDEX IF NOT EXISTS idx_analytics_reports_user_type ON analytics_reports(user_id, report_type);

-- Trigger for updated_at
CREATE TRIGGER update_analytics_reports_updated_at BEFORE UPDATE ON analytics_reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

