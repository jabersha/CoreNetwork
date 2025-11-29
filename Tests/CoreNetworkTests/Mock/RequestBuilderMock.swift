//
//  RequestBuilderMock.swift
//  CoreNetwork
//
//  Created by Jabinho on 29/11/25.
//

import Foundation
@testable import CoreNetwork

final class RequestBuilderMock: RequestBuilding {

    var lastEndpoint: Endpoint?
    var lastBaseURL: URL?
    var requestToReturn: URLRequest = URLRequest(url: URL(string: "https://test.com")!)

    func baseRequest(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        lastBaseURL = baseURL
        lastEndpoint = endpoint
        return requestToReturn
    }

    func buildRequestHash(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        return requestToReturn
    }

    func buildResquestNonce(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        return requestToReturn
    }

    func buildResquestMiddleware(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        return requestToReturn
    }

    func buildResquestKeyProvider(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        return requestToReturn
    }

    func buildResquestKeyRotation(baseURL: URL, endpoint: Endpoint) throws -> URLRequest {
        return requestToReturn
    }
}
