//
//  KueryTypes.swift
//  Kitura-Next
//
//  Created by Aaron Liberatore on 12/21/17.
//

import Foundation

public protocol QueryComparator: Codable {
    associatedtype T: Codable
    var value: T { get }
    init(value: T)
}
extension QueryComparator {
    public init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        self.init(value: try values.decode(T.self))
    }
}
public struct GreaterThan<T: Codable&Comparable>: QueryComparator {
    public var value: T
    public init(value: T) { self.value = value }
    
}
public struct LessThan<T: Codable&Comparable>: QueryComparator {
    public var value: T
    public init(value: T) { self.value = value }
}
