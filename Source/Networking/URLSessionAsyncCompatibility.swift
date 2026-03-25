//
//  URLSessionAsyncCompatibility.swift
//  Based on AsyncCompatibilityKit's URLSession+Async.swift which is
//  Copyright (c) John Sundell 2021
//  MIT license, see LICENSE.md file for details
//
//  Change from AsyncCompatibilityKit: Modified the `@available` line to be deprecated in macOS 12 instead of iOS 15.
//

import Foundation

@available(macOS, deprecated: 12.0, message: "AsyncCompatibilityKit is only useful when targeting macOS versions earlier than 12")
extension URLSession {
    /// Start a data task with a URL using async/await.
    /// - parameter url: The URL to send a request to.
    /// - returns: A tuple containing the binary `Data` that was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the data task.
    public func data(from url: URL) async throws -> (Data, URLResponse) {
        try await data(for: URLRequest(url: url))
    }

    /// Start a data task with a `URLRequest` using async/await.
    /// - parameter request: The `URLRequest` that the data task should perform.
    /// - returns: A tuple containing the binary `Data` that was downloaded,
    ///   as well as a `URLResponse` representing the server's response.
    /// - throws: Any error encountered while performing the data task.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        var dataTask: URLSessionDataTask?
        let onCancel = { dataTask?.cancel() }

        return try await withTaskCancellationHandler(
            operation: {
                try await withCheckedThrowingContinuation { continuation in
                    dataTask = self.dataTask(with: request) { data, response, error in
                        guard let data = data, let response = response else {
                            let error = error ?? URLError(.badServerResponse)
                            return continuation.resume(throwing: error)
                        }

                        continuation.resume(returning: (data, response))
                    }

                    dataTask?.resume()
                }
            },
            onCancel: {
                onCancel()
            }
        )
    }
}
