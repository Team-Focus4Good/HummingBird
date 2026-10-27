import SwiftUI

// MARK: - AuthView

struct AuthView: View {
    @Environment(UserStore.self) private var userStore

    /// Called by Focus4GoodApp when authentication succeeds
    let onSuccess: () -> Void

    @State private var isSignUp = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false

    /// Validates standard email address format (e.g. user@example.com)
    private var isEmailValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return predicate.evaluate(with: trimmed)
    }

    private var isFormValid: Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty && !trimmedPassword.isEmpty else { return false }
        if isSignUp {
            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            return !trimmedName.isEmpty && password == confirmPassword
        } else {
            return true
        }
    }

    var body: some View {
        ZStack {
            // ── Rich gradient background ─────────────────────
            AppTheme.pageGradient
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                // ── Logo / Header ─────────────────────────────
                VStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)

                    Text("Focus4Good")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.orange, AppTheme.orangeDeep],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text(isSignUp ? "Create your account" : "Welcome back")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.warmTextSecondary)
                }

                Spacer(minLength: 28)

                // ── Form Fields (native style) ───────────────
                VStack(spacing: 0) {
                    if isSignUp {
                        AuthTextField(
                            icon: "person",
                            placeholder: "Full Name",
                            text: $fullName
                        )
                        Divider().padding(.leading, 48)
                    }

                    AuthTextField(
                        icon: "envelope",
                        placeholder: "Email",
                        text: $email,
                        keyboardType: .emailAddress,
                        autocapitalization: .never
                    )

                    Divider().padding(.leading, 48)

                    AuthPasswordField(
                        placeholder: "Password",
                        text: $password,
                        showPassword: $showPassword
                    )

                    if isSignUp {
                        Divider().padding(.leading, 48)
                        AuthPasswordField(
                            placeholder: "Confirm Password",
                            text: $confirmPassword,
                            showPassword: $showPassword
                        )
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .padding(.horizontal, 24)

                // ── Error Message ─────────────────────────────
                if let error = userStore.errorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(AppTheme.destructive)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                }

                Spacer(minLength: 28)

                // ── Submit Button (gradient) ─────────────────
                Button {
                    let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

                    guard !trimmedEmail.isEmpty else {
                        userStore.errorMessage = "Please enter your email"
                        return
                    }

                    guard isEmailValid else {
                        userStore.errorMessage = "Please enter a valid email address"
                        return
                    }

                    guard !trimmedPassword.isEmpty else {
                        userStore.errorMessage = "Please enter your password"
                        return
                    }

                    Task {
                        if isSignUp {
                            let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
                            await userStore.signUp(fullName: trimmedName, email: trimmedEmail, password: trimmedPassword)
                        } else {
                            await userStore.signIn(email: trimmedEmail, password: trimmedPassword)
                        }
                    }
                } label: {
                    Group {
                        if userStore.isLoading {
                            ProgressView().tint(.white)
                        } else {
                            Text(isSignUp ? "Create Account" : "Sign In")
                        }
                    }
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule().fill(
                            isFormValid
                                ? AnyShapeStyle(AppTheme.buttonGradient)
                                : AnyShapeStyle(AppTheme.orange.opacity(0.4))
                        )
                    )
                    .shadow(color: isFormValid ? AppTheme.orange.opacity(0.3) : .clear, radius: 10, y: 4)
                }
                .disabled(userStore.isLoading)
                .padding(.horizontal, 24)
                .animation(.easeInOut(duration: 0.2), value: isFormValid)

                Spacer(minLength: 20)

                // ── Toggle Sign In / Sign Up ──────────────────
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        isSignUp.toggle()
                        fullName = ""
                        email = ""
                        password = ""
                        confirmPassword = ""
                        userStore.errorMessage = nil
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                            .foregroundStyle(AppTheme.warmTextSecondary)
                        Text(isSignUp ? "Sign In" : "Sign Up")
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.orange)
                    }
                    .font(.subheadline)
                }
                .padding(.bottom, 32)
            }
        }
        // Watch for successful authentication → notify parent
        .onChange(of: userStore.isAuthenticated) { _, isAuth in
            if isAuth { onSuccess() }
        }
    }
}

// MARK: - Text Field Component

private struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var autocapitalization: TextInputAutocapitalization = .sentences

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(isFocused ? AppTheme.orange : AppTheme.warmTextSecondary)
                .font(.system(size: 16))
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            TextField(placeholder, text: $text)
                .font(.body)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled()
                .focused($isFocused)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Password Field Component

private struct AuthPasswordField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var showPassword: Bool

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock")
                .foregroundStyle(isFocused ? AppTheme.orange : AppTheme.warmTextSecondary)
                .font(.system(size: 16))
                .frame(width: 24)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            Group {
                if showPassword {
                    TextField(placeholder, text: $text)
                } else {
                    SecureField(placeholder, text: $text)
                }
            }
            .font(.body)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .focused($isFocused)

            Button {
                showPassword.toggle()
            } label: {
                Image(systemName: showPassword ? "eye.slash" : "eye")
                    .foregroundStyle(AppTheme.warmTextSecondary)
                    .font(.body)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}
