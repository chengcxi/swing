import { Component, ChangeDetectionStrategy, input, output, inject, computed, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GolfCourse } from '../models/golf.model';
import { GolfService } from '../services/golf.service';

@Component({
  selector: 'app-course-details',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
  template: `
    <div class="p-4">
      <button (click)="close.emit()" class="flex items-center text-[#1A4D2E] font-semibold mb-4">
        <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7" />
        </svg>
        Back
      </button>

      <img [src]="course().imageUrl" [alt]="course().name" class="w-full h-40 object-cover rounded-xl mb-4">

      <h2 class="text-xl font-bold text-gray-800">{{ course().name }}</h2>
      <p class="text-sm text-gray-500 mb-3">{{ course().location }}</p>

      <div class="grid grid-cols-3 gap-3 mb-4">
        <div class="bg-white rounded-xl p-3 text-center shadow-sm">
          <p class="text-lg font-bold text-[#1A4D2E]">{{ course().holes }}</p>
          <p class="text-xs text-gray-500">Holes</p>
        </div>
        <div class="bg-white rounded-xl p-3 text-center shadow-sm">
          <p class="text-lg font-bold text-[#1A4D2E]">{{ course().difficulty.toFixed(1) }}</p>
          <p class="text-xs text-gray-500">Difficulty</p>
        </div>
        <div class="bg-white rounded-xl p-3 text-center shadow-sm">
          <p class="text-lg font-bold text-[#1A4D2E]">{{ course().rating.toFixed(1) }}</p>
          <p class="text-xs text-gray-500">Rating</p>
        </div>
      </div>

      <div class="flex gap-2 mb-4">
        @if (course().facilities.drivingRange) {
          <span class="text-xs bg-green-100 text-green-700 px-2 py-1 rounded-full">Driving Range</span>
        }
        @if (course().facilities.puttingGreen) {
          <span class="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full">Putting Green</span>
        }
      </div>

      <h3 class="text-lg font-semibold text-gray-800 mb-3">Reviews</h3>
      @if (reviews().length === 0) {
        <p class="text-sm text-gray-400 text-center py-4">No reviews yet.</p>
      } @else {
        @for (review of reviews(); track review.id) {
          <div class="bg-white rounded-xl p-3 mb-2 shadow-sm">
            <div class="flex items-center mb-2">
              <img [src]="review.authorAvatar" [alt]="review.author" class="w-8 h-8 rounded-full mr-2">
              <div>
                <p class="text-sm font-semibold">{{ review.author }}</p>
                <p class="text-xs text-gray-400">{{ review.timestamp }}</p>
              </div>
              <div class="ml-auto text-yellow-500 text-sm">
                @for (star of [1,2,3,4,5]; track star) {
                  {{ star <= review.rating ? '★' : '☆' }}
                }
              </div>
            </div>
            <p class="text-sm text-gray-600">{{ review.comment }}</p>
          </div>
        }
      }
    </div>
  `,
})
export class CourseDetailsComponent {
  private golfService = inject(GolfService);
  course = input.required<GolfCourse>();
  close = output<void>();

  private courseId = computed(() => this.course().id);
  reviews = this.golfService.getReviewsForCourse(this.courseId);
}
