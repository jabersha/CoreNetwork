//
//  RequestBuilder.swift
//  CoreNetwork
//
//  Created by Jabinho on 26/11/25.
//

import Foundation
import CryptoKit
import CoreSecurity

public protocol RequestBuilding {
    func baseRequest(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
    func buildRequestHash(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
    func buildResquestNonce(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
    func buildResquestMiddleware(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
    func buildResquestKeyProvider(baseURL: URL, endpoint: Endpoint) throws -> URLRequest
    func buildResquestKeyRotation(baseURL: URL, endpoint: Endpoint) throws -> URLRequest


}


@available(macOS 10.15, *)
public final class RequestBuilder: RequestBuilding {

    
    private let secretKey: String?
    private let clientKey: String?
    private let bundledKey: String?
    private var allowedTime: Int = 10
    private let securityMiddleware: SecurityMiddleware?
    private let deviceKeyProvider: DeviceKeyProvider?
    private let rotationManager: KeyRotationManager?

    public init(
        secretKey: String? = nil,
        clientKey: String? = nil,
        allowedTime: Int? = nil,
        securityMiddleware: SecurityMiddleware? = nil,
        deviceKeyProvider: DeviceKeyProvider? = nil,
        rotationManager: KeyRotationManager? = nil,
        bundledKey: String? = nil
    ) {
        self.secretKey = secretKey
        self.clientKey = clientKey
        self.securityMiddleware = securityMiddleware
        self.deviceKeyProvider = deviceKeyProvider
        self.rotationManager = rotationManager
        self.bundledKey = bundledKey
        
        if let allowedTime { self.allowedTime = allowedTime }
    }

    // MARK: - Base Request
    public func baseRequest(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(endpoint.path),
            resolvingAgainstBaseURL: false
        ) else { throw APIError.invalidURL }

        if let query = endpoint.query {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        guard let url = components.url else { throw APIError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue

        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        return request
    }

    // MARK: - Hash Builder
    public func buildRequestHash(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        var request = try baseRequest(baseURL: baseURL, endpoint: endpoint)

        let bodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        
        /// hash do body
        let bodyHash = CryptoUtils.sha256(bodyString)

        let timestamp = String(Int(Date().timeIntervalSince1970))
        let message = "\(timestamp)\n\(bodyHash)"

        /// assinatura HMAC(secret + timestamp + hash)
        let signature = CryptoUtils.hmacSHA256(
            message: message,
            key: secretKey ?? ""
        )

        request.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        request.setValue(bodyHash, forHTTPHeaderField: "X-Body-Hash")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")

        return request
    }

    // MARK: - Nonce Builder
    public func buildResquestNonce(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        var request = try baseRequest(baseURL: baseURL, endpoint: endpoint)

        /// Nonce único por requisição
        let nonce = NonceGenerator.generate()
        let timestamp = Int(Date().timeIntervalSince1970)

        let bodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let bodyHash = CryptoUtils.sha256(bodyString)

        let message = "\(timestamp)\n\(nonce)\n\(bodyHash)"

        let signature = CryptoUtils.hmacSHA256(message: message, key: secretKey ?? "")

        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        request.setValue(bodyHash, forHTTPHeaderField: "X-Body-Hash")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue("\(allowedTime)", forHTTPHeaderField: "X-Time-Window")

        return request
    }

    // MARK: - Middleware Builder
    public func buildResquestMiddleware(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        var request = try buildResquestNonce(baseURL: baseURL, endpoint: endpoint)

        /// injeta middleware
        securityMiddleware?.apply(to: &request)
        return request
    }

    // MARK: - Key Provider Builder (Composite Key)
    public func buildResquestKeyProvider(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        var request = try buildResquestNonce(baseURL: baseURL, endpoint: endpoint)

        let deviceKey = deviceKeyProvider?.getOrCreateDeviceKey() ?? ""
        
        /// composite/gera Key
        let finalKey = CompositeKey.generate(clientKey: clientKey ?? "", deviceKey: deviceKey)

        let bodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let bodyHash = CryptoUtils.sha256(bodyString)

        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = NonceGenerator.generate()
        let message = "\(timestamp)\n\(nonce)\n\(bodyHash)"

        let signatureData = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: finalKey)
        let signature = Data(signatureData).map { String(format: "%02x", $0) }.joined()

        securityMiddleware?.apply(to: &request)

        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        request.setValue(bodyHash, forHTTPHeaderField: "X-Body-Hash")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue("\(allowedTime)", forHTTPHeaderField: "X-Time-Window")

        return request
    }

    // MARK: - Key Rotation Builder
    public func buildResquestKeyRotation(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        var request = try buildResquestNonce(baseURL: baseURL, endpoint: endpoint)

        /// composite Key(pega a chave atual)
        let compositeKey = rotationManager?
            .currentCompositeKey(clientFallback: bundledKey ?? "")
            ?? SymmetricKey(data: Data())

        let bodyString = request.httpBody.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        let bodyHash = CryptoUtils.sha256(bodyString)

        let timestamp = Int(Date().timeIntervalSince1970)
        let nonce = NonceGenerator.generate()
        let message = "\(timestamp)\n\(nonce)\n\(bodyHash)"

        let signatureData = HMAC<SHA256>.authenticationCode(for: Data(message.utf8), using: compositeKey)
        let signature = Data(signatureData).map { String(format: "%02x", $0) }.joined()

        securityMiddleware?.apply(to: &request)

        request.setValue("\(timestamp)", forHTTPHeaderField: "X-Timestamp")
        request.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        request.setValue(bodyHash, forHTTPHeaderField: "X-Body-Hash")
        request.setValue(signature, forHTTPHeaderField: "X-Signature")
        request.setValue("\(allowedTime)", forHTTPHeaderField: "X-Time-Window")

        return request
    }
}

