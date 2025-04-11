//
//  MockAPIClient.swift
//  EventHorizon
//

import Foundation

public actor MockAPIClient: @preconcurrency APIClientProtocol {

    // MARK: - Properties -
    public let interceptors: [NetworkInterceptorProtocol]
    public let session: NetworkSessionProtocol
    private let taskManager: APIClientTaskManagerProtocol
    private let logger: EHLoggerProtocol

    public init(
        interceptors: [NetworkInterceptorProtocol] = [MockNetworkInterceptorProtocol()],
        taskManager: APIClientTaskManagerProtocol = APIClientTaskManager.shared,
        logger: EHLoggerProtocol = DefaultEHLogger()
    ) {
        self.interceptors = interceptors
        self.session = NetworkSession(session: URLSession(configuration: .ephemeral))
        self.taskManager = taskManager
        self.logger = logger
    }

    // MARK: - Methods -
    var requestReturnValue: [String: Encodable] = [:]
    var shouldThrowErrorForRequest: Bool = false
    public func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder,
        id: String
    ) async throws -> T {
        guard !(taskManager.isTaskInProgress(id) || taskManager.isTaskQueued(id)) else {
            throw APIClientError.taskInProgress
        }
        guard !taskManager.isTaskFinished(id) else {
            throw APIClientError.taskFinished
        }
        guard !taskManager.isTaskCanceled(id) else {
            throw APIClientError.taskCanceled
        }

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

        taskManager.addTask(task, for: id)

        defer {
            taskManager.setTaskStatus(for: id, status: .finished)
        }

        return try await task.value
    }

    var requestVoidReturnValue: [String: Void] = [:]
    var shouldThrowErrorForRequestVoid: Bool = false
    public func request(
        _ endpoint: any APIEndpointProtocol,
        id: String
    ) async throws {
        guard !(taskManager.isTaskInProgress(id) || taskManager.isTaskQueued(id)) else {
            throw APIClientError.taskInProgress
        }
        guard !taskManager.isTaskFinished(id) else {
            throw APIClientError.taskFinished
        }
        guard !taskManager.isTaskCanceled(id) else {
            throw APIClientError.taskCanceled
        }

        if shouldThrowErrorForRequestVoid {
            throw URLError(.badServerResponse)
        }
        let task = Task {
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
        taskManager.addTask(task, for: id)

        defer {
            taskManager.setTaskStatus(for: id, status: .finished)
        }

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
        guard !(taskManager.isTaskInProgress(id) || taskManager.isTaskQueued(id)) else {
            throw APIClientError.taskInProgress
        }
        guard !taskManager.isTaskFinished(id) else {
            throw APIClientError.taskFinished
        }
        guard !taskManager.isTaskCanceled(id) else {
            throw APIClientError.taskCanceled
        }

        if shouldThrowErrorForRequestWithProgress {
            throw URLError(.badServerResponse)
        }

        guard let encodable = requestWithProgressReturnValue[endpoint.path] else {
            return nil
        }

        let task = Task<Data, any Error> {
            return encodable
        }

        taskManager.addTask(task, for: id)

        defer {
            taskManager.setTaskStatus(for: id, status: .finished)
        }

        return try await task.value
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
        taskManager.cancelTask(for: id)
    }

    public func cancelAllRequests() {
        taskManager.cancelAllTasks()
    }
}
