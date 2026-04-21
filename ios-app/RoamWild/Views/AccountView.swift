//
//  AccountView.swift
//  RoamWild
//
//  User panel — avatar, stats, saved spots, feedback, sign out, delete.
//

import SwiftUI

struct AccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var isSigningOut = false
    @State private var isDeleting = false
    @State private var showDeleteConfirm = false
    @State private var deleteError: String?
    @State private var showSavedSpots = false
    @State private var showPrivacy = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [Brand.night, Color(red: 0.18, green: 0.18, blue: 0.16)],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    panel
                    footer
                    Button {
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.left")
                            .font(.system(size: 13))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            }
        }
        .task {
            await appState.refreshProfile()
        }
        .sheet(isPresented: $showSavedSpots) {
            SavedSpotsView()
        }
        .sheet(isPresented: $showPrivacy) {
            PrivacyPolicyView()
        }
        .alert("Delete your Roam Wild account?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task { await performDelete() }
            }
        } message: {
            Text("This removes your profile, saved spots, and submissions. It can't be undone.")
        }
    }

    // MARK: - Panel

    private var panel: some View {
        VStack(spacing: 18) {
            avatar
            VStack(spacing: 4) {
                Text(displayName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Brand.night)
                if let email = appState.email {
                    Text(email)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
                if let activity = appState.profile?.favouriteActivity, !activity.isEmpty {
                    Text("Favourite activity: \(activity)")
                        .font(.system(size: 11))
                        .foregroundColor(Brand.ember)
                        .padding(.top, 4)
                }
            }

            statsRow

            VStack(spacing: 10) {
                Button {
                    showSavedSpots = true
                } label: {
                    actionLabel("Saved spots", systemImage: "heart.fill",
                                badge: appState.savedCount > 0 ? "\(appState.savedCount)" : nil)
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    actionLabel("Explore the map", systemImage: "map")
                }
                .buttonStyle(.plain)

                if let url = URL(string: "mailto:hello@roamwild.app?subject=Roam%20Wild%20feedback") {
                    Link(destination: url) {
                        actionLabel("Send feedback", systemImage: "envelope")
                    }
                }

                Button {
                    showPrivacy = true
                } label: {
                    actionLabel("Privacy policy", systemImage: "lock.shield")
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        isSigningOut = true
                        await appState.signOut()
                        isSigningOut = false
                        dismiss()
                    }
                } label: {
                    Text(isSigningOut ? "Signing out..." : "Sign Out")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(red: 0.77, green: 0.24, blue: 0.06))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(Color(red: 0.99, green: 0.92, blue: 0.92))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(isSigningOut || isDeleting)

                Button {
                    showDeleteConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        if isDeleting { ProgressView().scaleEffect(0.7) }
                        Text(isDeleting ? "Deleting..." : "Delete Account")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.red.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .disabled(isDeleting || isSigningOut)

                if let err = deleteError {
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(28)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .frame(maxWidth: 400)
    }

    private var avatar: some View {
        Circle()
            .fill(Brand.ember)
            .frame(width: 72, height: 72)
            .overlay(
                Text(initial)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white)
            )
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statBox(value: "\(appState.savedCount)", label: "Saved")
            statBox(value: "\(appState.addedCount)", label: "Added")
            statBox(value: "\(appState.reviewsCount)", label: "Reviews")
        }
    }

    private func statBox(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 24, weight: .heavy))
                .foregroundColor(Brand.ember)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Brand.canvas)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func actionLabel(_ title: String, systemImage: String, badge: String? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Brand.ember)
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Brand.night)
            Spacer()
            if let badge {
                Text(badge)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8).padding(.vertical, 2)
                    .background(Brand.ember)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.12), lineWidth: 1)
        )
    }

    private var footer: some View {
        VStack(spacing: 2) {
            Text("Roam Wild")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(Color.white.opacity(0.4))
            Text(versionString)
                .font(.system(size: 10))
                .foregroundColor(Color.white.opacity(0.3))
        }
    }

    // MARK: - Helpers

    private var displayName: String {
        if let n = appState.profile?.username, !n.isEmpty { return n }
        if let n = appState.username, !n.isEmpty { return n }
        if let e = appState.email { return String(e.split(separator: "@").first ?? "Adventurer") }
        return "Adventurer"
    }

    private var initial: String {
        if let first = displayName.first { return String(first).uppercased() }
        return "R"
    }

    private var versionString: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(v) • build \(b)"
    }

    private func performDelete() async {
        deleteError = nil
        isDeleting = true
        do {
            try await appState.deleteAccount()
            isDeleting = false
            dismiss()
        } catch {
            deleteError = error.localizedDescription
            isDeleting = false
        }
    }
}

#Preview {
    AccountView()
        .environmentObject({
            let s = AppState(); s.username = "milli"; return s
        }())
}
