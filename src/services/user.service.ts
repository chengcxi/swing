import { Injectable, computed, signal, Signal, inject, effect } from '@angular/core';
import { User } from '../models/user.model';
import { AuthService } from './auth.service';
import { supabase } from './supabase';

const MOCK_USERS: User[] = [
  { id: '1', name: 'John Doe', username: 'johndoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, handicap: 10.2 },
  { id: '2', name: 'Jane Doe', username: 'janedoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, handicap: 5.4, university: 'Golf State University' },
  { id: '3', name: 'Jack Doe', username: 'jackdoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: false, isPro: false, handicap: 18.0, university: 'Golf State University' },
  { id: '4', name: 'Jason Doe', username: 'jasondoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: false, handicap: 12.5 },
  { id: '5', name: 'Jacky Doe', username: 'jackydoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, description: 'Golf is fun!', favoriteCourse: 'Pebble Beach', handicap: 2.1, university: 'Golf State University' },
  { id: '6', name: 'Jayden Doe', username: 'jaydendoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: false, isPro: true, handicap: 0.5, university: 'Golf State University' },
  { id: 'u1', name: 'Tiger Woodz', username: 'tigerw', avatar: 'https://ui-avatars.com/api/?name=Tiger+Woodz&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: -2.0, university: 'Golf State University' },
  { id: 'u2', name: 'Rory Mac', username: 'rorym', avatar: 'https://ui-avatars.com/api/?name=Rory+Mac&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: -1.5, university: 'Golf State University' },
  { id: 'u3', name: 'Phil Mick', username: 'philm', avatar: 'https://ui-avatars.com/api/?name=Phil+Mick&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 0.2, university: 'Golf State University' },
  { id: 'u4', name: 'Jordan S', username: 'jordans', avatar: 'https://ui-avatars.com/api/?name=Jordan+S&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 1.1, university: 'Golf State University' },
  { id: 'u5', name: 'Rickie F', username: 'rickief', avatar: 'https://ui-avatars.com/api/?name=Rickie+F&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 2.8, university: 'Golf State University' },
  { id: 'u6', name: 'Justin T', username: 'justint', avatar: 'https://ui-avatars.com/api/?name=Justin+T&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 3.5, university: 'Golf State University' },
  { id: 'u7', name: 'Dustin J', username: 'dustinj', avatar: 'https://ui-avatars.com/api/?name=Dustin+J&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 4.0, university: 'Golf State University' },
];

@Injectable({ providedIn: 'root' })
export class UserService {
  private authService = inject(AuthService);
  private allUsers = signal<User[]>(MOCK_USERS);
  private currentUserProfile = signal<User | null>(null);
  private loaded = signal(false);

  constructor() {
    // When auth state changes, load user data
    effect(() => {
      const userId = this.authService.currentUserId();
      if (userId) {
        this.loadCurrentUser(userId);
        this.loadAllProfiles();
      }
    });
  }

  private async loadCurrentUser(userId: string) {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (!error && data) {
        this.currentUserProfile.set(this.mapProfile(data));
      }
    } catch (e) {
      console.error('Failed to load current user', e);
    }
  }

  private async loadAllProfiles() {
    try {
      const { data, error } = await supabase
        .from('profiles')
        .select('*, universities(name)');

      if (!error && data) {
        this.allUsers.set(data.map((p: any) => this.mapProfile(p)));
        this.loaded.set(true);
      }
    } catch (e) {
      console.error('Failed to load profiles', e);
    }
  }

  private mapProfile(p: any): User {
    return {
      id: p.id,
      name: p.full_name || p.username || 'Unknown',
      username: p.username || 'user',
      avatar: p.avatar_url || `https://ui-avatars.com/api/?name=${encodeURIComponent(p.full_name || p.username || 'U')}&background=1A4D2E&color=fff`,
      isVerified: p.is_university_verified || false,
      isPro: false,
      description: p.bio,
      handicap: p.handicap,
      university: p.universities?.name,
      eduEmail: p.university_email,
    };
  }

  getCurrentUser() {
    return computed(() => {
      const profile = this.currentUserProfile();
      if (profile) return profile;
      // Fallback to first mock user
      return MOCK_USERS[0];
    });
  }

  getSuggestedUsers() {
    return computed(() => {
      const currentId = this.authService.currentUserId();
      return this.allUsers()
        .filter(u => u.id !== currentId)
        .slice(0, 5);
    });
  }

  searchUsers(term: Signal<string>) {
    return computed(() => {
      const searchTerm = term();
      if (!searchTerm.trim()) {
        return this.getSuggestedUsers()();
      }
      const lowerTerm = searchTerm.toLowerCase();
      const currentId = this.authService.currentUserId();
      return this.allUsers()
        .filter(u => u.id !== currentId)
        .filter(user =>
          user.name.toLowerCase().includes(lowerTerm) ||
          user.username.toLowerCase().includes(lowerTerm)
        );
    });
  }

  async connectToUniversity(email: string): Promise<boolean> {
    if (!email.endsWith('.edu')) {
      return false;
    }

    const userId = this.authService.currentUserId();
    if (!userId) return false;

    try {
      // Find university by email domain
      const domain = email.split('@')[1];
      const { data: uni } = await supabase
        .from('universities')
        .select('id, name')
        .eq('email_domain', domain)
        .single();

      if (!uni) return false;

      // Update profile with university info
      const { error } = await supabase
        .from('profiles')
        .update({
          university_id: uni.id,
          university_email: email,
          is_university_verified: true,
        })
        .eq('id', userId);

      if (error) return false;

      // Refresh current user
      this.currentUserProfile.update(user => user ? {
        ...user,
        university: uni.name,
        eduEmail: email,
      } : user);

      return true;
    } catch (e) {
      console.error('Failed to connect university', e);
      return false;
    }
  }

  getUniversityLeaderboard() {
    return computed(() => {
      const currentUser = this.currentUserProfile();
      if (!currentUser?.university) return [];

      return this.allUsers()
        .filter(u => u.university === currentUser.university && u.handicap !== undefined)
        .sort((a, b) => (a.handicap || 0) - (b.handicap || 0))
        .slice(0, 10);
    });
  }

  getUserRank() {
    return computed(() => {
      const currentUser = this.currentUserProfile();
      if (!currentUser?.university || currentUser.handicap === undefined) return null;

      const universityGolfers = this.allUsers()
        .filter(u => u.university === currentUser.university && u.handicap !== undefined)
        .sort((a, b) => (a.handicap || 0) - (b.handicap || 0));

      const rank = universityGolfers.findIndex(u => u.id === currentUser.id) + 1;
      return { rank, total: universityGolfers.length };
    });
  }

  getUniversityPeers() {
    return computed(() => {
      const currentUser = this.currentUserProfile();
      if (!currentUser?.university) return [];

      return this.allUsers()
        .filter(u => u.university === currentUser.university && u.id !== currentUser.id)
        .sort((a, b) => a.name.localeCompare(b.name));
    });
  }
}
