//
//  PostsLoader.swift
//  SpyInAction
//
//  Created by Dauren Muratov on 05.10.2023.
//

import Foundation

public struct Post {
    let title: String
    let description: String
}

public protocol PostsLoader {
    typealias Result = Swift.Result<[Post], Error>
    func load(completion: @escaping (Result) -> Void)
}

public protocol HTTPClient {
    typealias Result = Swift.Result<(Data, HTTPURLResponse), Error>
    func get(from url: URL, completion: @escaping (Result) -> Void)
}

