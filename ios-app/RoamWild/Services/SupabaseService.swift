//
//  SupabaseService.swift
//  RoamWild
//
//  REST client against the same Supabase project the web POC uses:
//    • Read-only spot fetch (unauthenticated)
//    • Email/password sign in, sign up, sign out
//    • Profile read for the account screen
//

import Foundation

enum SupabaseConfig {
    // Same project / anon key as index.html. Safe to ship — this is the *anon* key.
    static let url = "https://zqkujliskbvexoxtnjxv.supabase.co"
    static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9." +
        "eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpxa3VqbGlza2J2ZXhveHRuanh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYyNjc1ODksImV4cCI6MjA5MTg0MzU4OX0." +
        "m8c50IQBVsPFLOFFRDEbhiZWy6nVGSI0qK-DWhqMmdI"
}

enum SupabaseError: LocalizedError {
    case badURL
    case http(Int, String?)
    case decoding(Error)
    case auth(String)

    var errorDescription: String? {
        switch self {
        case .badURL: return "Invalid Supabase URL."
        case .http(let code, let body):
            if let b = body, !b.isEmpty { return b }
            return "Server returned HTTP \(code)."
        case .decoding(let err): return "Could not read response: \(err.localizedDescription)"
        case .auth(let msg): return msg
        }
    }
}

// MARK: - Auth payloads

struct AuthUser: Codable, Hashable {
    let id: String
    let email: String?
    let userMetadata: [String: MetadataValue]?

    enum CodingKeys: String, CodingKey {
        case id, email
        case userMetadata = "user_metadata"
    }
}

/// Loose wrapper so user_metadata can contain strings or nulls without failing to decode.
enum MetadataValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case bool(Bool)
    case null

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null; return }
        if let s = try? c.decode(String.self) { self = .string(s); return }
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        self = .null
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let s): try c.encode(s)
        case .int(let i): try c.encode(i)
        case .bool(let b): try c.encode(b)
        case .null: try c.encodeNil()
        }
    }
    var stringValue: String? {
        if case .string(let s) = self { return s } else { return nil }
    }
}

struct AuthSession: Codable {
    let accessToken: String
    let refreshToken: String?
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

/// Supabase auth errors come back as `{ "error": "invalid_grant", "error_description": "..." }`
private struct AuthErrorBody: Decodable {
    let error: String?
    let errorDescription: String?
    let msg: String?
    let message: String?
    enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case msg, message
    }
    var text: String {
        errorDescription ?? msg ?? message ?? error ?? "Unknown error"
    }
}

/// Payload passed from AddSpotView to SupabaseService.createSpot.
struct SpotDraft {
    var name: String
    var region: String
    var country: String
    var category: SpotCategory
    var type: SpotType
    var description: String
    var insiderTip: String
    var latitude: Double
    var longitude: Double
    var submittedBy: String?
}

struct Profile: Codable, Hashable {
    let id: String
    let username: String?
    let fullName: String?
    let favouriteActivity: String?

    enum CodingKeys: String, CodingKey {
        case id, username
        case fullName = "full_name"
        case favouriteActivity = "favourite_activity"
    }
}

// MARK: - Service

