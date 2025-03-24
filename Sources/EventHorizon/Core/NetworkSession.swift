//
//  NetworkSession.swift
//  EventHorizon
//

import Foundation

/// A concrete implementation of `NetworkSessionProtocol` that wraps `URLSession`.
///
/// This class provides a default implementation for performing network requests using `URLSession`.
/// It allows dependency injection of a custom `URLSession` instance for better testability.
public final class NetworkSession: NetworkSessionProtocol {

    /// The underlying `URLSession` used for network requests.
    private let session: URLSession

    /// Creates a new network session with an optional custom `URLSession` instance.
    ///
    /// - Parameter session: The `URLSession` instance to use. Defaults to `.shared`.
    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Performs a network request and returns the response data.
    ///
    /// - Parameter request: The `URLRequest` to be executed.
    /// - Returns: A tuple containing the response `Data` and the associated `URLResponse`.
    /// - Throws: An error if the network request fails.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return try await session.data(for: request)
    }
}
