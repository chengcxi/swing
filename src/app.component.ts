import { Component, ChangeDetectionStrategy, signal, inject } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from './components/header.component';
import { ProfileComponent } from './components/rounds-dashboard.component';
import { BottomNavComponent } from './components/bottom-nav.component';
import { ActivityFeedComponent } from './components/feed.component';
import { SearchComponent } from './components/search.component';
import { SideMenuComponent } from './components/side-menu.component';
import { FriendFinderComponent } from './components/friend-finder.component';
import { PostFeedComponent } from './components/post-feed.component';
import { CreatePostComponent } from './components/create-post.component';
import { MessagesComponent } from './components/messages.component';
import { LoginComponent } from './components/login.component';
import { AuthService } from './services/auth.service';

type Screen = 'feed' | 'profile' | 'search' | 'notifications' | 'messages';

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, HeaderComponent, ProfileComponent, BottomNavComponent, ActivityFeedComponent, SearchComponent, SideMenuComponent, FriendFinderComponent, PostFeedComponent, CreatePostComponent, MessagesComponent, LoginComponent],
})
export class AppComponent {
  private authService = inject(AuthService);
  isAuthenticated = this.authService.isAuthenticated;

  activeScreen = signal<Screen>('feed');
  isMenuOpen = signal(false);
  isFriendFinderOpen = signal(false);
  isCreatePostOpen = signal(false);

  onNavigate(screen: Screen) {
    this.activeScreen.set(screen);
  }

  toggleMenu() {
    this.isMenuOpen.update(open => !open);
  }

  onMenuAction(action: string) {
    if (action === 'logout') {
      this.authService.logout();
      this.isMenuOpen.set(false);
      return;
    }
    
    this.toggleMenu();
    if (action === 'findFriends') {
      this.isFriendFinderOpen.set(true);
    } else if (action === 'profile') {
      this.activeScreen.set('profile');
    }
  }

  closeFriendFinder() {
    this.isFriendFinderOpen.set(false);
  }

  openCreatePost() {
    this.isCreatePostOpen.set(true);
  }

  closeCreatePost() {
    this.isCreatePostOpen.set(false);
  }
}
