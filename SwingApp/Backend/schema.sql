-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- UNIVERSITIES
-- ================================================
CREATE TABLE IF NOT EXISTS universities (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    short_name TEXT,
    email_domain TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    primary_color TEXT,
    secondary_color TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- PROFILES
-- ================================================
CREATE TABLE IF NOT EXISTS profiles (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    banner_url TEXT,
    bio TEXT,
    handicap DECIMAL(4,1),
    university_id UUID REFERENCES universities(id) ON DELETE SET NULL,
    university_email TEXT,
    is_university_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT username_length CHECK (char_length(username) >= 3 AND char_length(username) <= 30),
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]+$')
);

-- ================================================
-- GOLF COURSES
-- ================================================
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
    yardage INTEGER,
    phone TEXT,
    website TEXT,
    description TEXT,
    image_url TEXT,
    google_place_id TEXT UNIQUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- ROUNDS
-- ================================================
CREATE TABLE IF NOT EXISTS rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    course_id UUID REFERENCES golf_courses(id) ON DELETE SET NULL,
    score INTEGER NOT NULL,
    date_played DATE NOT NULL DEFAULT CURRENT_DATE,
    tee_box TEXT,
    notes TEXT,
    weather TEXT,
    photos TEXT[],
    total_putts INTEGER,
    fairways_hit INTEGER,
    fairways_total INTEGER,
    greens_in_regulation INTEGER,
    greens_total INTEGER,
    penalties INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- HOLE SCORES
-- ================================================
CREATE TABLE IF NOT EXISTS hole_scores (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE NOT NULL,
    hole_number INTEGER NOT NULL,
    par INTEGER NOT NULL,
    score INTEGER NOT NULL,
    putts INTEGER,
    fairway_hit BOOLEAN,
    green_in_regulation BOOLEAN,
    penalties INTEGER DEFAULT 0,
    club_used_off_tee TEXT,
    notes TEXT,
    
    UNIQUE(round_id, hole_number)
);

-- ================================================
-- CLUB DISTANCES
-- ================================================
CREATE TABLE IF NOT EXISTS club_distances (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    club_type TEXT NOT NULL,
    average_distance INTEGER NOT NULL,
    max_distance INTEGER,
    min_distance INTEGER,
    measurement_count INTEGER DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, club_type)
);

-- ================================================
-- FAVORITE COURSES
-- ================================================
CREATE TABLE IF NOT EXISTS favorite_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    course_id UUID REFERENCES golf_courses(id) ON DELETE CASCADE NOT NULL,
    rank INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(user_id, course_id)
);

-- ================================================
-- COURSE PREFERENCES (for swiping)
-- ================================================
CREATE TABLE IF NOT EXISTS course_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    winner_id UUID REFERENCES golf_courses(id) ON DELETE CASCADE NOT NULL,
    loser_id UUID REFERENCES golf_courses(id) ON DELETE CASCADE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- SOCIAL: FOLLOWS
-- ================================================
CREATE TABLE IF NOT EXISTS follows (
    follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (follower_id, following_id),
    CONSTRAINT no_self_follow CHECK (follower_id != following_id)
);

-- ================================================
-- SOCIAL: LIKES
-- ================================================
CREATE TABLE IF NOT EXISTS likes (
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, round_id)
);

-- ================================================
-- SOCIAL: COMMENTS
-- ================================================
CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
    round_id UUID REFERENCES rounds(id) ON DELETE CASCADE NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ================================================
