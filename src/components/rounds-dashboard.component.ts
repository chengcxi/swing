import { Component, ChangeDetectionStrategy, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { GolfService } from '../services/golf.service';
import { AnalyticsDashboardComponent } from './analytics.component';
import { UserService } from '../services/user.service';

type Tab = 'Rounds' | 'Rankings' | 'Analytics';

@Component({
  selector: 'app-profile',
  templateUrl: './rounds-dashboard.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, AnalyticsDashboardComponent],
})
export class ProfileComponent {
  private golfService = inject(GolfService);
  private userService = inject(UserService);

  currentUser = this.userService.getCurrentUser();
  stats = this.golfService.getUserStats();
  recentRounds = this.golfService.getRecentRounds();
  courseRankings = this.golfService.getCourseRankings();

  activeTab = signal<Tab>('Analytics');

  selectTab(tab: Tab) {
    this.activeTab.set(tab);
  }

  getRankingBadgeClass(rank: number): string {
    switch (rank) {
      case 1:
        return 'bg-yellow-400 text-yellow-800';
      case 2:
        return 'bg-gray-300 text-gray-700';
      case 3:
        return 'bg-orange-400 text-orange-800';
      default:
        return 'bg-gray-200 text-gray-600';
    }
  }
}
