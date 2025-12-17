import { Component, ChangeDetectionStrategy, input, output, computed } from '@angular/core';
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

  formattedContent = computed(() => {
    const content = this.post().content;
    // Regex to find @mentions and #hashtags
    const regex = /([@#])(\w+)/g;
    
    return content.replace(regex, (match, type) => {
      if (type === '@') {
        return `<span class="text-blue-500 font-semibold cursor-pointer hover:underline">${match}</span>`;
      } else { // type === '#'
        return `<span class="text-green-600 font-semibold cursor-pointer hover:underline">${match}</span>`;
      }
    });
  });
}
