//
//  AppleSignInController.swift
//  Snooker
//
//  Created by Tayfun Susamcioglu on 14.06.2026.
//

import AuthenticationServices
import CryptoKit
import UIKit

// MARK: - Apple Sign In Result

/// Everything we need from a successful "Sign in with Apple" handshake.
/// `fullName` / `email` are only populated by Apple on the very first sign-in.
struct AppleSignInResult {
    let idToken: String
    let rawNonce: String
    let fullName: String?
    let email: String?
}

// MARK: - Apple Sign In Controller

/// Wraps the `ASAuthorizationController` boilerplate (secure nonce, request,
/// delegate, presentation anchor) behind a single `start` call with closures.
///
/// Keep a strong reference to the instance until the callback fires — the
/// controller retains itself while the system sheet is on screen.
final class AppleSignInController: NSObject {

    private var onSuccess: ((AppleSignInResult) -> Void)?
    private var onFailure: ((Error) -> Void)?
    private weak var presentationAnchor: UIWindow?

    /// Raw nonce for the in-flight request; hashed copy is sent to Apple.
    private var currentNonce: String?

    /// Self-reference held while the system sheet is presented.
    private var retainedSelf: AppleSignInController?

    /// Starts the native Sign in with Apple flow.
    /// - Parameters:
    ///   - anchor: The window used to present the system sheet.
    func start(
        anchor: UIWindow?,
        onSuccess: @escaping (AppleSignInResult) -> Void,
        onFailure: @escaping (Error) -> Void
    ) {
        self.presentationAnchor = anchor
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.retainedSelf = self

        let nonce = Self.randomNonceString()
        currentNonce = nonce

        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }

    private func finish() {
        onSuccess = nil
        onFailure = nil
        retainedSelf = nil
    }

    // MARK: - Nonce Helpers

    /// Cryptographically secure random string used to prevent replay attacks.
    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length

        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if status != errSecSuccess { continue }
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInController: ASAuthorizationControllerDelegate {

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        defer { finish() }

        guard
            let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
            let rawNonce = currentNonce,
            let tokenData = credential.identityToken,
            let idToken = String(data: tokenData, encoding: .utf8)
        else {
            onFailure?(AppleSignInError.invalidCredential)
            return
        }

        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")

        let result = AppleSignInResult(
            idToken: idToken,
            rawNonce: rawNonce,
            fullName: fullName.isEmpty ? nil : fullName,
            email: credential.email
        )
        onSuccess?(result)
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        onFailure?(error)
        finish()
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor ?? UIWindow()
    }
}

// MARK: - Error

enum AppleSignInError: LocalizedError {
    case invalidCredential

    var errorDescription: String? {
        switch self {
        case .invalidCredential:
            return "Could not read the Apple credential."
        }
    }
}
