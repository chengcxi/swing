import { Component, ChangeDetectionStrategy, output, inject, signal, viewChild, ElementRef } from '@angular/core';
import { CommonModule } from '@angular/common';
import { PostService } from '../services/post.service';

@Component({
  selector: 'app-create-post',
  templateUrl: './create-post.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class CreatePostComponent {
  close = output<void>();
  private postService = inject(PostService);

  postContent = signal('');
  textarea = viewChild<ElementRef<HTMLTextAreaElement>>('textarea');
  
  onInput(event: Event) {
    this.postContent.set((event.target as HTMLTextAreaElement).value);
  }

  submitPost() {
    if (this.postContent().trim()) {
      this.postService.addPost(this.postContent());
      this.close.emit();
    }
  }

  tagUser() {
    this.postContent.update(content => content + '@');
    this.textarea()?.nativeElement.focus();
  }

  tagCourse() {
    this.postContent.update(content => content + '#');
    this.textarea()?.nativeElement.focus();
  }
}
