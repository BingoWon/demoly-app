//
//  LoginView.swift
//  Swipop
//

import AuthenticationServices
import ClerkKit
import SwiftUI

struct LoginView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: AuthMode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var verificationCode = ""
    @State private var pendingSignUp: SignUp?
    @State private var showPassword = false
    @State private var errorMessage: String?
    @State private var isLoading = false

    @FocusState private var focusedField: Field?

    private enum AuthMode {
        case signIn, signUp, verifyEmail
        var title: String {
            switch self {
            case .signIn: "Sign In"
            case .signUp: "Sign Up"
            case .verifyEmail: "Verify Email"
            }
        }

        var buttonTitle: String {
            switch self {
            case .signIn: "Sign In"
            case .signUp: "Create Account"
            case .verifyEmail: "Verify"
            }
        }

        var switchPrompt: String {
            switch self {
            case .signIn: "Don't have an account?"
            case .signUp, .verifyEmail: "Already have an account?"
            }
        }

        var switchAction: String {
            switch self {
            case .signIn: "Sign Up"
            case .signUp, .verifyEmail: "Sign In"
            }
        }
    }

    private enum Field: Hashable { case email, password, confirmPassword, code }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header

                    if mode == .verifyEmail {
                        verifyEmailContent
                    } else {
                        socialButtons
                        divider
                        emailForm
                        switchModeButton
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)

            if isLoading { loadingOverlay }
        }
        .onChange(of: Clerk.shared.user?.id) { _, newId in
            if newId != nil { isPresented = false }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 0) {
            HStack {
                Button { isPresented = false } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 36, height: 36)
                        .background(.ultraThinMaterial, in: Circle())
                }
                Spacer()
            }
            .padding(.top, 8)

            VStack(spacing: 8) {
                Text("Swipop")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.primary, .brand], startPoint: .leading, endPoint: .trailing)
                    )

                Text(mode.title)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 24)
        }
    }

    // MARK: - Social Buttons

    private var socialButtons: some View {
        VStack(spacing: 12) {
            SocialLoginButton(
                icon: Image(systemName: "apple.logo"),
                title: "Continue with Apple",
                style: colorScheme == .dark ? .light : .dark
            ) {
                await oauthFlow { try await Clerk.shared.auth.signInWithApple() }
            }

            SocialLoginButton(
                icon: Image("GoogleLogo"),
                title: "Continue with Google",
                style: .outline
            ) {
                await oauthFlow { try await Clerk.shared.auth.signInWithOAuth(provider: .google) }
            }

            SocialLoginButton(
                icon: Image("GitHubLogo").renderingMode(.template),
                title: "Continue with GitHub",
                style: .outline
            ) {
                await oauthFlow { try await Clerk.shared.auth.signInWithOAuth(provider: .github) }
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        HStack(spacing: 16) {
            Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
            Text("or").font(.system(size: 13)).foregroundStyle(.tertiary)
            Rectangle().fill(Color.primary.opacity(0.1)).frame(height: 1)
        }
    }

    // MARK: - Email Form

    private var emailForm: some View {
        VStack(spacing: 14) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(focusedField == .email ? Color.brand : Color.clear, lineWidth: 1.5)
                )

            HStack(spacing: 0) {
                Group {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                }
                .textContentType(mode == .signUp ? .newPassword : .password)
                .focused($focusedField, equals: .password)

                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .font(.system(size: 15))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(focusedField == .password ? Color.brand : Color.clear, lineWidth: 1.5)
            )

            if mode == .signUp {
                SecureField("Confirm Password", text: $confirmPassword)
                    .textContentType(.newPassword)
                    .focused($focusedField, equals: .confirmPassword)
                    .padding(.horizontal, 16)
                    .frame(height: 50)
                    .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(focusedField == .confirmPassword ? Color.brand : Color.clear, lineWidth: 1.5)
                    )
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: submitForm) {
                Text(mode.buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1 : 0.5)
        }
        .animation(.easeInOut(duration: 0.2), value: mode)
    }

    // MARK: - Verify Email

    private var verifyEmailContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)

            Text("Enter the verification code sent to \(email)")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            TextField("Verification code", text: $verificationCode)
                .textContentType(.oneTimeCode)
                .keyboardType(.numberPad)
                .focused($focusedField, equals: .code)
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color.secondaryBackground, in: RoundedRectangle(cornerRadius: 12))

            if let error = errorMessage {
                Text(error)
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button {
                Task { await verifyEmail() }
            } label: {
                Text("Verify")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.brand, in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(verificationCode.isEmpty)
            .opacity(verificationCode.isEmpty ? 0.5 : 1)

            switchModeButton
        }
    }

    // MARK: - Switch Mode

    private var switchModeButton: some View {
        HStack(spacing: 4) {
            Text(mode.switchPrompt).foregroundStyle(.secondary)
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    mode = mode == .signIn ? .signUp : .signIn
                    errorMessage = nil
                    confirmPassword = ""
                    verificationCode = ""
                    pendingSignUp = nil
                }
            } label: {
                Text(mode.switchAction).fontWeight(.semibold).foregroundStyle(Color.brand)
            }
        }
        .font(.system(size: 14))
    }

    // MARK: - Loading

    private var loadingOverlay: some View {
        Color.appBackground.opacity(0.8).ignoresSafeArea()
            .overlay { ProgressView().tint(.brand).scaleEffect(1.2) }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let emailOK = email.contains("@") && email.contains(".")
        let passOK = password.count >= 8
        return mode == .signUp ? emailOK && passOK && password == confirmPassword : emailOK && passOK
    }

    // MARK: - Actions

    private func submitForm() {
        focusedField = nil
        errorMessage = nil
        Task {
            if mode == .signUp {
                await signUpWithEmail()
            } else {
                await signInWithEmail()
            }
        }
    }

    @MainActor
    private func signInWithEmail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await Clerk.shared.auth.signInWithPassword(identifier: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func signUpWithEmail() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let signUp = try await Clerk.shared.auth.signUp(
                emailAddress: email,
                password: password
            )
            if signUp.status == .missingRequirements {
                pendingSignUp = try await signUp.sendEmailCode()
                withAnimation(.easeInOut(duration: 0.2)) { mode = .verifyEmail }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    private func verifyEmail() async {
        guard let pending = pendingSignUp, !verificationCode.isEmpty else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await pending.verifyEmailCode(verificationCode)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func isUserCancellation(_ error: Error) -> Bool {
        let nsError = error as NSError
        switch (nsError.domain, nsError.code) {
        case (ASWebAuthenticationSessionError.errorDomain, ASWebAuthenticationSessionError.canceledLogin.rawValue),
             (ASAuthorizationError.errorDomain, ASAuthorizationError.canceled.rawValue):
            return true
        default:
            return Task.isCancelled
        }
    }

    @MainActor
    private func oauthFlow(_ action: () async throws -> some Any) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await action()
        } catch {
            if !isUserCancellation(error) { errorMessage = error.localizedDescription }
        }
    }
}

// MARK: - Social Login Button

private struct SocialLoginButton: View {
    let icon: Image
    let title: String
    let style: Style
    let action: () async -> Void

    enum Style { case dark, light, outline }

    var body: some View {
        Button {
            Task { await action() }
        } label: {
            HStack(spacing: 12) {
                icon.resizable().scaledToFit().frame(width: 20, height: 20)
                Text(title).font(.system(size: 16, weight: .medium))
            }
            .foregroundStyle(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor, in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                if style == .outline {
                    RoundedRectangle(cornerRadius: 12).strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                }
            }
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .dark: .white
        case .light: .black
        case .outline: .primary
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .dark: .black
        case .light: .white
        case .outline: Color.secondaryBackground
        }
    }
}

#Preview {
    LoginView(isPresented: .constant(true))
}
