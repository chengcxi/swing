import { Component, ChangeDetectionStrategy, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { UserService } from '../services/user.service';

@Component({
  selector: 'app-university-hub',
  templateUrl: './university-hub.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, FormsModule]
})
export class UniversityHubComponent {
  private userService = inject(UserService);
  
  currentUser = this.userService.getCurrentUser();
  leaderboard = this.userService.getUniversityLeaderboard();
  userRank = this.userService.getUserRank();
  peers = this.userService.getUniversityPeers();

  eduEmail = signal('');
  error = signal('');
  success = signal(false);

  connect() {
    this.error.set('');
    if (!this.eduEmail()) {
      this.error.set('Please enter an email address.');
      return;
    }
    
    const success = this.userService.connectToUniversity(this.eduEmail());
    if (success) {
      this.success.set(true);
    } else {
      this.error.set('Please provide a valid .edu email address.');
    }
  }
}
