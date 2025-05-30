import Foundation

/// A network interceptor that injects custom headers into outgoing requests.
///
/// `HeaderInjectorInterceptor` allows you to specify additional headers that should be included
/// in every network request. This is useful for scenarios such as adding authentication tokens,
/// custom user-agent strings, or any other required headers.
///
/// - Note: This interceptor does not modify the response.
/// - Important: Ensure sensitive headers, such as authentication tokens, are handled securely.
public struct HeaderInjectorInterceptor: NetworkInterceptorProtocol {
    private let headers: [String: String]

    public init(headers: [String: String]) {
        self.headers = headers
    }

    public func intercept(request: URLRequest) -> URLRequest {
        var modifiedRequest = request
        for (key, value) in headers {
            modifiedRequest.addValue(value, forHTTPHeaderField: key)
        }
        return modifiedRequest
    }

    public func intercept(
        response: URLResponse?,
        data: Data?
    ) -> (URLResponse?, Data?) {
        return (response, data)
    }
}
