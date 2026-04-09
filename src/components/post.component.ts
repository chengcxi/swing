import { Component, ChangeDetectionStrategy, input, output, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Post } from '../models/post.model';

@Component({
  selector: 'app-post',
  templateUrl: './post.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class PostComponent {
  post = input.required<Post>();
  profileClicked = output<void>();

  liked = signal(false);
  showComments = signal(false);
  shared = signal(false);

  likeCount = computed(() => this.post().likes + (this.liked() ? 1 : 0));

  formattedContent = computed(() => {
    const content = this.post().content;
    const regex = /([@#])(\w+)/g;

    return content.replace(regex, (match, type) => {
      if (type === '@') {
        return `<span class="text-blue-500 font-semibold cursor-pointer hover:underline">${match}</span>`;
      } else {
        return `<span class="text-green-600 font-semibold cursor-pointer hover:underline">${match}</span>`;
      }
    });
  });

  toggleLike() {
    this.liked.update(v => !v);
  }

  toggleComments() {
    this.showComments.update(v => !v);
  }

  sharePost() {
    this.shared.set(true);
    setTimeout(() => this.shared.set(false), 2000);
  }
}
