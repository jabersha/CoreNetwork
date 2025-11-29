//
//  URLSessionProtocol.swift
//  CoreNetwork
//
//  Created by Jabinho on 29/11/25.
//

import Foundation

public protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
