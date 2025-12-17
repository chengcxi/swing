import { Injectable, signal } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class AuthService {
  isAuthenticated = signal<boolean>(false);

  constructor() {
    this.checkAutoLogin();
  }

  // Simulates checking localStorage on startup
  private checkAutoLogin() {
    try {
      const rememberMe = localStorage.getItem('rememberMe');
      const deviceSignature = localStorage.getItem('deviceSignature');
      // In a real app, you'd verify the token and signature against a server
      if (rememberMe === 'true' && deviceSignature === navigator.userAgent) {
        this.isAuthenticated.set(true);
      }
    } catch (e) {
      console.error('Could not access localStorage', e);
    }
  }
  
  // Simulates login
  async login(identifier: string, password: string, rememberMe: boolean): Promise<boolean> {
    // Mock API call
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Simple validation for mock
    if (identifier && password) {
      this.isAuthenticated.set(true);
      if (rememberMe) {
        try {
          localStorage.setItem('rememberMe', 'true');
          // Simple device signature mock
          localStorage.setItem('deviceSignature', navigator.userAgent); 
        } catch (e) {
          console.error('Could not access localStorage', e);
        }
      } else {
        localStorage.removeItem('rememberMe');
        localStorage.removeItem('deviceSignature');
      }
      return true;
    }
    return false;
  }
  
  // Simulates signup
  async signup(identifier: string, username: string, password: string): Promise<boolean> {
    // Mock API call
    await new Promise(resolve => setTimeout(resolve, 500));
    
    // Simple validation for mock
    if (identifier && username && password) {
      this.isAuthenticated.set(true);
      // No "remember me" on signup, user can choose it on next login
      return true;
    }
    return false;
  }

  logout() {
    try {
      localStorage.removeItem('rememberMe');
      localStorage.removeItem('deviceSignature');
    } catch (e) {
      console.error('Could not access localStorage', e);
    }
    this.isAuthenticated.set(false);
  }
}
