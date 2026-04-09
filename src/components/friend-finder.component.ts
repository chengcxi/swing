import { Component, ChangeDetectionStrategy, output, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../services/user.service';
import { AuthService } from '../services/auth.service';
import { User } from '../models/user.model';
import { supabase } from '../services/supabase';

@Component({
  selector: 'app-friend-finder',
  templateUrl: './friend-finder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class FriendFinderComponent {
  close = output<void>();
  private userService = inject(UserService);
  private authService = inject(AuthService);

  searchTerm = signal('');
  addedUsers = signal<Set<string>>(new Set());

  filteredUsers = this.userService.searchUsers(this.searchTerm);

  onSearch(event: Event) {
    this.searchTerm.set((event.target as HTMLInputElement).value);
  }

  async addFriend(user: User) {
    const currentUserId = this.authService.currentUserId();
    if (!currentUserId) return;

    // Optimistic UI update
    this.addedUsers.update(set => {
      const next = new Set(set);
      next.add(user.id);
      return next;
    });

    try {
      await supabase.from('follows').insert({
        follower_id: currentUserId,
        following_id: user.id,
      });
    } catch (e) {
      // Revert on failure
      this.addedUsers.update(set => {
        const next = new Set(set);
        next.delete(user.id);
        return next;
      });
    }
  }

  isAdded(userId: string): boolean {
    return this.addedUsers().has(userId);
  }
}
