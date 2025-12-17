import { Injectable, OnDestroy, signal } from '@angular/core';
import { GolfActivity } from '../models/golf.model';

@Injectable({ providedIn: 'root' })
export class ActivityService implements OnDestroy {
  private activities = signal<GolfActivity[]>([]);
  private activityCounter = 0;
  private intervalId: any;

  private mockUsers = [
    { name: 'Alice', avatar: 'https://i.pravatar.cc/40?u=alice' },
    { name: 'Bob', avatar: 'https://i.pravatar.cc/40?u=bob' },
    { name: 'Charlie', avatar: 'https://i.pravatar.cc/40?u=charlie' },
    { name: 'Diana', avatar: 'https://i.pravatar.cc/40?u=diana' },
  ];

  private mockActions: Array<Omit<GolfActivity, 'id'|'user'|'userAvatar'|'timestamp'>> = [
    { action: 'played', details: 'a round at', target: 'Pebble Beach' },
    { action: 'posted', details: 'a new photo' },
    { action: 'commented on', details: 'your post:', target: '"Great shot on the 7th hole!"' },
    { action: 'joined', details: 'the group', target: 'Weekend Golf Warriors' },
    { action: 'played', details: 'a round at', target: 'Sandpiper Golf Club' },
    { action: 'posted', details: 'a new video' },
  ];

  constructor() {
    this.startFeed();
  }

  getActivities() {
    return this.activities.asReadonly();
  }

  private startFeed() {
    this.intervalId = setInterval(() => {
      const user = this.mockUsers[this.activityCounter % this.mockUsers.length];
      const actionDetails = this.mockActions[this.activityCounter % this.mockActions.length];

      const newActivity: GolfActivity = {
        id: Date.now(),
        user: user.name,
        userAvatar: user.avatar,
        ...actionDetails,
        timestamp: this.getRelativeTime(),
      };

      this.activities.update(activities => [newActivity, ...activities]);
      this.activityCounter++;
    }, 5000);
  }

  private getRelativeTime(): string {
    const minutes = Math.floor(Math.random() * 59);
    if (minutes < 1) return 'just now';
    if (minutes < 60) return `${minutes}m ago`;
    const hours = Math.floor(minutes / 60);
    return `${hours}h ago`;
  }

  ngOnDestroy() {
    clearInterval(this.intervalId);
  }
}
