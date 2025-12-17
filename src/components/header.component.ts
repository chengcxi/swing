import { Component, ChangeDetectionStrategy, output, input } from '@angular/core';

@Component({
  selector: 'app-header',
  templateUrl: './header.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
})
export class HeaderComponent {
  activeScreen = input.required<string>();
  menuToggled = output<void>();
  messagesClicked = output<void>();
}
