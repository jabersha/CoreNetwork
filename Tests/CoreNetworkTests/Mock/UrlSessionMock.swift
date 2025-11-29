//
//  UrlSessionMock.swift
//  CoreNetwork
//
//  Created by Jabinho on 29/11/25.
//

import Foundation
import CoreNetwork

final class URLSessionMock: URLSessionProtocol {

    var nextData: Data?
    var nextResponse: URLResponse?
    var nextError: Error?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {

        if let error = nextError {
            throw error
        }

        let data = nextData ?? Data()
        let response = nextResponse ?? URLResponse()

        return (data, response)
    }
}
