//
//  KueryTypes.swift
//  Kitura-Next
//
//  Created by Aaron Liberatore on 12/21/17.
//

import Foundation

public protocol QueryComparator: Codable {
    var value: Int { get }
    init(value: Int)
}
extension QueryComparator {
    public init(from decoder: Decoder) throws {
        var values = try decoder.unkeyedContainer()
        self.init(value: try values.decode(Int.self))
    }
}
public struct GreaterThan: QueryComparator {
    public var value: Int
    public init(value: Int) { self.value = value }
    
}
public struct LessThan: QueryComparator {
    public var value: Int
    public init(value: Int) { self.value = value }
}
