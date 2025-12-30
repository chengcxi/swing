import { Component, ChangeDetectionStrategy, input, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GolfCourse } from '../models/golf.model';

@Component({
  selector: 'app-course-card',
  templateUrl: './course-card.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class CourseCardComponent {
  course = input.required<GolfCourse>();

  getStarArray = computed(() => {
    const rating = Math.round(this.course().rating);
    return Array(5).fill(0).map((_, i) => i < rating ? 1 : 0);
  });
}
