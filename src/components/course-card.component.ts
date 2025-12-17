import { Component, ChangeDetectionStrategy, input } from '@angular/core';
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
}
