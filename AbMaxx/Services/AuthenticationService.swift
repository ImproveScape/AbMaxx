import AuthenticationServices
import Foundation
import Security

nonisolated struct SupabaseAuthResponse: Codable, Sendable {
    let access_token: String
    let token_type: String?
    let expires_in: Int?
    let refresh_token: String?
    let user: SupabaseUser?
}

nonisolated struct SupabaseUser: Codable, Sendable {
    let id: String
    let email: String?
}

nonisolated struct SupabaseErrorResponse: Codable, Sendable {
    let error: String?
    let error_description: String?
    let msg: String?
    let message: String?
}

nonisolated struct StoredUserProfile: Codable, Sendable {
    let supabase_user_id: String
    let apple_user_id: String?
    let email: String?
    let display_name: String
    let profile_data: Data?
    let scan_data: Data?
    let is_subscribed: Bool
    let updated_at: String?
}

nonisolated enum AuthProvider: String, Codable, Sendable {
    case apple
    case google
}

@MainActor
class AuthenticationService: NSObject {
    static let shared = AuthenticationService()

    var isAuthenticated: Bool = false
    var isLoading: Bool = false
    var error: String?
    var appleUserId: String?
    var supabaseUserId: String?
    var userEmail: String?
    var authProvider: AuthProvider?

    private var signInContinuation: CheckedContinuation<ASAuthorization, Error>?
    private var webAuthSession: ASWebAuthenticationSession?

    private var supabaseURL: String {
        Config.allValues["EXPO_PUBLIC_MY_SUPABASE_URL"] ?? Config.allValues["EXPO_PUBLIC_SUPABASE_URL"] ?? ""
    }
    private var supabaseKey: String {
        Config.allValues["EXPO_PUBLIC_MY_SUPABASE_ANON_KEY"] ?? Config.allValues["EXPO_PUBLIC_SUPABASE_ANON_KEY"] ?? ""
    }
    private var accessToken: String?
    private var refreshToken: String?
    private var tokenExpiresAt: Date?

    private static let keychainService = "com.abmaxx.auth"

    override init() {
        super.init()
        migrateFromUserDefaultsIfNeeded()
        loadStoredAuth()
    }

    // MARK: - Keychain Helpers

    private static func keychainSave(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var addQuery = query
        addQuery[kSecValueData as String] = data
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(addQuery as CFDictionary, nil)
    }

    private static func keychainLoad(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func keychainDelete(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Migration from UserDefaults

    private func migrateFromUserDefaultsIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: "auth_migrated_to_keychain") else { return }

        if let token = UserDefaults.standard.string(forKey: "auth_access_token"), !token.isEmpty {
            Self.keychainSave(key: "access_token", value: token)
            UserDefaults.standard.removeObject(forKey: "auth_access_token")
        }
        if let refresh = UserDefaults.standard.string(forKey: "auth_refresh_token"), !refresh.isEmpty {
            Self.keychainSave(key: "refresh_token", value: refresh)
            UserDefaults.standard.removeObject(forKey: "auth_refresh_token")
        }

        UserDefaults.standard.set(true, forKey: "auth_migrated_to_keychain")
    }

    // MARK: - Load / Store / Clear

    private func loadStoredAuth() {
        appleUserId = UserDefaults.standard.string(forKey: "auth_apple_user_id")
        supabaseUserId = UserDefaults.standard.string(forKey: "auth_supabase_user_id")
        userEmail = UserDefaults.standard.string(forKey: "auth_email")
        accessToken = Self.keychainLoad(key: "access_token")
        refreshToken = Self.keychainLoad(key: "refresh_token")
        if let providerRaw = UserDefaults.standard.string(forKey: "auth_provider") {
            authProvider = AuthProvider(rawValue: providerRaw)
        }
        if let expiryInterval = UserDefaults.standard.object(forKey: "auth_token_expires_at") as? Double {
            tokenExpiresAt = Date(timeIntervalSince1970: expiryInterval)
        }
        isAuthenticated = (appleUserId != nil || supabaseUserId != nil) && accessToken != nil
    }

