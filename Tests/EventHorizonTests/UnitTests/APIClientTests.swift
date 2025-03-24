//
//  APIClientTests.swift
//  EventHorizonTests
//

import XCTest
@testable import EventHorizon

final class APIClientTests: XCTestCase {

    // MARK: - Properties
    var apiClient: APIClient!

    // MARK: - Setup & Teardown
    override func setUp() async throws {
        try await super.setUp()

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = NetworkSession(
            session: URLSession(configuration: config)
        )

        apiClient = APIClient(
            session: session,
            interceptors: [MockNetworkInterceptorProtocol()]
        )
    }

    override func tearDown() async throws {
        apiClient = nil
        try await super.tearDown()
    }

    // MARK: - Tests
    func test_request_success() async throws {
        let expectedResponse = MockResponse(message: EventHorizonTestsConstants.successMessage)
        let responseData = try JSONEncoder().encode(expectedResponse)

        MockURLProtocol.mockResponse = (
            responseData,
            HTTPURLResponse(url: URL(string: EventHorizonTestsConstants.testURL)!, statusCode: EventHorizonTestsConstants.httpStatusOk, httpVersion: nil, headerFields: nil),
            nil
        )

        let result: MockResponse = try await apiClient.request(MockAPIEndpoint(), decoder: JSONDecoder())

        XCTAssertEqual(result.message, EventHorizonTestsConstants.successMessage)
    }

    func test_request_failure() async {
        MockURLProtocol.mockResponse = (nil, nil, URLError(.badServerResponse))

        await XCTAssertThrowsErrorAsync(
            try await self.apiClient.request(MockAPIEndpoint()) as MockResponse
        ) { error in
            XCTAssertTrue(error is APIClientError, "Expected APIClientError but got \(type(of: error))")
        }
    }

    func test_request_correct_method() async throws {
        let endpoint = MockAPIEndpoint(method: .post)
        let expectedResponse = MockResponse(message: EventHorizonTestsConstants.successMessage)
        let responseData = try JSONEncoder().encode(expectedResponse)

        MockURLProtocol.mockResponse = (
            responseData,
            HTTPURLResponse(url: URL(string: EventHorizonTestsConstants.testURL)!,
                            statusCode: EventHorizonTestsConstants.httpStatusOk,
                            httpVersion: nil,
                            headerFields: nil),
            nil
        )

        let result: MockResponse = try await apiClient.request(endpoint, decoder: JSONDecoder())

        XCTAssertEqual(result.message, EventHorizonTestsConstants.successMessage)
        XCTAssertEqual(endpoint.method, .post)
    }

    // MARK: - Void Request Tests
    func test_request_void_success() async throws {
        MockURLProtocol.mockResponse = (
            nil,
            HTTPURLResponse(url: URL(string: EventHorizonTestsConstants.testURL)!,
                            statusCode: EventHorizonTestsConstants.httpStatusOk,
                            httpVersion: nil,
                            headerFields: nil),
            nil
        )

        do {
            try await apiClient.request(MockAPIEndpoint())
        } catch {
            XCTFail("Expected success but got error: \(error)")
        }
    }

    func test_request_void_failure() async {
        MockURLProtocol.mockResponse = (nil, nil, URLError(.badServerResponse))

        await XCTAssertThrowsErrorAsync(
            try await self.apiClient.request(MockAPIEndpoint())
        ) { error in
            XCTAssertTrue(error is APIClientError, "Expected APIClientError but got \(type(of: error))")
        }
    }

    // MARK: - Progress Request Tests
    func test_request_with_progress_failure() async {
        MockURLProtocol.mockResponse = (nil, nil, URLError(.badServerResponse))

        await XCTAssertThrowsErrorAsync(
            try await self.apiClient
                .request(MockAPIEndpoint(), progressDelegate: nil)
        ) { error in
            XCTAssertTrue(error is APIClientError, "Expected APIClientError but got \(type(of: error))")
        }
    }
}