-- INDEXES
-- ================================================
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username);
CREATE INDEX IF NOT EXISTS idx_profiles_university ON profiles(university_id);
CREATE INDEX IF NOT EXISTS idx_profiles_handicap ON profiles(handicap);
CREATE INDEX IF NOT EXISTS idx_golf_courses_location ON golf_courses(latitude, longitude);
CREATE INDEX IF NOT EXISTS idx_golf_courses_google_place_id ON golf_courses(google_place_id);
CREATE INDEX IF NOT EXISTS idx_rounds_user_id ON rounds(user_id);
CREATE INDEX IF NOT EXISTS idx_rounds_course_id ON rounds(course_id);
CREATE INDEX IF NOT EXISTS idx_rounds_date_played ON rounds(date_played DESC);
CREATE INDEX IF NOT EXISTS idx_rounds_created_at ON rounds(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_hole_scores_round ON hole_scores(round_id);
CREATE INDEX IF NOT EXISTS idx_follows_follower ON follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_follows_following ON follows(following_id);
CREATE INDEX IF NOT EXISTS idx_likes_round ON likes(round_id);
CREATE INDEX IF NOT EXISTS idx_comments_round ON comments(round_id);
CREATE INDEX IF NOT EXISTS idx_favorite_courses_user ON favorite_courses(user_id);
CREATE INDEX IF NOT EXISTS idx_course_preferences_user ON course_preferences(user_id);

-- ================================================
-- ROW LEVEL SECURITY
-- ================================================
ALTER TABLE universities ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE golf_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE hole_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE club_distances ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorite_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

-- Universities: Public read
CREATE POLICY "Universities are public" ON universities FOR SELECT USING (true);

-- Profiles
CREATE POLICY "Profiles are public" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

-- Golf courses
CREATE POLICY "Courses are public" ON golf_courses FOR SELECT USING (true);
CREATE POLICY "Auth users can create courses" ON golf_courses FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- Rounds
CREATE POLICY "Rounds are public" ON rounds FOR SELECT USING (true);
CREATE POLICY "Users can create own rounds" ON rounds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own rounds" ON rounds FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own rounds" ON rounds FOR DELETE USING (auth.uid() = user_id);

-- Hole scores
CREATE POLICY "Hole scores are public" ON hole_scores FOR SELECT USING (true);
CREATE POLICY "Users can manage own hole scores" ON hole_scores FOR ALL 
    USING (EXISTS (SELECT 1 FROM rounds WHERE rounds.id = hole_scores.round_id AND rounds.user_id = auth.uid()));

-- Club distances
CREATE POLICY "Club distances viewable by owner" ON club_distances FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own club distances" ON club_distances FOR ALL USING (auth.uid() = user_id);

-- Favorite courses
CREATE POLICY "Favorites are public" ON favorite_courses FOR SELECT USING (true);
CREATE POLICY "Users can manage own favorites" ON favorite_courses FOR ALL USING (auth.uid() = user_id);

-- Course preferences
CREATE POLICY "Preferences viewable by owner" ON course_preferences FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can manage own preferences" ON course_preferences FOR ALL USING (auth.uid() = user_id);

-- Follows
CREATE POLICY "Follows are public" ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow" ON follows FOR INSERT WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow" ON follows FOR DELETE USING (auth.uid() = follower_id);

-- Likes
CREATE POLICY "Likes are public" ON likes FOR SELECT USING (true);
CREATE POLICY "Users can like" ON likes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike" ON likes FOR DELETE USING (auth.uid() = user_id);

-- Comments
CREATE POLICY "Comments are public" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can comment" ON comments FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own comments" ON comments FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own comments" ON comments FOR DELETE USING (auth.uid() = user_id);

-- ================================================
-- TRIGGERS
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_golf_courses_updated_at BEFORE UPDATE ON golf_courses FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_rounds_updated_at BEFORE UPDATE ON rounds FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_club_distances_updated_at BEFORE UPDATE ON club_distances FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ================================================
-- SEED UNIVERSITIES
-- ================================================
INSERT INTO universities (name, short_name, email_domain, primary_color) VALUES
-- UCs
('UC Berkeley', 'Cal', 'berkeley.edu', '#003262'),
('UCLA', 'UCLA', 'ucla.edu', '#2774AE'),
('UC San Diego', 'UCSD', 'ucsd.edu', '#182B49'),
('UC Santa Barbara', 'UCSB', 'ucsb.edu', '#003660'),
('UC Irvine', 'UCI', 'uci.edu', '#0064A4'),
('UC Davis', 'UC Davis', 'ucdavis.edu', '#022851'),
('UC Santa Cruz', 'UCSC', 'ucsc.edu', '#003C6C'),
('UC Riverside', 'UCR', 'ucr.edu', '#2D6CC0'),
('UC Merced', 'UC Merced', 'ucmerced.edu', '#002855'),
('UC San Francisco', 'UCSF', 'ucsf.edu', '#052049'),

-- CSUs
('San Jose State', 'SJSU', 'sjsu.edu', '#0055A2'),
('San Diego State', 'SDSU', 'sdsu.edu', '#A6192E'),
('San Francisco State', 'SFSU', 'sfsu.edu', '#231161'),
('Cal State Long Beach', 'CSULB', 'csulb.edu', '#ffe100ff'),
('Cal State Fullerton', 'CSUF', 'fullerton.edu', '#00274C'),
('Cal State Northridge', 'CSUN', 'csun.edu', '#D22030'),
('Cal Poly SLO', 'Cal Poly', 'calpoly.edu', '#154734'),
('Cal Poly Pomona', 'CPP', 'cpp.edu', '#1E4D2B'),
('Sacramento State', 'Sac State', 'csus.edu', '#004E38'),
('Fresno State', 'Fresno State', 'fresnostate.edu', '#DB0032'),
('Cal State East Bay', 'CSUEB', 'csueastbay.edu', '#D81A21'),
('Chico State', 'Chico', 'csuchico.edu', '#9D2235'),

-- Private CA
('Stanford University', 'Stanford', 'stanford.edu', '#8C1515'),
('USC', 'USC', 'usc.edu', '#990000'),
('Caltech', 'Caltech', 'caltech.edu', '#FF6C0C'),
('Santa Clara University', 'Santa Clara', 'scu.edu', '#862633'),
('University of San Francisco', 'USF', 'usfca.edu', '#00543C'),
('University of San Diego', 'USD', 'sandiego.edu', '#002865'),
('Pepperdine University', 'Pepperdine', 'pepperdine.edu', '#00205B'),
('Loyola Marymount University', 'LMU', 'lmu.edu', '#00447C'),
('Chapman University', 'Chapman', 'chapman.edu', '#A50034'),
('Claremont Colleges', 'Claremont', 'claremont.edu', '#9D2235'),
('Pomona College', 'Pomona', 'pomona.edu', '#20438f'),
('Claremont McKenna College', 'CMC', 'cmc.edu', '#9D2235'),
('Harvey Mudd College', 'HMC', 'hmc.edu', '#333333'),
('Pitzer College', 'Pitzer', 'pitzer.edu', '#F7941D'),
('Scripps College', 'Scripps', 'scrippscollege.edu', '#2E4D41'),
('Occidental College', 'Oxy', 'oxy.edu', '#F26522'),
('Saint Mary''s College', 'SMC', 'stmarys-ca.edu', '#003366'),
('University of the Pacific', 'Pacific', 'pacific.edu', '#F47920'),

-- National
('Harvard University', 'Harvard', 'harvard.edu', '#A51C30'),
('Yale University', 'Yale', 'yale.edu', '#00356B'),
('Princeton University', 'Princeton', 'princeton.edu', '#FF6F00'),
('MIT', 'MIT', 'mit.edu', '#750014'),
('Duke University', 'Duke', 'duke.edu', '#003087'),
('UNC Chapel Hill', 'UNC', 'unc.edu', '#4B9CD3'),
('Columbia University', 'Columbia', 'columbia.edu', '#B9D9EB'),
('Cornell University', 'Cornell', 'cornell.edu', '#B31B1B'),
('UPenn', 'UPenn', 'upenn.edu', '#990000'),
('Brown University', 'Brown', 'brown.edu', '#4E3629'),
('Dartmouth College', 'Dartmouth', 'dartmouth.edu', '#00693E')

ON CONFLICT (email_domain) DO NOTHING;