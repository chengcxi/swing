import { Component, ChangeDetectionStrategy, inject, output } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PostService } from '../services/post.service';
import { PostComponent } from './post.component';

@Component({
  selector: 'app-post-feed',
  templateUrl: './post-feed.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, PostComponent],
})
export class PostFeedComponent {
  private postService = inject(PostService);
  posts = this.postService.getPosts();

  profileClicked = output<void>();
}
