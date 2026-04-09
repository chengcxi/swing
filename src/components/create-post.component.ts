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
  imageAttached = signal(false);
  videoAttached = signal(false);
  textarea = viewChild<ElementRef<HTMLTextAreaElement>>('textarea');
  fileInput = viewChild<ElementRef<HTMLInputElement>>('fileInput');
  videoInput = viewChild<ElementRef<HTMLInputElement>>('videoInput');
  
  onInput(event: Event) {
    this.postContent.set((event.target as HTMLTextAreaElement).value);
  }

  submitPost() {
    if (this.postContent().trim()) {
      this.postService.addPost(this.postContent());
      this.close.emit();
    }
  }

  attachImage() {
    this.fileInput()?.nativeElement.click();
  }

  onImageSelected(event: Event) {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      this.imageAttached.set(true);
    }
  }

  attachVideo() {
    this.videoInput()?.nativeElement.click();
  }

  onVideoSelected(event: Event) {
    const file = (event.target as HTMLInputElement).files?.[0];
    if (file) {
      this.videoAttached.set(true);
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
