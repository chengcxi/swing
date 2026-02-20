import SwiftUI

struct LoginView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var showPassword = false
    @State private var animatelogo = false

    var body: some View {
        ZStack {
            // Background gradient
            GolfrColors.heroGradient
                .ignoresSafeArea()

            // Subtle pattern overlay
            GeometryReader { geo in
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 300, height: 300)
                    .offset(x: -80, y: -60)

                Circle()
                    .fill(Color.white.opacity(0.04))
                    .frame(width: 200, height: 200)
                    .offset(x: geo.size.width - 80, y: geo.size.height - 200)
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer().frame(height: 60)

                    // Logo section
                    VStack(spacing: 12) {
                        // Golf ball icon
                        ZStack {
                            Circle()
                                .fill(GolfrColors.cream)
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)

                            Image(systemName: "figure.golf")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(GolfrColors.primary)
                        }
                        .scaleEffect(animatelogo ? 1.0 : 0.8)
                        .opacity(animatelogo ? 1.0 : 0.0)

                        Text("golfr")
                            .font(GolfrFonts.pageTitle(size: 42))
                            .foregroundColor(GolfrColors.cream)

                        Text("Track your game. Find your crew.")
                            .font(GolfrFonts.callout())
                            .foregroundColor(GolfrColors.textOnDarkMuted)
                    }
                    .padding(.bottom, 8)

                    // Input card
                    VStack(spacing: 20) {
                        // Segment toggle
                        HStack(spacing: 0) {
                            SegmentButton(title: "Sign In", isSelected: !isSignUp) {
                                withAnimation(.easeInOut(duration: 0.25)) { isSignUp = false }
                            }
                            SegmentButton(title: "Sign Up", isSelected: isSignUp) {
                                withAnimation(.easeInOut(duration: 0.25)) { isSignUp = true }
                            }
                        }
                        .background(
                            Capsule().fill(GolfrColors.backgroundElevated)
                        )

                        // Email field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundColor(GolfrColors.textSecondary)
                                    .font(.system(size: 16))
                                TextField("you@university.edu", text: $email)
                                    .font(GolfrFonts.body())
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(GolfrColors.backgroundElevated)
                            )
                        }

                        // Password field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Password")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)

                            HStack {
                                Image(systemName: "lock")
                                    .foregroundColor(GolfrColors.textSecondary)
                                    .font(.system(size: 16))

                                if showPassword {
                                    TextField("Enter password", text: $password)
                                        .font(GolfrFonts.body())
                                        .textContentType(.password)
                                } else {
                                    SecureField("Enter password", text: $password)
                                        .font(GolfrFonts.body())
                                        .textContentType(.password)
                                }

                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash" : "eye")
                                        .foregroundColor(GolfrColors.textSecondary)
                                        .font(.system(size: 14))
                                }
                            }
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(GolfrColors.backgroundElevated)
                            )
                        }

                        // Error message
                        if let error = appViewModel.authError {
                            Text(error)
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.error)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        // Action button
                        Button(action: {
                            Task {
                                if isSignUp {
                                    await appViewModel.signUp(email: email, password: password)
                                } else {
                                    await appViewModel.signIn(email: email, password: password)
                                }
                            }
                        }) {
                            HStack {
                                if appViewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(GolfrFonts.headline())
                                    Image(systemName: "arrow.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Capsule()
                                    .fill(GolfrColors.heroGradient)
                            )
                            .shadow(color: GolfrColors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .disabled(appViewModel.isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)
                        .padding(.top, 4)

                        // Divider
                        HStack {
                            Rectangle().fill(GolfrColors.textSecondary.opacity(0.2)).frame(height: 1)
                            Text("or")
                                .font(GolfrFonts.caption())
                                .foregroundColor(GolfrColors.textSecondary)
                            Rectangle().fill(GolfrColors.textSecondary.opacity(0.2)).frame(height: 1)
                        }

                        // Sign in with Apple
                        Button(action: {}) {
                            HStack(spacing: 8) {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 18))
                                Text("Continue with Apple")
                                    .font(GolfrFonts.headline())
                            }
                            .foregroundColor(GolfrColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                Capsule()
                                    .fill(GolfrColors.backgroundCard)
                                    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
                            )
                        }
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(GolfrColors.backgroundCard)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)
                    .padding(.horizontal, 20)

                    Spacer().frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.7).delay(0.2)) {
                animatelogo = true
            }
        }
    }
}

// MARK: - Segment Button

struct SegmentButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(GolfrFonts.callout())
                .foregroundColor(isSelected ? .white : GolfrColors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? GolfrColors.primary : Color.clear)
                )
        }
    }
}
