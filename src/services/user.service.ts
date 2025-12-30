import { Injectable, computed, signal, Signal } from '@angular/core';
import { User } from '../models/user.model';

@Injectable({ providedIn: 'root' })
export class UserService {
  private allUsers = signal<User[]>([
    { id: '1', name: 'John Doe', username: 'johndoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true },
    { id: '2', name: 'Jane Doe', username: 'janedoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true },
    { id: '3', name: 'Jack Doe', username: 'jackdoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: false, isPro: false },
    { id: '4', name: 'Jason Doe', username: 'jasondoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: false },
    { id: '5', name: 'Jacky Doe', username: 'jackydoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, description: 'Golf is fun!', favoriteCourse: 'Pebble Beach' },
    { id: '6', name: 'Jayden Doe', username: 'jaydendoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: false, isPro: true },
  ]);

  getCurrentUser() {
    // For now, hardcode the current user. In a real app, this would be based on auth state.
    return computed(() => this.allUsers().find(u => u.username === 'johndoe')!);
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
