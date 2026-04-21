//
//  AuthView.swift
//  RoamWild
//
//  Mirror of auth.html — Sign In / Sign Up tabs against Supabase Auth.
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    enum Mode: Hashable { case signIn, signUp }
    @State private var mode: Mode = .signIn

    // Sign-in
    @State private var siEmail: String = ""
    @State private var siPassword: String = ""

    // Sign-up
    @State private var suUsername: String = ""
    @State private var suEmail: String = ""
    @State private var suPassword: String = ""
    @State private var suActivity: String = ""

    @State private var isBusy = false
    @State private var message: AuthMessage?

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.night, Color(red: 0.18, green: 0.18, blue: 0.16)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    header
                    card
                    Button("← Back") { dismiss() }
                        .font(.system(size: 13))
                        .foregroundColor(Color.white.opacity(0.5))
                        .padding(.top, 8)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Pieces

    private var header: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoamWildLogoBadge(size: 52, cornerRadius: 14)
                Text("Roam Wild")
                    .font(.system(size: 42, weight: .heavy))
                    .kerning(2)
                    .foregroundColor(.white)
            }
            Text("GO FURTHER")
                .font(.system(size: 13, weight: .medium))
                .kerning(2)
                .foregroundColor(Color.white.opacity(0.4))
        }
    }

    private var card: some View {
        VStack(spacing: 20) {
            tabBar

            if let msg = message {
                Text(msg.text)
                    .font(.system(size: 12))
                    .foregroundColor(msg.color.fg)
                    .padding(.horizontal, 14).padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(msg.color.bg)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if mode == .signIn { signInForm } else { signUpForm }
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(maxWidth: 400)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tab("Sign In", active: mode == .signIn) { mode = .signIn; message = nil }
            tab("Sign Up", active: mode == .signUp) { mode = .signUp; message = nil }
        }
        .padding(3)
        .background(Brand.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func tab(_ title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(active ? Brand.night : Color.black.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(active ? Color.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: active ? .black.opacity(0.08) : .clear, radius: 3, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Forms

    private var signInForm: some View {
        VStack(spacing: 14) {
            labeled("EMAIL") {
                TextField("you@email.com", text: $siEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            labeled("PASSWORD") {
                SecureField("••••••••", text: $siPassword)
                    .textContentType(.password)
            }
            HStack {
                Spacer()
                Button("Forgot password?") {
                    Task { await doResetPassword() }
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Brand.ember)
            }
            primaryButton(title: isBusy ? "Signing in..." : "Sign In  →") {
                Task { await doSignIn() }
            }
            divider
            socialStub("Continue with Google", systemImage: "g.circle.fill")
            socialStub("Continue with Apple", systemImage: "apple.logo")
        }
    }

    private var signUpForm: some View {
        VStack(spacing: 14) {
            labeled("USERNAME") {
                TextField("adventurer_123", text: $suUsername)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            labeled("EMAIL") {
                TextField("you@email.com", text: $suEmail)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }
            labeled("PASSWORD") {
                SecureField("Min 6 characters", text: $suPassword)
                    .textContentType(.newPassword)
            }
            labeled("FAVOURITE ACTIVITY") {
                TextField("e.g. Gold fossicking, MTB, Surfing", text: $suActivity)
            }
            primaryButton(title: isBusy ? "Creating account..." : "Create Account  →") {
                Task { await doSignUp() }
            }
        }
    }

    // MARK: - Form primitives

    private func labeled<Content: View>(_ label: String,
                                        @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .kerning(0.5)
                .foregroundColor(Color.black.opacity(0.5))
            content()
                .font(.system(size: 14))
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .background(Brand.canvas)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func primaryButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 13)
                .background(isBusy ? Color.gray : Brand.ember)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .disabled(isBusy)
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
            Text("or").font(.system(size: 12)).foregroundColor(.gray)
            Rectangle().fill(Color.black.opacity(0.08)).frame(height: 1)
        }
    }

    private func socialStub(_ title: String, systemImage: String) -> some View {
        Button {
            message = .info("\(title.replacingOccurrences(of: "Continue with ", with: "")) sign-in coming soon! Use email for now.")
        } label: {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Brand.night)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func doResetPassword() async {
        let email = siEmail.trimmingCharacters(in: .whitespaces)
        guard !email.isEmpty else {
            message = .error("Enter your email above, then tap 'Forgot password?' again.")
            return
        }
        isBusy = true; defer { isBusy = false }
        do {
            try await appState.requestPasswordReset(email: email)
            message = .success("Check your inbox — we've sent a reset link to \(email).")
        } catch {
            message = .error(error.localizedDescription)
        }
    }

    private func doSignIn() async {
        guard !siEmail.isEmpty, !siPassword.isEmpty else {
            message = .error("Please fill in all fields"); return
        }
        isBusy = true; defer { isBusy = false }
        do {
            try await appState.signIn(email: siEmail.trimmingCharacters(in: .whitespaces),
                                      password: siPassword)
            message = .success("Signed in! Welcome back 🎉")
            try? await Task.sleep(nanoseconds: 400_000_000)
            dismiss()
        } catch {
            message = .error(error.localizedDescription)
        }
    }

    private func doSignUp() async {
        guard !suUsername.isEmpty, !suEmail.isEmpty, !suPassword.isEmpty else {
            message = .error("Please fill in all required fields"); return
        }
        guard suPassword.count >= 6 else {
            message = .error("Password must be at least 6 characters"); return
        }
        isBusy = true; defer { isBusy = false }
        do {
            let autoSignedIn = try await appState.signUp(
                email: suEmail.trimmingCharacters(in: .whitespaces),
                password: suPassword,
                username: suUsername.trimmingCharacters(in: .whitespaces),
                favouriteActivity: suActivity.trimmingCharacters(in: .whitespaces)
            )
            if autoSignedIn {
                message = .success("Account created! Welcome to Roam Wild 🎉")
                try? await Task.sleep(nanoseconds: 600_000_000)
                dismiss()
            } else {
                message = .info("Account created — please check your email to confirm, then sign in.")
                mode = .signIn
                siEmail = suEmail
            }
        } catch {
            message = .error(error.localizedDescription)
        }
    }
}

// MARK: - Message model

struct AuthMessage: Equatable {
    enum Kind { case error, success, info }
    let text: String
    let kind: Kind

    static func error(_ t: String) -> AuthMessage { .init(text: t, kind: .error) }
    static func success(_ t: String) -> AuthMessage { .init(text: t, kind: .success) }
    static func info(_ t: String) -> AuthMessage { .init(text: t, kind: .info) }

    var color: (fg: Color, bg: Color) {
        switch kind {
        case .error:   return (Color(red: 0.77, green: 0.24, blue: 0.06), Color(red: 0.99, green: 0.92, blue: 0.92))
        case .success: return (Color(red: 0.03, green: 0.31, blue: 0.25), Color(red: 0.88, green: 0.96, blue: 0.93))
        case .info:    return (Color(red: 0.09, green: 0.37, blue: 0.64), Color(red: 0.9, green: 0.95, blue: 0.98))
        }
    }
}

#Preview {
    AuthView().environmentObject(AppState())
}
