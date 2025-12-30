import { Injectable, OnDestroy, signal } from '@angular/core';
import { GolfActivity } from '../models/golf.model';

@Injectable({ providedIn: 'root' })
export class ActivityService implements OnDestroy {
  private activities = signal<GolfActivity[]>([]);
  private activityCounter = 0;
  private intervalId: any;

  private mockUsers = [
    { name: 'Alice', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG' },
    { name: 'Bob', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG' },
    { name: 'Charlie', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG' },
    { name: 'Diana', avatar: 'https://media.defense.gov/2020/Feb/19/2002251686/1088/820/0/200219-A-QY194-002.JPG' },
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