    private func storeAuth(appleId: String?, supabaseId: String?, email: String?, token: String?, refresh: String?, provider: AuthProvider, expiresIn: Int? = nil) {
        if let appleId { UserDefaults.standard.set(appleId, forKey: "auth_apple_user_id") }
        if let supabaseId { UserDefaults.standard.set(supabaseId, forKey: "auth_supabase_user_id") }
        if let email { UserDefaults.standard.set(email, forKey: "auth_email") }
        if let token { Self.keychainSave(key: "access_token", value: token) }
        if let refresh { Self.keychainSave(key: "refresh_token", value: refresh) }
        UserDefaults.standard.set(provider.rawValue, forKey: "auth_provider")

        if let expiresIn {
            let expiry = Date().addingTimeInterval(TimeInterval(expiresIn))
            tokenExpiresAt = expiry
            UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: "auth_token_expires_at")
        }

        appleUserId = appleId ?? appleUserId
        supabaseUserId = supabaseId ?? supabaseUserId
        userEmail = email ?? userEmail
        accessToken = token ?? accessToken
        refreshToken = refresh ?? refreshToken
        authProvider = provider
        isAuthenticated = true
    }

    func clearAuth() {
        let udKeys = [
            "auth_apple_user_id", "auth_supabase_user_id", "auth_email",
            "auth_provider", "auth_token_expires_at", "auth_apple_full_name"
        ]
        udKeys.forEach { UserDefaults.standard.removeObject(forKey: $0) }
        Self.keychainDelete(key: "access_token")
        Self.keychainDelete(key: "refresh_token")
        appleUserId = nil
        supabaseUserId = nil
        userEmail = nil
        accessToken = nil
        refreshToken = nil
        authProvider = nil
        tokenExpiresAt = nil
        isAuthenticated = false
    }

    // MARK: - Token Refresh

    func ensureValidToken() async {
        guard isAuthenticated else { return }

        if let expiry = tokenExpiresAt, Date() < expiry.addingTimeInterval(-60) {
            return
        }

        guard let refresh = refreshToken, !refresh.isEmpty else { return }
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else { return }
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=refresh_token") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: String] = ["refresh_token": refresh]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else { return }
        request.httpBody = jsonData

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200,
              let result = try? JSONDecoder().decode(SupabaseAuthResponse.self, from: data) else {
            clearAuth()
            return
        }

        accessToken = result.access_token
        Self.keychainSave(key: "access_token", value: result.access_token)

        if let newRefresh = result.refresh_token {
            refreshToken = newRefresh
            Self.keychainSave(key: "refresh_token", value: newRefresh)
        }

        if let expiresIn = result.expires_in {
            let expiry = Date().addingTimeInterval(TimeInterval(expiresIn))
            tokenExpiresAt = expiry
            UserDefaults.standard.set(expiry.timeIntervalSince1970, forKey: "auth_token_expires_at")
        }
    }

    func getValidAccessToken() async -> String? {
        await ensureValidToken()
        return accessToken
    }

    // MARK: - Sign in with Apple

    func signInWithApple() async -> Bool {
        isLoading = true
        error = nil

        do {
            let authorization = try await performAppleSignIn()

            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                error = "Invalid Apple credential."
                isLoading = false
                return false
            }

            let appleId = credential.user
            let email = credential.email
            let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
                .compactMap { $0 }
                .joined(separator: " ")

            if !fullName.isEmpty {
                UserDefaults.standard.set(fullName, forKey: "auth_apple_full_name")
            }

            guard let identityTokenData = credential.identityToken,
                  let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                error = "Could not retrieve Apple identity token. Please try again."
                isLoading = false
                return false
            }

            let supabaseResult = await authenticateWithSupabase(idToken: identityToken, provider: "apple")

            switch supabaseResult {
            case .success(let authResponse):
                storeAuth(
                    appleId: appleId,
                    supabaseId: authResponse.user?.id,
                    email: email ?? authResponse.user?.email,
                    token: authResponse.access_token,
                    refresh: authResponse.refresh_token,
                    provider: .apple,
                    expiresIn: authResponse.expires_in
                )
                isLoading = false
                return true
            case .failure(let errorMsg):
                error = errorMsg
                isLoading = false
                return false
            }
        } catch {
            let nsError = error as NSError
            if nsError.code == ASAuthorizationError.canceled.rawValue {
                self.error = nil
            } else {
                self.error = "Apple sign in failed: \(nsError.localizedDescription) (code \(nsError.code))"
            }
            isLoading = false
            return false
        }
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async -> Bool {
        isLoading = true
        error = nil

        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            error = "Configuration error. Please contact support."
            isLoading = false
            return false
        }

        let redirectScheme = "abmaxx"
        let redirectURL = "\(redirectScheme)://auth-callback"
        guard let encodedRedirect = redirectURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let authURL = URL(string: "\(supabaseURL)/auth/v1/authorize?provider=google&redirect_to=\(encodedRedirect)") else {
            error = "Invalid configuration."
            isLoading = false
            return false
        }

        do {
            let callbackURL = try await performOAuthWebSession(url: authURL, callbackScheme: redirectScheme)

            let params: [String: String]
            if let fragment = callbackURL.fragment, !fragment.isEmpty {
                params = parseFragment(fragment)
            } else if let query = callbackURL.query, !query.isEmpty {
                params = parseFragment(query)
            } else {
                error = "Sign in failed. No response received."
                isLoading = false
                return false
            }

            if let errorCode = params["error"] {
                let desc = params["error_description"]?.replacingOccurrences(of: "+", with: " ") ?? errorCode
                error = "Sign in failed: \(desc)"
                isLoading = false
                return false
            }

            guard let token = params["access_token"] else {
                error = "Sign in failed. No access token received."
                isLoading = false
                return false
            }

            let refresh = params["refresh_token"]
            let expiresIn = params["expires_in"].flatMap { Int($0) }
            let userInfo = await fetchSupabaseUser(accessToken: token)

            storeAuth(
                appleId: nil,
                supabaseId: userInfo?.id,
                email: userInfo?.email,
                token: token,
                refresh: refresh,
                provider: .google,
                expiresIn: expiresIn
            )

            isLoading = false
            return true
        } catch {
            let nsError = error as NSError
            if nsError.domain == ASWebAuthenticationSessionError.errorDomain,
               nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                self.error = nil
            } else {
                self.error = "Google sign in failed. Please try again."
            }
            isLoading = false
            return false
        }
    }

    // MARK: - Sign Out (server-side)

    func signOut() async {
        if let token = accessToken, !supabaseURL.isEmpty, !supabaseKey.isEmpty,
           let url = URL(string: "\(supabaseURL)/auth/v1/logout") {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            _ = try? await URLSession.shared.data(for: request)
        }
        clearAuth()
    }

    // MARK: - Delete Account (server-side)

    func deleteAccount() async {
        await ensureValidToken()

        if let token = accessToken, let userId = supabaseUserId,
           !supabaseURL.isEmpty, !supabaseKey.isEmpty {
            let encoded = userId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? userId
            if let url = URL(string: "\(supabaseURL)/rest/v1/user_profiles?supabase_user_id=eq.\(encoded)") {
                var request = URLRequest(url: url)
                request.httpMethod = "DELETE"
                request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                _ = try? await URLSession.shared.data(for: request)
            }

            if let url = URL(string: "\(supabaseURL)/auth/v1/logout") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                _ = try? await URLSession.shared.data(for: request)
            }
        }

        clearAuth()
    }

    // MARK: - OAuth Web Session

    private func performOAuthWebSession(url: URL, callbackScheme: String) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackScheme) { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: NSError(domain: "AuthError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No callback received"]))
                }
            }
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            self.webAuthSession = session
            session.start()
        }
    }

    // MARK: - Apple Sign-In Flow

    private func performAppleSignIn() async throws -> ASAuthorization {
        try await withCheckedThrowingContinuation { continuation in
            signInContinuation = continuation
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }

    // MARK: - Supabase Auth

    nonisolated private enum AuthResult: Sendable {
        case success(SupabaseAuthResponse)
        case failure(String)
    }

    private func authenticateWithSupabase(idToken: String, provider: String) async -> AuthResult {
        guard !supabaseURL.isEmpty, !supabaseKey.isEmpty else {
            return .failure("Server configuration missing. Please contact support.")
        }
        guard let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=id_token") else {
            return .failure("Invalid server configuration.")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "provider": provider,
            "id_token": idToken
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            return .failure("Failed to prepare authentication request.")
        }
        request.httpBody = jsonData

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return .failure("No response from server.")
            }

            if http.statusCode == 200 {
                if let authResponse = try? JSONDecoder().decode(SupabaseAuthResponse.self, from: data) {
                    return .success(authResponse)
                }
                return .failure("Unexpected server response.")
            }

            if let errorResponse = try? JSONDecoder().decode(SupabaseErrorResponse.self, from: data) {
                let msg = errorResponse.error_description ?? errorResponse.message ?? errorResponse.msg ?? errorResponse.error ?? "Unknown error"
                return .failure("Authentication failed: \(msg)")
            }

            return .failure("Server error (code \(http.statusCode)). Please try again.")
        } catch {
            return .failure("Network error. Please check your connection and try again.")
        }
    }

    private func fetchSupabaseUser(accessToken: String) async -> SupabaseUser? {
        guard let url = URL(string: "\(supabaseURL)/auth/v1/user") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }
        return try? JSONDecoder().decode(SupabaseUser.self, from: data)
    }

    private func parseFragment(_ fragment: String) -> [String: String] {
        var result: [String: String] = [:]
        for pair in fragment.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1)
            if parts.count == 2 {
                let key = String(parts[0])
                let value = String(parts[1]).removingPercentEncoding ?? String(parts[1])
                result[key] = value
            }
        }
        return result
    }

    // MARK: - Apple Credential Validation

    func validateAppleCredential() async {
        guard let appleId = appleUserId else { return }
        let provider = ASAuthorizationAppleIDProvider()
        do {
            let state = try await provider.credentialState(forUserID: appleId)
            if state == .revoked || state == .notFound {
                await signOut()
            }
        } catch {}
    }

    // MARK: - Cloud Sync

    func saveProfileToCloud(profile: UserProfile, scanResults: [ScanResult]) async {
        guard let supabaseId = supabaseUserId, !supabaseURL.isEmpty, !supabaseKey.isEmpty else { return }

        await ensureValidToken()

        let profileData = try? JSONEncoder().encode(profile)
        let scanData = try? JSONEncoder().encode(scanResults)

        let entry = StoredUserProfile(
            supabase_user_id: supabaseId,
            apple_user_id: appleUserId,
            email: userEmail,
            display_name: profile.displayName,
            profile_data: profileData,
            scan_data: scanData,
            is_subscribed: profile.isSubscribed,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )

        guard let url = URL(string: "\(supabaseURL)/rest/v1/user_profiles") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("resolution=merge-duplicates", forHTTPHeaderField: "Prefer")

        guard let body = try? JSONEncoder().encode(entry) else { return }
        request.httpBody = body

        _ = try? await URLSession.shared.data(for: request)
    }

    func restoreProfileFromCloud() async -> (UserProfile, [ScanResult])? {
        guard let supabaseId = supabaseUserId, !supabaseURL.isEmpty, !supabaseKey.isEmpty else { return nil }

        await ensureValidToken()

        let encoded = supabaseId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? supabaseId
        guard let url = URL(string: "\(supabaseURL)/rest/v1/user_profiles?supabase_user_id=eq.\(encoded)&select=*&limit=1") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(supabaseKey, forHTTPHeaderField: "apikey")
        if let token = accessToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
        }

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

        guard let entries = try? JSONDecoder().decode([StoredUserProfile].self, from: data),
              let entry = entries.first else { return nil }

        var profile: UserProfile?
        var scans: [ScanResult] = []

        if let profileData = entry.profile_data {
            profile = try? JSONDecoder().decode(UserProfile.self, from: profileData)
        }
        if let scanData = entry.scan_data {
            scans = (try? JSONDecoder().decode([ScanResult].self, from: scanData)) ?? []
        }

        if var p = profile {
            p.isSubscribed = entry.is_subscribed
            return (p, scans)
        }
        return nil
    }
}

// MARK: - Presentation Context Providers

extension AuthenticationService: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first ?? ASPresentationAnchor()
        }
    }
}

extension AuthenticationService: ASAuthorizationControllerPresentationContextProviding {
    nonisolated func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            let scenes = UIApplication.shared.connectedScenes
            let windowScene = scenes.first as? UIWindowScene
            return windowScene?.windows.first ?? ASPresentationAnchor()
        }
    }
}

// MARK: - Apple Sign-In Delegate

extension AuthenticationService: ASAuthorizationControllerDelegate {
    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        Task { @MainActor in
            signInContinuation?.resume(returning: authorization)
            signInContinuation = nil
        }
    }

    nonisolated func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        Task { @MainActor in
            signInContinuation?.resume(throwing: error)
            signInContinuation = nil
        }
    }
}
