//
//  APIError.swift
//  CoreNetwork
//
//  Created by Jabinho on 26/11/25.
//

import Foundation

public enum APIError: Error {
    case invalidURL
    case noData
    case decodingError(Error)
    case serverError(statusCode: Int, data: Data?)
    case networkError(Error)
}
