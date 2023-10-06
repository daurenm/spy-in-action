//
//  SpyInActionTests.swift
//  SpyInActionTests
//
//  Created by Dauren Muratov on 05.10.2023.
//

import XCTest
import SpyInAction

class RemotePostsLoader: PostsLoader {
    let client: HTTPClient
    let url: URL
    
    enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (PostsLoader.Result) -> Void) {
        client.get(from: url) { result in
            switch result {
                case .success:
                    completion(.failure(Error.invalidData))
                case .failure:
                    completion(.failure(Error.connectivity))
            }
        }
    }
}

final class SpyInActionTests: XCTestCase {

    func test_init_doesNotRequestDataFromClient() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.messages.isEmpty)
    }
    
    func test_load_requestsDataFromGivenURL() {
        let url = URL(string: "http://a-url.com")!
        let (sut, client) = makeSUT(url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.messages.map { $0.url }, [url])
    }

    func test_load_deliversConnectivityErrorOnClientError() {
        let clientError = NSError(domain: "any", code: 0)
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(RemotePostsLoader.Error.connectivity)) {
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversInvalidDataOnNon200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 400, 501]
        let emptyData = Data()
        
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWith: .failure(RemotePostsLoader.Error.invalidData)) {
                client.complete(withStatusCode: code, data: emptyData, at: index)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(url: URL = URL(string: "http://any-url.com")!) -> (sut: RemotePostsLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemotePostsLoader(client: client, url: url)
        trackForMemoryLeaks(client)
        trackForMemoryLeaks(sut)
        return (sut, client)
    }
    
    private func trackForMemoryLeaks(_ instance: AnyObject) {
        addTeardownBlock { [weak instance] in
            XCTAssertNil(instance, "Instance should have been deallocated. Potential Memory Leak")
        }
    }
    
    private func expect(
        _ sut: RemotePostsLoader,
        toCompleteWith expectedResult: PostsLoader.Result,
        when action: () -> Void
    ) {
        let exp = expectation(description: "Wait for load")
        sut.load { receivedResult in
            switch (receivedResult, expectedResult) {
                case let (.success(receivedItems), .success(expectedItems)):
                    XCTAssertEqual(receivedItems, expectedItems)
                case let (.failure(receivedError as RemotePostsLoader.Error), .failure(expectedError as RemotePostsLoader.Error)):
                    XCTAssertEqual(receivedError, expectedError)
                default:
                    XCTFail("Expected \(expectedResult), got \(receivedResult) instead")
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }

    private class HTTPClientSpy: HTTPClient {
        private(set) var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
        
        var requestedURLs: [URL] {
            messages.map { $0.url }
        }
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(
                url: requestedURLs[index],
                statusCode: code,
                httpVersion: nil,
                headerFields: nil)!
            messages[index].completion(.success((data, response)))
        }
    }
}
