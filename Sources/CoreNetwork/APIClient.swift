//
//  APIClient.swift
//  CoreNetwork
//
//  Created by Jabinho on 26/11/25.
//

import Foundation

public protocol APIClientProtocol {
    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T
}

@available(macOS 12.0, *)
public final class APIClient: APIClientProtocol {

    private let baseURL: URL
    private let session: URLSessionProtocol
    private let requestBuilder: RequestBuilding

    public init(
        baseURL: URL,
        session: URLSessionProtocol = URLSession.shared,
        requestBuilder: RequestBuilding
    ) {
        self.baseURL = baseURL
        self.session = session
        self.requestBuilder = requestBuilder
    }

    // MARK: - MAIN REQUEST FLOW
    public func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {

        let request = try buildRequest(for: endpoint)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.noData
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIError.serverError(statusCode: httpResponse.statusCode, data: data)
            }

            return try JSONDecoder().decode(T.self, from: data)

        } catch let apiError as APIError {
            throw apiError

        } catch let decodingError as DecodingError {
            throw APIError.decodingError(decodingError)

        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - REQUEST BUILDER DISPATCH
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {

        switch endpoint.security {

        case .basic:
            return try requestBuilder.baseRequest(baseURL: baseURL, endpoint: endpoint)

        case .hash:
            return try requestBuilder.buildRequestHash(baseURL: baseURL, endpoint: endpoint)

        case .nonce:
            return try requestBuilder.buildResquestNonce(baseURL: baseURL, endpoint: endpoint)

        case .middleware:
            return try requestBuilder.buildResquestMiddleware(baseURL: baseURL, endpoint: endpoint)

        case .keyProvider:
            return try requestBuilder.buildResquestKeyProvider(baseURL: baseURL, endpoint: endpoint)

        case .keyRotation:
            return try requestBuilder.buildResquestKeyRotation(baseURL: baseURL, endpoint: endpoint)
        }
    }
}
