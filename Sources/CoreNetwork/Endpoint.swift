//
//  Endpoint.swift
//  CoreNetwork
//
//  Created by Jabinho on 26/11/25.
//

import Foundation

public struct Endpoint {
    public let path: String
    public let method: HTTPMethod
    public let query: [String: String]?
    public let body: Encodable?
    public let headers: [String: String]?
    public let security: SecurityMode


    public init(
        path: String,
        method: HTTPMethod = .GET,
        query: [String: String]? = nil,
        body: Encodable? = nil,
        headers: [String: String]? = nil,
        security: SecurityMode = .basic

    ) {
        self.path = path
        self.method = method
        self.query = query
        self.body = body
        self.headers = headers
        self.security = security
    }
}
