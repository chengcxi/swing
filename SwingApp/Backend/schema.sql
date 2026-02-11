-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ========================================
-- PROFILES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    handicap DECIMAL(4,1),
    bio TEXT,
    home_course_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$')
);

-- ========================================
-- GOLF COURSES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS golf_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    address TEXT NOT NULL,
    city TEXT NOT NULL,
    state TEXT,
    country TEXT NOT NULL DEFAULT 'USA',
    latitude DECIMAL(10, 8) NOT NULL,
    longitude DECIMAL(11, 8) NOT NULL,
    holes INTEGER DEFAULT 18,
    par INTEGER,
    course_rating DECIMAL(4,1),
    slope INTEGER,
    phone TEXT,
    website TEXT,
    description TEXT,
    image_url TEXT,
    google_place_id TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Add foreign key for home course
ALTER TABLE profiles 
ADD CONSTRAINT fk_home_course 
FOREIGN KEY (home_course_id) REFERENCES golf_courses(id) ON DELETE SET NULL;

-- ========================================
-- ROUNDS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    course_id UUID REFERENCES golf_courses(id) ON DELETE SET NULL,
    score INTEGER NOT NULL,
    date_played DATE NOT NULL DEFAULT CURRENT_DATE,
    notes TEXT,
    weather TEXT,
    photos TEXT[],
    putts INTEGER,
    fairways_hit INTEGER,
    greens_in_regulation INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- FOLLOWS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS follows (
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT no_self_follow CHECK (follower_id != following_id)
);

-- ========================================
-- LIKES TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS likes (
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, round_id)
);

-- ========================================
-- COMMENTS TABLE
-- ========================================
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ========================================
-- INDEXES
-- ========================================
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_golf_courses_location ON golf_courses(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_golf_courses_google_place_id ON golf_courses(google_place_id);
CREATE INDEX IF NOT EXISTS idx_rounds_user_id ON rounds(user_id);
CREATE INDEX IF NOT EXISTS idx_rounds_course_id ON rounds(course_id);
CREATE INDEX IF NOT EXISTS idx_rounds_date_played ON rounds(date_played DESC);
CREATE INDEX IF NOT EXISTS idx_rounds_created_at ON rounds(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_likes_round ON likes(round_id);
CREATE INDEX IF NOT EXISTS idx_comments_round ON comments(round_id);

-- ========================================
-- ROW LEVEL SECURITY
-- ========================================
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE golf_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Profiles are viewable by everyone" ON profiles
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own profile" ON profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE USING (auth.uid() = id);

-- Golf courses policies
CREATE POLICY "Golf courses are viewable by everyone" ON golf_courses
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can create courses" ON golf_courses
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Rounds policies
CREATE POLICY "Rounds are viewable by everyone" ON rounds
    FOR SELECT USING (true);

CREATE POLICY "Users can create their own rounds" ON rounds
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own rounds" ON rounds
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own rounds" ON rounds
    FOR DELETE USING (auth.uid() = user_id);

-- Follows policies
CREATE POLICY "Follows are viewable by everyone" ON follows
    FOR SELECT USING (true);

CREATE POLICY "Users can follow others" ON follows
    FOR INSERT WITH CHECK (auth.uid() = follower_id);

CREATE POLICY "Users can unfollow" ON follows
    FOR DELETE USING (auth.uid() = follower_id);

-- Likes policies
CREATE POLICY "Likes are viewable by everyone" ON likes
    FOR SELECT USING (true);

CREATE POLICY "Users can like rounds" ON likes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike rounds" ON likes
    FOR DELETE USING (auth.uid() = user_id);

-- Comments policies
CREATE POLICY "Comments are viewable by everyone" ON comments
    FOR SELECT USING (true);

CREATE POLICY "Users can create comments" ON comments
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" ON comments
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON comments
    FOR DELETE USING (auth.uid() = user_id);

-- ========================================
-- FUNCTIONS & TRIGGERS
-- ========================================

-- Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_golf_courses_updated_at
    BEFORE UPDATE ON golf_courses
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_rounds_updated_at
    BEFORE UPDATE ON rounds
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_comments_updated_at
    BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ========================================
-- STORAGE BUCKET POLICIES
-- ========================================

-- Bucket: round-photos (Public)
CREATE POLICY "Authenticated users can upload round photos"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'round-photos');

CREATE POLICY "Round photos are public"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'round-photos');

CREATE POLICY "Users can delete round photos"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'round-photos');

-- Bucket: avatars (Public)
CREATE POLICY "Users can upload avatar"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'avatars');

CREATE POLICY "Avatars are public"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'avatars');

CREATE POLICY "Users can manage their avatar"
ON storage.objects FOR UPDATE TO authenticated
USING (bucket_id = 'avatars');

CREATE POLICY "Users can delete their avatar"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'avatars');
