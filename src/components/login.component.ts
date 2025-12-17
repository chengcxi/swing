import { Component, ChangeDetectionStrategy, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, Validators } from '@angular/forms';
import { AuthService } from '../services/auth.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.component.html',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule, ReactiveFormsModule],
})
export class LoginComponent {
  private fb = inject(FormBuilder);
  private authService = inject(AuthService);

  mode = signal<'signIn' | 'signUp'>('signIn');
  isLoading = signal(false);
  errorMessage = signal<string | null>(null);

  signInForm = this.fb.group({
    identifier: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required]],
    rememberMe: [false]
  });

  signUpForm = this.fb.group({
    identifier: ['', [Validators.required, Validators.email]],
    username: ['', [Validators.required]],
    password: ['', [Validators.required, Validators.minLength(8)]],
  });

  toggleMode() {
    this.mode.update(m => m === 'signIn' ? 'signUp' : 'signIn');
    this.errorMessage.set(null);
    this.signInForm.reset();
    this.signUpForm.reset();
  }

  async onSubmit() {
    this.isLoading.set(true);
    this.errorMessage.set(null);

    try {
      if (this.mode() === 'signIn') {
        const { identifier, password, rememberMe } = this.signInForm.value;
        const success = await this.authService.login(identifier!, password!, rememberMe!);
        if (!success) {
          this.errorMessage.set('Invalid credentials. Please try again.');
        }
      } else { // signUp
        const { identifier, username, password } = this.signUpForm.value;
        const success = await this.authService.signup(identifier!, username!, password!);
         if (!success) {
          this.errorMessage.set('Sign up failed. Please try again.');
        }
      }
    } catch (error) {
      this.errorMessage.set('An unexpected error occurred.');
    } finally {
      this.isLoading.set(false);
    }
  }
}
