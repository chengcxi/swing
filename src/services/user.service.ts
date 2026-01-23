import { Injectable, computed, signal, Signal } from '@angular/core';
import { User } from '../models/user.model';

@Injectable({ providedIn: 'root' })
export class UserService {
  private allUsers = signal<User[]>([
    { id: '1', name: 'John Doe', username: 'johndoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, handicap: 10.2 },
    { id: '2', name: 'Jane Doe', username: 'janedoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, handicap: 5.4, university: 'Golf State University' },
    { id: '3', name: 'Jack Doe', username: 'jackdoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: false, isPro: false, handicap: 18.0, university: 'Golf State University' },
    { id: '4', name: 'Jason Doe', username: 'jasondoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: false, handicap: 12.5 },
    { id: '5', name: 'Jacky Doe', username: 'jackydoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: true, isPro: true, description: 'Golf is fun!', favoriteCourse: 'Pebble Beach', handicap: 2.1, university: 'Golf State University' },
    { id: '6', name: 'Jayden Doe', username: 'jaydendoe', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG', isVerified: false, isPro: true, handicap: 0.5, university: 'Golf State University' },
    // Mock university students for leaderboard
    { id: 'u1', name: 'Tiger Woodz', username: 'tigerw', avatar: 'https://ui-avatars.com/api/?name=Tiger+Woodz&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: -2.0, university: 'Golf State University' },
    { id: 'u2', name: 'Rory Mac', username: 'rorym', avatar: 'https://ui-avatars.com/api/?name=Rory+Mac&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: -1.5, university: 'Golf State University' },
    { id: 'u3', name: 'Phil Mick', username: 'philm', avatar: 'https://ui-avatars.com/api/?name=Phil+Mick&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 0.2, university: 'Golf State University' },
    { id: 'u4', name: 'Jordan S', username: 'jordans', avatar: 'https://ui-avatars.com/api/?name=Jordan+S&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 1.1, university: 'Golf State University' },
    { id: 'u5', name: 'Rickie F', username: 'rickief', avatar: 'https://ui-avatars.com/api/?name=Rickie+F&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 2.8, university: 'Golf State University' },
    { id: 'u6', name: 'Justin T', username: 'justint', avatar: 'https://ui-avatars.com/api/?name=Justin+T&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 3.5, university: 'Golf State University' },
    { id: 'u7', name: 'Dustin J', username: 'dustinj', avatar: 'https://ui-avatars.com/api/?name=Dustin+J&background=1A4D2E&color=fff', isVerified: false, isPro: false, handicap: 4.0, university: 'Golf State University' },
  ]);

  getCurrentUser() {
    return computed(() => this.allUsers().find(u => u.username === 'johndoe')!);
  }

  getSuggestedUsers() {
    return computed(() => this.allUsers().slice(0, 2));
  }

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

  connectToUniversity(email: string): boolean {
    if (!email.endsWith('.edu')) {
      return false;
    }
    
    // Simulate updating the user
    this.allUsers.update(users => users.map(u => {
      if (u.username === 'johndoe') {
        return { ...u, university: 'Golf State University', eduEmail: email };
      }
      return u;
    }));
    return true;
  }

  getUniversityLeaderboard() {
    return computed(() => {
      const currentUser = this.getCurrentUser()();
      if (!currentUser.university) return [];

      return this.allUsers()
        .filter(u => u.university === currentUser.university && u.handicap !== undefined)
        .sort((a, b) => (a.handicap || 0) - (b.handicap || 0))
        .slice(0, 10);
    });
  }

  getUserRank() {
    return computed(() => {
      const currentUser = this.getCurrentUser()();
      if (!currentUser.university || currentUser.handicap === undefined) return null;

      const universityGolfers = this.allUsers()
        .filter(u => u.university === currentUser.university && u.handicap !== undefined)
        .sort((a, b) => (a.handicap || 0) - (b.handicap || 0));

      const rank = universityGolfers.findIndex(u => u.id === currentUser.id) + 1;
      return { rank, total: universityGolfers.length };
    });
  }
  
  getUniversityPeers() {
    return computed(() => {
      const currentUser = this.getCurrentUser()();
      if (!currentUser.university) return [];
      
      // Return everyone in university except current user and top 3 (who are likely on leaderboard view already)
      return this.allUsers()
        .filter(u => u.university === currentUser.university && u.id !== currentUser.id)
        .sort((a, b) => (a.name.localeCompare(b.name)));
    });
  }
}
