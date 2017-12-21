import Foundation
import LoggerAPI
import Extensions
import KituraContracts
import SwiftKuery
import SwiftKueryPostgreSQL

public protocol TableQuery: KituraContracts.Query {
    associatedtype QueryTable: Table
    static var table: QueryTable { get }
    var query: [WhereCondition] { get }
}

public protocol AgnosticTableQuery: KituraContracts.Query {
    static var table: String { get }
}

public protocol DjangoTableQuery: KituraContracts.Query {
    static var table: String { get }
}

// These will have to be Field types. Currently not codable.
public enum WhereCondition {
    
    case equal(Int, String) /// The SQL == operator.
    
    case notEqual(Int, String) /// The SQL != operator.
    
    case greaterThan(Int, String) /// The SQL > operator.
    
    case lessThan(Int, String) /// The SQL < operator.
    /// ...
}

extension WhereCondition: Codable {
    enum CodingError: Error { case decoding(String) }
    enum CodingKeys: String, CodingKey { case equal, notEqual, greaterThan, lessThan }
    
    fileprivate struct Comparison: Codable {
        let int: Int
        let field: String
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case let .equal(int, string)      : try container.encode(Comparison(int: int, field: string), forKey: .equal)
        case let .notEqual(int, string)   : try container.encode(Comparison(int: int, field: string), forKey: .notEqual)
        case let .greaterThan(int, string): try container.encode(Comparison(int: int, field: string), forKey: .greaterThan)
        case let .lessThan(int, string)   : try container.encode(Comparison(int: int, field: string), forKey: .lessThan)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        
        if let comparison = try? values.decode(Comparison.self, forKey: .equal) {
            self = .equal(comparison.int, comparison.field)
            return
        }
        
        if let comparison = try? values.decode(Comparison.self, forKey: .notEqual) {
            self = .notEqual(comparison.int, comparison.field)
            return
        }
        
        if let comparison = try? values.decode(Comparison.self, forKey: .greaterThan) {
            self = .greaterThan(comparison.int, comparison.field)
            return
        }
        
        if let comparison = try? values.decode(Comparison.self, forKey: .lessThan) {
            self = .lessThan(comparison.int, comparison.field)
            return
        }
        throw CodingError.decoding("Decoding Failed. \(dump(values))")
    }
}

/// ORM (Kordata) Placeholder -
public protocol Model: Codable {
    static var tableName: String { get }
}

extension Model {
    // ORM Placeholder
    
    // We'd like the guarantee the same table is being used by params and table query. This can only be done if Model uses an associated type with the actual table class
    public static func findAll<Params: TableQuery>(where params: Params) throws -> [Self] {
        return []
    }
    
    // We'd like the guarantee the same table is being used by params and table query. We can't do this at compile time and
    // even if we could theyre strings, which is iffy to begin with
    public static func findAll<Params: AgnosticTableQuery>(where params: Params) throws -> [Self]{
        return []
    }
}