actor SupabaseService {
    static let shared = SupabaseService()

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: Spots

    /// Loads all approved spots, same filter/order the web POC uses.
    func fetchSpots(limit: Int = 1000) async throws -> [Spot] {
        let path = "/rest/v1/spots?approved=eq.true&order=name&limit=\(limit)"
        let data = try await get(path: path, authToken: nil)
        do {
            let spots = try JSONDecoder().decode([Spot].self, from: data)
            return spots.filter { $0.latitude != 0 && $0.longitude != 0 }
        } catch {
            throw SupabaseError.decoding(error)
        }
    }

    /// Create a new `spots` row (pending review). Requires the user's access token so RLS
    /// can tie the submission back to a profile. Mirrors what the web POC's `+ Add spot`
    /// modal will do once wired up.
    func createSpot(draft: SpotDraft, token: String) async throws -> String? {
        struct Body: Encodable {
            let name: String
            let category: String
            let country: String?
            let region: String?
            let latitude: Double
            let longitude: Double
            let type: String
            let description: String?
            let insider_tip: String?
            let approved: Bool
            let submitted_by: String?
        }
        let body = Body(
            name: draft.name,
            category: draft.category.rawValue,
            country: draft.country.isEmpty ? nil : draft.country,
            region: draft.region.isEmpty ? nil : draft.region,
            latitude: draft.latitude,
            longitude: draft.longitude,
            type: draft.type.rawValue,
            description: draft.description.isEmpty ? nil : draft.description,
            insider_tip: draft.insiderTip.isEmpty ? nil : draft.insiderTip,
            approved: false,
            submitted_by: draft.submittedBy
        )
        let data = try await post(
            path: "/rest/v1/spots",
            body: body,
            authToken: token,
            preferReturn: "representation"
        )
        struct Row: Decodable { let id: String? }
        if let rows = try? JSONDecoder().decode([Row].self, from: data),
           let first = rows.first {
            return first.id
        }
        return nil
    }

    // MARK: Auth

    /// Sign in with email + password. Mirrors `/auth/v1/token?grant_type=password` in auth.html.
    func signIn(email: String, password: String) async throws -> AuthSession {
        struct Body: Encodable { let email: String; let password: String }
        let data = try await post(
            path: "/auth/v1/token?grant_type=password",
            body: Body(email: email, password: password),
            authToken: nil
        )
        do {
            return try JSONDecoder().decode(AuthSession.self, from: data)
        } catch {
            throw SupabaseError.decoding(error)
        }
    }

    /// Sign up with email + password. Mirrors `/auth/v1/signup` in auth.html.
    /// Supabase responds either with a session (auto-confirm on) or with a user and no tokens
    /// (email-confirm required). Both shapes are handled.
    func signUp(email: String, password: String, username: String, favouriteActivity: String) async throws -> AuthSession? {
        struct Meta: Encodable { let username: String; let favourite_activity: String }
        struct Body: Encodable { let email: String; let password: String; let data: Meta }

        let raw = try await post(
            path: "/auth/v1/signup",
            body: Body(email: email, password: password,
                       data: Meta(username: username, favourite_activity: favouriteActivity)),
            authToken: nil
        )

        // Try the "session" shape first.
        if let session = try? JSONDecoder().decode(AuthSession.self, from: raw),
           !session.accessToken.isEmpty {
            try? await upsertProfile(userId: session.user.id,
                                     username: username,
                                     favouriteActivity: favouriteActivity,
                                     token: session.accessToken)
            return session
        }

        // Otherwise fall through: account created but email confirmation required.
        if let _ = try? JSONDecoder().decode(AuthUser.self, from: raw) {
            return nil
        }

        // If the body was an error object, surface it.
        if let err = try? JSONDecoder().decode(AuthErrorBody.self, from: raw) {
            throw SupabaseError.auth(err.text)
        }

        throw SupabaseError.auth("Unexpected sign up response.")
    }

    /// Invalidate the access token server-side.
    func signOut(token: String) async throws {
        _ = try await post(path: "/auth/v1/logout", body: EmptyBody(), authToken: token)
    }

    /// Send a password-reset email. Supabase emails a recovery link to the user.
    func requestPasswordReset(email: String) async throws {
        struct Body: Encodable { let email: String }
        _ = try await post(path: "/auth/v1/recover", body: Body(email: email), authToken: nil)
    }

    /// Kick off account deletion. Calls a Supabase RPC named `request_account_deletion`
    /// (an edge function / SQL function you deploy with service_role) that schedules
    /// the auth user + their rows for hard-delete within 30 days. On the client we
    /// just fire-and-forget, then sign out.
    ///
    /// Apple guideline 5.1.1(v) requires the deletion to be *initiatable* from the
    /// app; the actual purge can be async on the backend.
    func requestAccountDeletion(token: String) async throws {
        _ = try await post(
            path: "/rest/v1/rpc/request_account_deletion",
            body: EmptyBody(),
            authToken: token
        )
    }

    // MARK: Profile

    /// Fetch the authenticated user's profile row.
    func fetchProfile(userId: String, token: String) async throws -> Profile? {
        let path = "/rest/v1/profiles?id=eq.\(userId)&select=id,username,full_name,favourite_activity&limit=1"
        let data = try await get(path: path, authToken: token)
        let rows = (try? JSONDecoder().decode([Profile].self, from: data)) ?? []
        return rows.first
    }

    /// Create / update the user's profile row after sign up.
    func upsertProfile(userId: String,
                       username: String,
                       favouriteActivity: String,
                       token: String) async throws {
        struct Body: Encodable {
            let id: String
            let username: String
            let full_name: String
            let favourite_activity: String
        }
        _ = try await post(
            path: "/rest/v1/profiles",
            body: Body(id: userId, username: username, full_name: username, favourite_activity: favouriteActivity),
            authToken: token,
            preferReturn: "minimal"
        )
    }

    // MARK: - Transport helpers

    private func get(path: String, authToken: String?) async throws -> Data {
        guard let url = URL(string: SupabaseConfig.url + path) else { throw SupabaseError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        addCommonHeaders(&req, token: authToken)
        return try await send(req)
    }

    private func post<B: Encodable>(path: String,
                                    body: B,
                                    authToken: String?,
                                    preferReturn: String? = nil) async throws -> Data {
        guard let url = URL(string: SupabaseConfig.url + path) else { throw SupabaseError.badURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        addCommonHeaders(&req, token: authToken)
        if let preferReturn { req.setValue("return=\(preferReturn)", forHTTPHeaderField: "Prefer") }
        req.httpBody = try JSONEncoder().encode(body)
        return try await send(req)
    }

    private func addCommonHeaders(_ req: inout URLRequest, token: String?) {
        req.setValue(SupabaseConfig.anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token ?? SupabaseConfig.anonKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func send(_ req: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else { return data }
        if !(200..<300).contains(http.statusCode) {
            // Prefer the human-readable auth error if present.
            if let err = try? JSONDecoder().decode(AuthErrorBody.self, from: data) {
                throw SupabaseError.http(http.statusCode, err.text)
            }
            let text = String(data: data, encoding: .utf8)
            throw SupabaseError.http(http.statusCode, text)
        }
        return data
    }
}

private struct EmptyBody: Encodable {}
