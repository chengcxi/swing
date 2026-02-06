-- Enable UUID extension
create extension if not exists "uuid-ossp";

-- PROFILES (Users)
create table profiles (
  id uuid references auth.users not null primary key,
  username text unique,
  full_name text,
  avatar_url text,
  website text,
  university text,
  handicap numeric,
  average_score numeric,
  best_round integer,
  rounds_played integer default 0,
  badges text[], -- Array of strings for badges
  is_verified boolean default false,
  updated_at timestamp with time zone,
  
  constraint username_length check (char_length(username) >= 3)
);

alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- TRIGGER for New User -> Profile
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url)
  values (new.id, new.raw_user_meta_data->>'username', new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'avatar_url');
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- COURSES
create table courses (
  id uuid default uuid_generate_v4() primary key,
  name text not null,
  location text,
  holes integer default 18,
  difficulty numeric,
  has_driving_range boolean default false,
  has_putting_green boolean default false,
  latitude double precision,
  longitude double precision,
  google_place_id text unique,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table courses enable row level security;

create policy "Courses are viewable by everyone."
  on courses for select
  using ( true );

-- ROUNDS
create table rounds (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) not null,
  course_id uuid references courses(id),
  course_name text, -- De-normalized in case course is deleted or custom
  location text,
  score integer not null,
  holes integer default 18,
  date timestamp with time zone not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table rounds enable row level security;

create policy "Rounds are viewable by everyone."
  on rounds for select
  using ( true );

create policy "Users can insert their own rounds."
  on rounds for insert
  with check ( auth.uid() = user_id );

-- POSTS
create table posts (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references profiles(id) not null,
  round_id uuid references rounds(id),
  caption text,
  image_url text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table posts enable row level security;

create policy "Posts are viewable by everyone."
  on posts for select
  using ( true );

create policy "Users can insert their own posts."
  on posts for insert
  with check ( auth.uid() = user_id );

-- COMMENTS
create table comments (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references posts(id) not null,
  user_id uuid references profiles(id) not null,
  text text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table comments enable row level security;

create policy "Comments are viewable by everyone."
  on comments for select
  using ( true );

create policy "Users can insert their own comments."
  on comments for insert
  with check ( auth.uid() = user_id );

-- LIKES
create table likes (
  id uuid default uuid_generate_v4() primary key,
  post_id uuid references posts(id) not null,
  user_id uuid references profiles(id) not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(post_id, user_id)
);

alter table likes enable row level security;

create policy "Likes are viewable by everyone."
  on likes for select
  using ( true );

create policy "Users can insert their own likes."
  on likes for insert
  with check ( auth.uid() = user_id );

create policy "Users can delete their own likes."
  on likes for delete
  using ( auth.uid() = user_id );

-- FRIENDSHIPS
create table friendships (
  id uuid default uuid_generate_v4() primary key,
  follower_id uuid references profiles(id) not null,
  following_id uuid references profiles(id) not null,
  status text check (status in ('pending', 'accepted')) default 'pending',
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(follower_id, following_id)
);

alter table friendships enable row level security;

create policy "Friendships are viewable by everyone."
  on friendships for select
  using ( true );

create policy "Users can insert their own friendships."
  on friendships for insert
  with check ( auth.uid() = follower_id );

create policy "Users can update their own friendships."
  on friendships for update
  using ( auth.uid() = following_id ); -- e.g. accepting a request

-- STORAGE BUCKETS (Script to be run in SQL Editor or Storage UI)
-- insert into storage.buckets (id, name, public) values ('avatars', 'avatars', true);
-- insert into storage.buckets (id, name, public) values ('post_images', 'post_images', true);
-- create policy "Avatar images are publicly accessible." on storage.objects for select using ( bucket_id = 'avatars' );
-- create policy "Anyone can upload an avatar." on storage.objects for insert with check ( bucket_id = 'avatars' ); 

-- FUNCTIONS & TRIGGERS

-- 1. Update Profile Stats on New Round
create or replace function public.update_profile_stats()
returns trigger as $$
declare
  _user_id uuid;
  _new_avg numeric;
  _best_round integer;
  _rounds_count integer;
  _handicap numeric;
begin
  _user_id := new.user_id;

  -- Calculate Stats
  select 
    count(*), 
    avg(score), 
    min(score)
  into 
    _rounds_count, 
    _new_avg, 
    _best_round
  from rounds
  where user_id = _user_id;
  
  -- Simple Handicap Calculation (Average - 72) * 0.96 roughly, just for demo
  -- Limit to min 0
  _handicap := greatest(0, (_new_avg - 72) * 0.96);

  update profiles
  set 
    rounds_played = _rounds_count,
    average_score = round(_new_avg, 1),
    best_round = _best_round,
    handicap = round(_handicap, 1),
    updated_at = now()
  where id = _user_id;

  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_round_created
  after insert on rounds
  for each row execute procedure public.update_profile_stats();

-- 2. University Verification (Simple Domain Check)
create or replace function public.get_university_from_email(email text)
returns text as $$
declare
  domain text;
begin
  domain := split_part(email, '@', 2);
  if domain like '%.edu' then
    -- Very basic mapping. In production, use a lookup table.
    return initcap(split_part(domain, '.', 1)); 
  else
    return null;
  end if;
end;
$$ language plpgsql;

-- Update handle_new_user to use university check
create or replace function public.handle_new_user() 
returns trigger as $$
begin
  insert into public.profiles (id, username, full_name, avatar_url, university, is_verified)
  values (
    new.id, 
    new.raw_user_meta_data->>'username', 
    new.raw_user_meta_data->>'full_name', 
    new.raw_user_meta_data->>'avatar_url',
    public.get_university_from_email(new.email),
    case when new.email like '%.edu' then true else false end
  );
  return new;
end;
$$ language plpgsql security definer;
