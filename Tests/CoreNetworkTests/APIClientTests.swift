//
//  APIClientTests.swift
//  CoreNetwork
//
//  Created by Jabinho on 29/11/25.
//

import XCTest
@testable import CoreNetwork

final class APIClientTests: XCTestCase {

    struct MockResponse: Codable, Equatable {
        let message: String
    }

    func test_apiClient_success() async throws {

        let session = URLSessionMock()
        let builder = RequestBuilderMock()

        // Prepare mocked response
        let expected = MockResponse(message: "Hello!")
        session.nextData = try JSONEncoder().encode(expected)
        session.nextResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: session,
            requestBuilder: builder
        )

        let result: MockResponse = try await client.request(
            Endpoint(path: "hello")
        )

        XCTAssertEqual(result, expected)
    }
    
    func test_apiClient_httpError() async {

        let session = URLSessionMock()
        let builder = RequestBuilderMock()

        session.nextData = Data()
        session.nextResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        let client = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: session,
            requestBuilder: builder
        )

        do {
            let _: MockResponse = try await client.request(Endpoint(path: "fail"))
            XCTFail("Expected error but got success")
        } catch let APIError.serverError(statusCode, _) {
            XCTAssertEqual(statusCode, 500)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func test_apiClient_decodingError() async {

        let session = URLSessionMock()
        let builder = RequestBuilderMock()

        // Provide invalid JSON
        session.nextData = "not-json".data(using: .utf8)
        session.nextResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: session,
            requestBuilder: builder
        )

        do {
            let _: MockResponse = try await client.request(Endpoint(path: "bad-json"))
            XCTFail("Expected decodingError but got success")
        } catch APIError.decodingError {
            XCTAssertTrue(true)
        } catch {
            XCTFail("Wrong error type")
        }
    }
    
    func test_apiClient_usesCorrectBuilder() async throws {

        let session = URLSessionMock()
        let builder = RequestBuilderMock()

        session.nextData = try JSONEncoder().encode(["message": "hello"])
        session.nextResponse = HTTPURLResponse(
            url: URL(string: "https://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        let client = APIClient(
            baseURL: URL(string: "https://api.test.com")!,
            session: session,
            requestBuilder: builder
        )

        let _: MockResponse = try await client.request(Endpoint(path: "test"))

        XCTAssertEqual(builder.lastEndpoint?.path, "test")
        XCTAssertEqual(builder.lastBaseURL?.absoluteString, "https://api.test.com")
    }


}
