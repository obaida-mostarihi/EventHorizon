import Foundation

// TOOD: Inject logger
public final class APIClient: APIClientProtocol {

    // MARK: - Properties -
    public let session: NetworkSessionProtocol
    public let interceptors: [any NetworkInterceptorProtocol]
    private let taskManager: APIClientTaskManagerProtocol

    // MARK: - Initialization -
    public init(
        session: NetworkSessionProtocol = NetworkSession(),
        interceptors: [any NetworkInterceptorProtocol] = [],
        taskManager: APIClientTaskManagerProtocol = APIClientTaskManager.shared
    ) {
        self.session = session
        self.interceptors = interceptors
        self.taskManager = taskManager
    }

    // MARK: - Methods -
    public func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder = JSONDecoder(),
        id: String
    ) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

        guard !(taskManager.isTaskInProgress(id) || taskManager.isTaskQueued(id)) else {
            throw APIClientError.taskInProgress
        }
        guard !taskManager.isTaskFinished(id) else {
            throw APIClientError.taskFinished
        }
        guard !taskManager.isTaskCanceled(id) else {
            throw APIClientError.taskCanceled
        }

        let task = Task {
            let data = try await performRequest(request)
            return try decoder.decode(T.self, from: data)
        }

        taskManager.addTask(task, for: id)

        defer {
            taskManager.setTaskStatus(
                for: id,
                status: .finished
            )
        }

        return try await task.value
    }

    public func request(
        _ endpoint: any APIEndpointProtocol,
        id: String
    ) async throws {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

        guard !(taskManager.isTaskInProgress(id) || taskManager.isTaskQueued(id)) else {
            throw APIClientError.taskInProgress
        }
        guard !taskManager.isTaskFinished(id) else {
            throw APIClientError.taskFinished
        }
        guard !taskManager.isTaskCanceled(id) else {
            throw APIClientError.taskCanceled
        }

        let task = Task {
            try await performRequest(request)
        }

        taskManager.addTask(task, for: id)

        defer {
            taskManager.setTaskStatus(
                for: id,
                status: .finished
            )
        }

        _ = try await task.value
    }

    @discardableResult
    public func request(
        _ endpoint: any APIEndpointProtocol,
        progressDelegate: (any UploadProgressDelegateProtocol)?,
        id: String
    ) async throws -> Data? {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.urlRequestIsEmpty
        }
        guard !taskManager.isTaskFinished(id) else {
            throw APIClientError.taskFinished
        }
        guard !taskManager.isTaskCanceled(id) else {
            throw APIClientError.taskCanceled
        }
        guard !(taskManager.isTaskInProgress(id) || taskManager.isTaskQueued(id)) else {
            throw APIClientError.taskInProgress
        }

        let task = Task {
            let data = try await performRequest(request, progressDelegate: progressDelegate)
            return data
        }
        taskManager.addTask(task, for: id)

        defer {
            taskManager.setTaskStatus(
                for: id,
                status: .finished
            )
        }

        return try await task.value
    }

    public func cancelRequest(id: String) {
        taskManager.cancelTask(for: id)
    }

    public func cancelAllRequests() {
        taskManager.cancelAllTasks()
    }
}

// MARK: - Private extensions -
private extension APIClient {

    @discardableResult
    private func performRequest(
        _ request: URLRequest,
        progressDelegate: (any UploadProgressDelegateProtocol)? = nil
    ) async throws -> Data {
        var mutableRequest = request

        // Apply request interceptors
        for interceptor in interceptors {
            mutableRequest = interceptor.intercept(request: mutableRequest)
        }

        // If a progress delegate is provided, create a new session instance.
        let sessionToUse: NetworkSessionProtocol = {
            if let progressDelegate {
                return NetworkSession(session: URLSession(configuration: .default, delegate: progressDelegate, delegateQueue: nil))
            } else {
                return session
            }
        }()

        do {
            let (data, response) = try await sessionToUse.data(for: mutableRequest)

            // Apply response interceptors
            var modifiedData = data
            var modifiedResponse = response
            for interceptor in interceptors {
                let result = interceptor.intercept(response: modifiedResponse, data: modifiedData)
                modifiedResponse = result.0 ?? modifiedResponse
                modifiedData = result.1 ?? modifiedData
            }

            guard let httpResponse = modifiedResponse as? HTTPURLResponse else {
                throw APIClientError.invalidResponse(modifiedData)
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw APIClientError.statusCode(httpResponse.statusCode)
            }

            return modifiedData
        } catch {
            if let urlError = error as? URLError {
                throw APIClientError.networkError(urlError)
            } else {
                throw APIClientError.requestFailed(error)
            }
        }
    }
}

// MARK: - Log extension -
private extension APIClient {
    private func log(_ string: String) {
        #if DEBUG
        print(string)
        #endif
    }
}

