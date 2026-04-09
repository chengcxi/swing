import { Injectable, signal, inject, effect } from '@angular/core';
import { Post } from '../models/post.model';
import { AuthService } from './auth.service';
import { supabase } from './supabase';

const MOCK_POSTS: Post[] = [
  {
    id: 1,
    author: 'John Doe',
    authorUsername: 'johndoe',
    authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
    timestamp: '2h ago',
    content: 'Great day at #RivieraCountryClub! The course was in perfect condition. Tough greens but managed to sink a few long putts with @janedoe.',
    image: 'https://picsum.photos/400/300?image=1011',
    likes: 42,
    comments: 7,
    taggedUsers: ['janedoe'],
    taggedCourses: ['RivieraCountryClub'],
  },
  {
    id: 2,
    author: 'Jane Doe',
    authorUsername: 'janedoe',
    authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
    timestamp: '5h ago',
    content: 'Working on my swing at the driving range. Finally getting that smooth tempo!',
    likes: 31,
    comments: 4,
  },
  {
    id: 3,
    author: 'Jack Doe',
    authorUsername: 'jackdoe',
    authorAvatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG',
    timestamp: '1d ago',
    content: "Who's up for a round at #RusticCanyon this weekend? The weather looks amazing. @jasondoe you in?",
    image: 'https://picsum.photos/400/300?image=1012',
    likes: 58,
    comments: 12,
    taggedUsers: ['jasondoe'],
    taggedCourses: ['RusticCanyon'],
  },
];

@Injectable({ providedIn: 'root' })
export class PostService {
  private authService = inject(AuthService);
  private posts = signal<Post[]>(MOCK_POSTS);

  constructor() {
    effect(() => {
      const userId = this.authService.currentUserId();
      if (userId) {
        this.loadFeed();
      }
    });
  }

  private async loadFeed() {
    try {
      const { data, error } = await supabase
        .from('rounds')
        .select('*, course:golf_courses(name, city, state), profile:profiles!user_id(username, full_name, avatar_url)')
        .order('date_played', { ascending: false })
        .limit(20);

      if (!error && data && data.length > 0) {
        const feedPosts: Post[] = data.map((r: any) => {
          const courseName = r.course?.name || 'a course';
          const location = r.course ? `${r.course.city}, ${r.course.state || ''}` : '';
          return {
            id: r.id,
            author: r.profile?.full_name || r.profile?.username || 'Golfer',
            authorUsername: r.profile?.username || 'golfer',
            authorAvatar: r.profile?.avatar_url || 'https://ui-avatars.com/api/?name=G&background=1A4D2E&color=fff',
            timestamp: this.formatTimestamp(r.date_played),
            content: `Shot a ${r.score} at #${courseName.replace(/\s+/g, '')}${location ? ` in ${location}` : ''}! ${r.notes || ''}`.trim(),
            likes: 0,
            comments: 0,
            taggedCourses: [courseName.replace(/\s+/g, '')],
          };
        });
        this.posts.set(feedPosts);

        // Load like/comment counts
        for (const round of data) {
          const [{ count: likeCount }, { count: commentCount }] = await Promise.all([
            supabase.from('likes').select('*', { count: 'exact', head: true }).eq('round_id', round.id),
            supabase.from('comments').select('*', { count: 'exact', head: true }).eq('round_id', round.id),
          ]);
          this.posts.update(posts => posts.map(p =>
            p.id === round.id ? { ...p, likes: likeCount || 0, comments: commentCount || 0 } : p
          ));
        }
      }
      // If no data or error, keep the mock posts that were set as default
    } catch (e) {
      console.error('Failed to load feed', e);
      // Keep mock posts on failure
    }
  }

  private formatTimestamp(dateStr: string): string {
    if (!dateStr) return 'Unknown';
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffMins = Math.floor(diffMs / 60000);
    if (diffMins < 1) return 'just now';
    if (diffMins < 60) return `${diffMins}m ago`;
    const diffHours = Math.floor(diffMins / 60);
    if (diffHours < 24) return `${diffHours}h ago`;
    const diffDays = Math.floor(diffHours / 24);
    if (diffDays < 30) return `${diffDays}d ago`;
    return date.toLocaleDateString();
  }

  getPosts() {
    return this.posts.asReadonly();
  }

  async addPost(content: string) {
    const userId = this.authService.currentUserId();

    const taggedUsers = (content.match(/@(\w+)/g) || []).map(u => u.substring(1));
    const taggedCourses = (content.match(/#(\w+)/g) || []).map(c => c.substring(1));

    let author = 'You';
    let authorUsername = 'user';
    let authorAvatar = 'https://ui-avatars.com/api/?name=U&background=1A4D2E&color=fff';

    if (userId) {
      try {
        const { data: profile } = await supabase
          .from('profiles')
          .select('username, full_name, avatar_url')
          .eq('id', userId)
          .single();
        if (profile) {
          author = profile.full_name || profile.username || 'You';
          authorUsername = profile.username || 'user';
          authorAvatar = profile.avatar_url || authorAvatar;
        }
      } catch {}
    }

    const newPost: Post = {
      id: Date.now(),
      author,
      authorUsername,
      authorAvatar,
      timestamp: 'just now',
      content,
      likes: 0,
      comments: 0,
      taggedUsers,
      taggedCourses,
    };
    this.posts.update(posts => [newPost, ...posts]);
  }
}
