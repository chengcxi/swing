import { Injectable, OnDestroy, signal, inject, effect } from '@angular/core';
import { GolfActivity } from '../models/golf.model';
import { AuthService } from './auth.service';
import { supabase } from './supabase';

@Injectable({ providedIn: 'root' })
export class ActivityService implements OnDestroy {
  private authService = inject(AuthService);
  private activities = signal<GolfActivity[]>([
    { id: 1, user: 'Alice', userAvatar: 'https://ui-avatars.com/api/?name=Alice&background=1A4D2E&color=fff', action: 'played', details: 'a round at', target: 'Pebble Beach', timestamp: '5m ago' },
    { id: 2, user: 'Bob', userAvatar: 'https://ui-avatars.com/api/?name=Bob&background=1A4D2E&color=fff', action: 'posted', details: 'a new photo', timestamp: '12m ago' },
    { id: 3, user: 'Charlie', userAvatar: 'https://ui-avatars.com/api/?name=Charlie&background=1A4D2E&color=fff', action: 'commented on', details: 'your post:', target: '"Great shot on the 7th hole!"', timestamp: '25m ago' },
    { id: 4, user: 'Diana', userAvatar: 'https://ui-avatars.com/api/?name=Diana&background=1A4D2E&color=fff', action: 'joined', details: 'the group', target: 'Weekend Golf Warriors', timestamp: '1h ago' },
    { id: 5, user: 'Alice', userAvatar: 'https://ui-avatars.com/api/?name=Alice&background=1A4D2E&color=fff', action: 'played', details: 'a round at', target: 'Sandpiper Golf Club', timestamp: '2h ago' },
  ]);
  private pollInterval: any;

  constructor() {
    effect(() => {
      const userId = this.authService.currentUserId();
      if (userId) {
        this.loadActivities();
        this.startPolling();
      }
    });
  }

  private async loadActivities() {
    try {
      // Load recent rounds from all users as activity
      const { data: rounds } = await supabase
        .from('rounds')
        .select('*, profile:profiles!user_id(username, full_name, avatar_url), course:golf_courses(name)')
        .order('created_at', { ascending: false })
        .limit(20);

      // Load recent comments
      const { data: comments } = await supabase
        .from('comments')
        .select('*, profile:profiles!user_id(username, full_name, avatar_url)')
        .order('created_at', { ascending: false })
        .limit(10);

      // Load recent follows
      const { data: follows } = await supabase
        .from('follows')
        .select('*, follower:profiles!follower_id(username, full_name, avatar_url), following:profiles!following_id(username, full_name)')
        .order('created_at', { ascending: false })
        .limit(10);

      const allActivities: GolfActivity[] = [];

      if (rounds) {
        for (const r of rounds) {
          allActivities.push({
            id: Date.parse(r.created_at || r.date_played),
            user: r.profile?.full_name || r.profile?.username || 'Someone',
            userAvatar: r.profile?.avatar_url || 'https://ui-avatars.com/api/?name=G&background=1A4D2E&color=fff',
            action: 'played',
            details: 'a round at',
            target: r.course?.name || 'a course',
            timestamp: this.formatTimestamp(r.created_at || r.date_played),
          });
        }
      }

      if (comments) {
        for (const c of comments) {
          allActivities.push({
            id: Date.parse(c.created_at || new Date().toISOString()),
            user: c.profile?.full_name || c.profile?.username || 'Someone',
            userAvatar: c.profile?.avatar_url || 'https://ui-avatars.com/api/?name=G&background=1A4D2E&color=fff',
            action: 'commented on',
            details: 'a round:',
            target: `"${c.content.substring(0, 50)}${c.content.length > 50 ? '...' : ''}"`,
            timestamp: this.formatTimestamp(c.created_at),
          });
        }
      }

      if (follows) {
        for (const f of follows) {
          allActivities.push({
            id: Date.parse(f.created_at || new Date().toISOString()),
            user: f.follower?.full_name || f.follower?.username || 'Someone',
            userAvatar: f.follower?.avatar_url || 'https://ui-avatars.com/api/?name=G&background=1A4D2E&color=fff',
            action: 'joined',
            details: 'started following',
            target: f.following?.full_name || f.following?.username || 'someone',
            timestamp: this.formatTimestamp(f.created_at),
          });
        }
      }

      // Sort by most recent
      allActivities.sort((a, b) => b.id - a.id);
      this.activities.set(allActivities);
    } catch (e) {
      console.error('Failed to load activities', e);
    }
  }

  private startPolling() {
    // Refresh activities every 30 seconds
    if (this.pollInterval) clearInterval(this.pollInterval);
    this.pollInterval = setInterval(() => this.loadActivities(), 30000);
  }

  private formatTimestamp(isoDate: string): string {
    if (!isoDate) return 'just now';
    const date = new Date(isoDate);
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

  getActivities() {
    return this.activities.asReadonly();
  }

  ngOnDestroy() {
    if (this.pollInterval) clearInterval(this.pollInterval);
  }
}
