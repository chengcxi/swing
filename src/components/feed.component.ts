import { Component, ChangeDetectionStrategy, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ActivityService } from '../services/activity.service';

@Component({
  selector: 'app-activity-feed',
  templateUrl: './feed.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class ActivityFeedComponent {
  private activityService = inject(ActivityService);
  activities = this.activityService.getActivities();
}
