import { Component, ChangeDetectionStrategy, input, output, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { UserService } from '../services/user.service';

@Component({
  selector: 'app-side-menu',
  templateUrl: './side-menu.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule]
})
export class SideMenuComponent {
  private userService = inject(UserService);
  currentUser = this.userService.getCurrentUser();

  isOpen = input.required<boolean>();
  close = output<void>();
  menuAction = output<string>();
}
