//
//  MockAPIClient.swift
//  EventHorizon
//

import Foundation

public actor MockAPIClient: @preconcurrency APIClientProtocol {

    // MARK: - Properties -
    public let interceptors: [NetworkInterceptorProtocol]
    public let session: NetworkSessionProtocol
    private var activeRequests: [String: Any] = [:]

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
        decoder: JSONDecoder,
        id: String
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
        let task = Task {
            return try decoder.decode(T.self, from: data)
        }

        // Store the task in activeRequests
        activeRequests[id] = task

        return try await task.value
    }

    var requestVoidReturnValue: [String: Void] = [:]
    var shouldThrowErrorForRequestVoid: Bool = false
    public func request(
        _ endpoint: any APIEndpointProtocol,
        id: String
    ) async throws {
        if shouldThrowErrorForRequestVoid {
            throw URLError(.badServerResponse)
        }
        let task = Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        activeRequests[id] = task
        _ = try await task.value
    }

    var requestWithProgressReturnValue: [String: Data] = [:]
    var shouldThrowErrorForRequestWithProgress: Bool = false
    @discardableResult
    public func request(
        _ endpoint: any APIEndpointProtocol,
        progressDelegate: (any UploadProgressDelegateProtocol)?,
        id: String
    ) async throws -> Data? {
        if shouldThrowErrorForRequestWithProgress {
            throw URLError(.badServerResponse)
        }

        guard let encodable = requestWithProgressReturnValue[endpoint.path] else {
            return nil
        }

        let task = Task {
            return encodable
        }

        // Store the task in activeRequests
        activeRequests[id] = task

        return await task.value
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

    // MARK: - Cancel Methods -
    public func cancelRequest(id: String) {
        // Cancel a specific request by id
        if let task = activeRequests[id] as? Task<Void, Never> {
            task.cancel()
            activeRequests.removeValue(forKey: id)
        }
    }

    public func cancelAllRequests() {
        // Cancel all active requests
        for task in activeRequests.values {
            if let task = task as? Task<Void, Never> {
                task.cancel()
            }
        }
        activeRequests.removeAll()
    }
}
