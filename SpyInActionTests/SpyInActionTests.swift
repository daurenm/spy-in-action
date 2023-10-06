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
    }
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (PostsLoader.Result) -> Void) {
        client.get(from: url) { _ in
            completion(.failure(Error.connectivity))
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
        
        let exp = expectation(description: "Wait for load")
        sut.load { result in
            switch result {
                case let .failure(error as RemotePostsLoader.Error):
                    XCTAssertEqual(error, RemotePostsLoader.Error.connectivity)
                case .success, .failure:
                    XCTFail("Expected to fail, got \(result) instead")
            }
            exp.fulfill()
        }
        
        client.complete(with: clientError)
        
        wait(for: [exp], timeout: 1.0)
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
    
    private class HTTPClientSpy: HTTPClient {
        private(set) var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
    }
}
