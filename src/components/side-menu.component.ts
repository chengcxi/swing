import { Component, ChangeDetectionStrategy, input, output } from '@angular/core';

@Component({
  selector: 'app-side-menu',
  templateUrl: './side-menu.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush
})
export class SideMenuComponent {
  isOpen = input.required<boolean>();
  close = output<void>();
  menuAction = output<string>();
}
