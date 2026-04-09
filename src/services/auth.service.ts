import { Injectable, signal } from '@angular/core';
import { supabase } from './supabase';

@Injectable({ providedIn: 'root' })
export class AuthService {
  isAuthenticated = signal<boolean>(false);
  currentUserId = signal<string | null>(null);
  authError = signal<string | null>(null);

  constructor() {
    this.initSession();
  }

  private async initSession() {
    try {
      const { data: { session } } = await supabase.auth.getSession();
      if (session?.user) {
        this.isAuthenticated.set(true);
        this.currentUserId.set(session.user.id);
      }

      // Listen for auth state changes
      supabase.auth.onAuthStateChange((_event, session) => {
        if (session?.user) {
          this.isAuthenticated.set(true);
          this.currentUserId.set(session.user.id);
        } else {
          this.isAuthenticated.set(false);
          this.currentUserId.set(null);
        }
      });
    } catch (e) {
      console.error('Failed to init session', e);
    }
  }

  async login(email: string, password: string, _rememberMe: boolean): Promise<boolean> {
    this.authError.set(null);
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });
      if (error) {
        this.authError.set(error.message);
        return false;
      }
      if (data.user) {
        this.isAuthenticated.set(true);
        this.currentUserId.set(data.user.id);
        return true;
      }
      return false;
    } catch (e) {
      this.authError.set('An unexpected error occurred.');
      return false;
    }
  }

  async signup(email: string, username: string, password: string): Promise<boolean> {
    this.authError.set(null);
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: { username },
        },
      });
      if (error) {
        this.authError.set(error.message);
        return false;
      }
      if (data.user) {
        // Create profile row for the new user
        await supabase.from('profiles').upsert({
          id: data.user.id,
          username,
          full_name: username,
        });
        this.isAuthenticated.set(true);
        this.currentUserId.set(data.user.id);
        return true;
      }
      return false;
    } catch (e) {
      this.authError.set('An unexpected error occurred.');
      return false;
    }
  }

  async logout() {
    await supabase.auth.signOut();
    this.isAuthenticated.set(false);
    this.currentUserId.set(null);
  }
}
