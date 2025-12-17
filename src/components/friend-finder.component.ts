import { Component, ChangeDetectionStrategy, output, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../services/user.service';
import { User } from '../models/user.model';

@Component({
  selector: 'app-friend-finder',
  templateUrl: './friend-finder.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class FriendFinderComponent {
  close = output<void>();
  private userService = inject(UserService);

  searchTerm = signal('');
  
  // Use a computed signal that depends on searchTerm
  filteredUsers = this.userService.searchUsers(this.searchTerm);

  onSearch(event: Event) {
    this.searchTerm.set((event.target as HTMLInputElement).value);
  }
}
