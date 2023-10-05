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
    
    init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    func load(completion: @escaping (PostsLoader.Result) -> Void) {
        client.get(from: url) { _ in }
    }
}

final class SpyInActionTests: XCTestCase {

    func test_init_doesNotRequestDataFromClient() {
        let url = URL(string: "http://a-url.com")!
        let client = HTTPClientSpy()
        _ = RemotePostsLoader(client: client, url: url)
        
        XCTAssertTrue(client.messages.isEmpty)
    }
    
    func test_load_requestsDataFromGivenURL() {
        let url = URL(string: "http://a-url.com")!
        let client = HTTPClientSpy()
        let sut = RemotePostsLoader(client: client, url: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.messages.map { $0.url }, [url])
    }
    
    // MARK: - Helpers
    
    private class HTTPClientSpy: HTTPClient {
        private(set) var messages = [(url: URL, completion: (HTTPClient.Result) -> Void)]()
    
        func get(from url: URL, completion: @escaping (HTTPClient.Result) -> Void) {
            messages.append((url, completion))
        }
    }
}
