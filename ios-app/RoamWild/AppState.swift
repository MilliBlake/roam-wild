//
//  AppState.swift
//  RoamWild
//
//  Global observable state shared across views.
//

import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {

    // MARK: - Spots

    @Published var spots: [Spot] = []
    @Published var isLoading = false
    @Published var loadError: String?

    @Published var savedSpotIDs: Set<String> = []

    // MARK: - Auth

    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var userId: String?
    @Published private(set) var email: String?
    @Published var profile: Profile?

    /// Display name in the UI. Falls back to local username, then email handle.
    @Published var username: String? {
        didSet { UserDefaults.standard.set(username, forKey: "rw_username") }
    }

    var isSignedIn: Bool { accessToken != nil }

    @Published var hasOnboarded: Bool {
        didSet { UserDefaults.standard.set(hasOnboarded, forKey: "rw_onboarded") }
    }

    // MARK: - Filters

    @Published var activeCategoryFilter: SpotCategory? = nil
    @Published var freeOnly: Bool = false
    @Published var knownOnly: Bool = false
    @Published var searchText: String = ""

    // MARK: - Init

    init() {
        let defaults = UserDefaults.standard
        self.username = defaults.string(forKey: "rw_username")
        self.hasOnboarded = defaults.bool(forKey: "rw_onboarded")
        if let saved = defaults.array(forKey: "rw_saved_spots") as? [String] {
            self.savedSpotIDs = Set(saved)
        }
        self.accessToken = defaults.string(forKey: "rw_token")
        self.refreshToken = defaults.string(forKey: "rw_refresh")
        self.userId = defaults.string(forKey: "rw_user_id")
        self.email = defaults.string(forKey: "rw_email")
    }

    // MARK: - Spot loading

    func loadSpots() async {
        isLoading = true
        loadError = nil
        do {
            let loaded = try await SupabaseService.shared.fetchSpots()
            self.spots = loaded
        } catch {
            self.loadError = error.localizedDescription
        }
        isLoading = false
    }

    var filteredSpots: [Spot] {
        spots.filter { spot in
            if freeOnly && spot.type != .free { return false }
            if knownOnly && !spot.isKnownSpot { return false }
            if let cat = activeCategoryFilter, spot.category != cat { return false }
            if !searchText.isEmpty {
                let q = searchText.lowercased()
                let haystack = [spot.name, spot.location, spot.category.displayName,
                                spot.description ?? "", spot.insiderTip ?? ""]
                    .joined(separator: " ").lowercased()
                if !haystack.contains(q) { return false }
            }
            return true
        }
    }

    // MARK: - Saved spots

    func toggleSaved(_ spot: Spot) {
        if savedSpotIDs.contains(spot.id) {
            savedSpotIDs.remove(spot.id)
        } else {
            savedSpotIDs.insert(spot.id)
        }
        UserDefaults.standard.set(Array(savedSpotIDs), forKey: "rw_saved_spots")
    }

    func isSaved(_ spot: Spot) -> Bool { savedSpotIDs.contains(spot.id) }

    var countsByCategory: [SpotCategory: Int] {
        var d: [SpotCategory: Int] = [:]
        for s in spots { d[s.category, default: 0] += 1 }
        return d
    }

    // MARK: - Auth

    /// Apply a freshly-issued session and persist tokens.
    func apply(session: AuthSession, fallbackUsername: String? = nil) {
        self.accessToken = session.accessToken
        self.refreshToken = session.refreshToken
        self.userId = session.user.id
        self.email = session.user.email

        let metadataName = session.user.userMetadata?["username"]?.stringValue
        let derived = fallbackUsername
            ?? metadataName
            ?? session.user.email?.split(separator: "@").first.map(String.init)
        if let derived, !derived.isEmpty {
            self.username = derived
        }

        let d = UserDefaults.standard
        d.set(session.accessToken, forKey: "rw_token")
        d.set(session.refreshToken, forKey: "rw_refresh")
        d.set(session.user.id, forKey: "rw_user_id")
        d.set(session.user.email, forKey: "rw_email")
    }

    func signIn(email: String, password: String) async throws {
        let session = try await SupabaseService.shared.signIn(email: email, password: password)
        apply(session: session)
        await refreshProfile()
    }

    /// Returns true if the account was created AND signed in. Returns false if Supabase
    /// requires email confirmation before issuing a session.
    @discardableResult
    func signUp(email: String, password: String, username: String, favouriteActivity: String) async throws -> Bool {
        let session = try await SupabaseService.shared.signUp(
            email: email, password: password,
            username: username, favouriteActivity: favouriteActivity
        )
        if let session {
            apply(session: session, fallbackUsername: username)
            await refreshProfile()
            return true
        } else {
            // Account created but no session yet — store the chosen username locally.
            self.username = username
            return false
        }
    }

    func signOut() async {
        if let token = accessToken {
            try? await SupabaseService.shared.signOut(token: token)
        }
        clearAuth()
    }

    /// Request password reset email. No auth required.
    func requestPasswordReset(email: String) async throws {
        try await SupabaseService.shared.requestPasswordReset(email: email)
    }

    /// Permanently delete the user's account. Fires the server-side RPC, then
    /// signs out locally. Apple guideline 5.1.1(v) compliance.
    func deleteAccount() async throws {
        guard let token = accessToken else { throw SubmitError.notSignedIn }
        // Best-effort server-side request — if the RPC doesn't exist yet, we still
        // sign the user out so the local session is cleared.
        try? await SupabaseService.shared.requestAccountDeletion(token: token)
        try? await SupabaseService.shared.signOut(token: token)
        clearAuth()
    }

    func refreshProfile() async {
        guard let userId, let accessToken else { return }
        do {
            self.profile = try await SupabaseService.shared.fetchProfile(userId: userId, token: accessToken)
            if let n = profile?.username, !n.isEmpty {
                self.username = n
            }
        } catch {
            // Non-fatal — profile row may not exist yet on first sign-in.
        }
    }

    private func clearAuth() {
        self.accessToken = nil
        self.refreshToken = nil
        self.userId = nil
        self.email = nil
        self.profile = nil
        self.username = nil
        let d = UserDefaults.standard
        d.removeObject(forKey: "rw_token")
        d.removeObject(forKey: "rw_refresh")
        d.removeObject(forKey: "rw_user_id")
        d.removeObject(forKey: "rw_email")
        d.removeObject(forKey: "rw_username")
    }

    // MARK: - Account stats (for AccountView)

    var savedCount: Int { savedSpotIDs.count }

    /// Local-only counters for V1. Will be replaced by server-side aggregates in V2.
    var addedCount: Int {
        get { UserDefaults.standard.integer(forKey: "rw_added_count") }
        set {
            UserDefaults.standard.set(newValue, forKey: "rw_added_count")
            objectWillChange.send()
        }
    }
    var reviewsCount: Int { UserDefaults.standard.integer(forKey: "rw_reviews_count") }

    // MARK: - Add Spot submission

    enum SubmitError: LocalizedError {
        case notSignedIn
        case missingLocation
        case server(String)

        var errorDescription: String? {
            switch self {
            case .notSignedIn: return "Please sign in before adding a spot."
            case .missingLocation: return "Pick a location — tap \"Use my location\" or enter coordinates."
            case .server(let msg): return msg
            }
        }
    }

    /// Submit a new spot. Requires the user to be signed in. The row is created with
    /// approved=false so it goes through review before appearing on the public map.
    func submitSpot(_ draft: SpotDraft) async throws {
        guard let token = accessToken, let userId else {
            throw SubmitError.notSignedIn
        }
        if draft.latitude == 0 && draft.longitude == 0 {
            throw SubmitError.missingLocation
        }
        var populated = draft
        populated.submittedBy = userId
        do {
            _ = try await SupabaseService.shared.createSpot(draft: populated, token: token)
            addedCount += 1
        } catch let err as SupabaseError {
            throw SubmitError.server(err.errorDescription ?? "Submission failed.")
        } catch {
            throw SubmitError.server(error.localizedDescription)
        }
    }
}
