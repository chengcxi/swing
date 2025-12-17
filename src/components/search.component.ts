import { Component, ChangeDetectionStrategy, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GolfService } from '../services/golf.service';
import { GolfCourse } from '../models/golf.model';
import { CourseCardComponent } from './course-card.component';

@Component({
  selector: 'app-search',
  templateUrl: './search.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, CourseCardComponent],
})
export class SearchComponent {
  private golfService = inject(GolfService);

  searchTerm = signal('');
  holeFilter = signal<number | 'all'>('all');
  practiceFacilityFilter = signal(false);

  courses = this.golfService.getCourses();

  filteredCourses = computed(() => {
    const term = this.searchTerm().toLowerCase();
    const holes = this.holeFilter();
    const practice = this.practiceFacilityFilter();

    return this.courses().filter(course => {
      const matchesTerm = course.name.toLowerCase().includes(term) || course.location.toLowerCase().includes(term);
      const matchesHoles = holes === 'all' || course.holes === holes;
      const matchesPractice = !practice || (course.facilities.drivingRange || course.facilities.puttingGreen);
      return matchesTerm && matchesHoles && matchesPractice;
    });
  });

  onSearch(event: Event) {
    this.searchTerm.set((event.target as HTMLInputElement).value);
  }

  onHoleFilterChange(event: Event) {
    const value = (event.target as HTMLSelectElement).value;
    this.holeFilter.set(value === 'all' ? 'all' : Number(value));
  }

  togglePracticeFacility() {
    this.practiceFacilityFilter.update(value => !value);
  }
}
