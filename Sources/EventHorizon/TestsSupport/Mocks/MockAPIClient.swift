//
//  MockAPIClient.swift
//  EventHorizon
//

import Foundation

public actor MockAPIClient: APIClientProtocol {

    // MARK: - Properties -
    public let interceptors: [NetworkInterceptorProtocol]
    public let session: NetworkSessionProtocol

    public init(
        interceptors: [NetworkInterceptorProtocol] = [MockNetworkInterceptorProtocol()]
    ) {
        self.interceptors = interceptors
        self.session = NetworkSession(
            session: URLSession(configuration: .ephemeral)
        )
    }

    // MARK: - Methods -
    var requestReturnValue: [String: Encodable] = [:]
    var shouldThrowErrorForRequest: Bool = false
    public func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder
    ) async throws -> T {
        if shouldThrowErrorForRequest {
            throw URLError(.badServerResponse)
        }
        guard let encodable = requestReturnValue[endpoint.path] else {
            throw URLError(.badServerResponse)
        }

        if let response = encodable as? T {
            return response
        }

        let data = try JSONEncoder().encode(encodable)
        return try decoder.decode(T.self, from: data)
    }

    var requestVoidReturnValue: [String: Void] = [:]
    var shouldThrowErrorForRequestVoid: Bool = false
    public func request(
        _ endpoint: any APIEndpointProtocol
    ) async throws {
        if shouldThrowErrorForRequestVoid {
            throw URLError(.badServerResponse)
        }
    }

    var requestWithProgressReturnValue: [String: Data] = [:]
    var shouldThrowErrorForRequestWithProgress: Bool = false
    @discardableResult
    public func request(
        _ endpoint: any APIEndpointProtocol,
        progressDelegate: (any UploadProgressDelegateProtocol)?
    ) async throws -> Data? {
        if shouldThrowErrorForRequestWithProgress {
            throw URLError(.badServerResponse)
        }

        guard let encodable = requestWithProgressReturnValue[endpoint.path] else {
            return nil
        }

        return encodable
    }

    public func clearMockResponses() {
        requestReturnValue.removeAll()
        requestWithProgressReturnValue.removeAll()
        requestVoidReturnValue.removeAll()
    }

    public func resetErrorState() {
        shouldThrowErrorForRequest = false
        shouldThrowErrorForRequestWithProgress = false
        shouldThrowErrorForRequestVoid = false
    }
}

// MARK: - Default Implementations -
public extension MockAPIClient {

    func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol
    ) async throws -> T {
        try await request(endpoint, decoder: JSONDecoder())
    }
}
