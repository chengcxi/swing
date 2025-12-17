import { Component, ChangeDetectionStrategy, output, input } from '@angular/core';

@Component({
  selector: 'app-bottom-nav',
  templateUrl: './bottom-nav.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class BottomNavComponent {
  navigate = output<any>();
  createPost = output<void>();
  activeScreen = input.required<string>();
}
