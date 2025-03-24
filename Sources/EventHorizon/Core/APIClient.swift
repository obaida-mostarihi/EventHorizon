import Foundation

public final class APIClient: APIClientProtocol {

    // MARK: - Properties -
    public let session: NetworkSessionProtocol
    public let interceptors: [any NetworkInterceptor]

    // MARK: - Initialization -
    public init(
        session: NetworkSessionProtocol = NetworkSession(),
        interceptors: [any NetworkInterceptor] = []
    ) {
        self.session = session
        self.interceptors = interceptors
    }

    // MARK: - Methods -
    public func request<T: Decodable & Sendable>(
        _ endpoint: any APIEndpointProtocol,
        decoder: JSONDecoder = JSONDecoder()
    ) async throws -> T {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

        let data = try await performRequest(request)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIClientError.decodingFailed(error)
        }
    }

    public func request(
        _ endpoint: any APIEndpointProtocol
    ) async throws {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.invalidURL
        }

        try await performRequest(request)
    }

    @discardableResult
    public func request(
        _ endpoint: any APIEndpointProtocol,
        progressDelegate: (any UploadProgressDelegateProtocol)?
    ) async throws -> Data? {
        guard let request = endpoint.urlRequest else {
            throw APIClientError.urlRequestIsEmpty
        }

        do {
            let data = try await performRequest(request, progressDelegate: progressDelegate)
            return data
        } catch {
            throw error
        }
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
