import { Component, ChangeDetectionStrategy, inject, output, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PostService } from '../services/post.service';
import { UserService } from '../services/user.service';
import { AuthService } from '../services/auth.service';
import { PostComponent } from './post.component';
import { User } from '../models/user.model';
import { supabase } from '../services/supabase';

@Component({
  selector: 'app-post-feed',
  templateUrl: './post-feed.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, PostComponent],
})
export class PostFeedComponent {
  private postService = inject(PostService);
  private userService = inject(UserService);
  private authService = inject(AuthService);

  posts = this.postService.getPosts();
  suggestedUsers = this.userService.getSuggestedUsers();
  addedIds = signal<Set<string>>(new Set());

  profileClicked = output<void>();

  isUserAdded(userId: string) {
    return this.addedIds().has(userId);
  }

  async addFriend(user: User) {
    const currentUserId = this.authService.currentUserId();
    if (!currentUserId) return;

    this.addedIds.update(set => {
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
      this.addedIds.update(set => {
        const next = new Set(set);
        next.delete(user.id);
        return next;
      });
    }
  }
}
