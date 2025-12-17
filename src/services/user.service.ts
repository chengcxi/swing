import { Injectable, computed, signal, Signal } from '@angular/core';
import { User } from '../models/user.model';

@Injectable({ providedIn: 'root' })
export class UserService {
  private allUsers = signal<User[]>([
    { id: '1', name: 'Jack Burke', username: 'jack', avatar: 'https://i.pravatar.cc/40?u=jackburke', isVerified: true, isPro: true },
    { id: '2', name: 'Jaxon Smith', username: 'jaxonsmith', avatar: 'https://i.pravatar.cc/40?u=jaxonsmith', isVerified: true, isPro: true },
    { id: '3', name: 'Jane Doe', username: 'janedoe', avatar: 'https://i.pravatar.cc/40?u=janedoe', isVerified: false, isPro: false },
    { id: '4', name: 'John Appleseed', username: 'johnnyA', avatar: 'https://i.pravatar.cc/40?u=johnappleseed', isVerified: true, isPro: false },
    { id: '5', name: 'Jake Shockley', username: 'jake', avatar: 'https://i.pravatar.cc/150?u=jake', isVerified: true, isPro: true, description: 'Just a guy who loves golf. Trying to break 80 consistently.', favoriteCourse: 'Pebble Beach' },
    { id: '6', name: 'Jackson Hole', username: 'jhole', avatar: 'https://i.pravatar.cc/40?u=jacksonhole', isVerified: false, isPro: true },
  ]);

  getCurrentUser() {
    // For now, hardcode the current user. In a real app, this would be based on auth state.
    return computed(() => this.allUsers().find(u => u.username === 'jake')!);
  }

  getSuggestedUsers() {
    return computed(() => this.allUsers().slice(0, 2));
  }

  // FIX: Accept a signal for the search term to make this method reactive.
  searchUsers(term: Signal<string>) {
    return computed(() => {
      const searchTerm = term();
      if (!searchTerm.trim()) {
        return this.getSuggestedUsers()();
      }
      const lowerTerm = searchTerm.toLowerCase();
      return this.allUsers().filter(user => 
        user.name.toLowerCase().includes(lowerTerm) || 
        user.username.toLowerCase().includes(lowerTerm)
      );
    });
  }
}
