import Foundation
import LoggerAPI
import Extensions

public protocol Query: Codable {
    init()
    static var dateDecodingFormatter: DateFormatter { get }
}

extension Query {
    public static var dateDecodingFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
}

extension Query {
    public static func create(from rawParams: [String : String]) throws -> Self {        
        var transformedDictionary: [String : Any] = [:]
        let emptyQuery = self.init()
        let queryMirror = Mirror(reflecting: emptyQuery)
        for (name, value) in queryMirror.children {
            guard let name = name else { continue }
            guard let itemValue = rawParams[name] else { continue }
            print("\(name): \(type(of: value)) = '\(value)'")
            let itemType = type(of: value)
            switch itemType {
                // Ints
                case is Int.Type, is Optional<Int>.Type:
                    transformedDictionary[name] = Int(itemValue)
                case is Array<Int>.Type, is Optional<Array<Int>>.Type:
                    if let ints = itemValue.intArray {
                        transformedDictionary[name] = ints
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Strings
                case is String.Type, is Optional<String>.Type:
                    transformedDictionary[name] = itemValue
                case is Array<String>.Type, is Optional<Array<String>>.Type:
                    transformedDictionary[name] = itemValue.stringArray
                // Floats
                case is Float.Type, is Optional<Float>.Type:
                    transformedDictionary[name] = Float(itemValue)
                case is Array<Float>.Type, is Optional<Array<Float>>.Type:
                    if let floats = itemValue.floatArray {
                        transformedDictionary[name] = floats
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Doubles
                case is Double.Type, is Optional<Double>.Type:
                    transformedDictionary[name] = Double(itemValue)
                case is Array<Double>.Type, is Optional<Array<Double>>.Type:
                    if let doubles = itemValue.doubleArray {
                        transformedDictionary[name] = doubles
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Dates
                case is Date.Type, is Optional<Date>.Type:
                    //transformedDictionary[name] = itemValue.date
                    transformedDictionary[name] = itemValue
                    //print("itemValue.date => \(itemValue.date)")
                case is Array<Date>.Type, is Optional<Array<Date>>.Type:
                    transformedDictionary[name] = itemValue.stringArray
                    // if let dates = itemValue.dateArray {
                    //     transformedDictionary[name] = dates
                    // }
                    //Log.warning("Could not process query parameter named '\(name)'.")
                default:
                    Log.warning("Could not process query parameter named '\(name)'.")
            }
        }    

        Log.verbose("Transformed query parameters: \(transformedDictionary).")
        if transformedDictionary.count != rawParams.count {
            Log.warning("One or more query parameters provided in the request were not processed.")
        }
        let jsonData: Data = try JSONSerialization.data(withJSONObject: transformedDictionary)
        let decoder = JSONDecoder()
        //TBD - http://benscheirman.com/2017/06/ultimate-guide-to-json-parsing-with-swift-4/
        decoder.dateDecodingStrategy = .formatted(Self.dateDecodingFormatter)
        //TBD
        //let query: Q = try decoder.decode(Q.self, from: jsonData)
        let query: Self = try decoder.decode(Self.self, from: jsonData)
        // Log.verbose("Query instance: \(query)")
        return query
        //return emptyQuery
        
    }
}

/*
extension Query {
    public func createQuery(from rawParams: [String : String], queryType: Q.Type) throws -> Q {
        var transformedDictionary: [String : Any] = [:]
        let emptyQuery = queryType.init()
        let queryMirror = Mirror(reflecting: emptyQuery)
        for (name, value) in queryMirror.children {
            guard let name = name else { continue }
            guard let itemValue = rawParams[name] else { continue }
            print("\(name): \(type(of: value)) = '\(value)'")
            let itemType = type(of: value)
            switch itemType {
                // Ints
                case is Int.Type, is Optional<Int>.Type:
                    transformedDictionary[name] = Int(itemValue)
                case is Array<Int>.Type, is Optional<Array<Int>>.Type:
                    if let ints = itemValue.intArray {
                        transformedDictionary[name] = ints
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Strings
                case is String.Type, is Optional<String>.Type:
                    transformedDictionary[name] = itemValue
                case is Array<String>.Type, is Optional<Array<String>>.Type:
                    transformedDictionary[name] = itemValue.stringArray
                // Floats
                case is Float.Type, is Optional<Float>.Type:
                    transformedDictionary[name] = Float(itemValue)
                case is Array<Float>.Type, is Optional<Array<Float>>.Type:
                    if let floats = itemValue.floatArray {
                        transformedDictionary[name] = floats
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Doubles
                case is Double.Type, is Optional<Double>.Type:
                    transformedDictionary[name] = Double(itemValue)
                case is Array<Double>.Type, is Optional<Array<Double>>.Type:
                    if let doubles = itemValue.doubleArray {
                        transformedDictionary[name] = doubles
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Dates
                case is Date.Type, is Optional<Date>.Type:
                    //transformedDictionary[name] = itemValue.date
                    transformedDictionary[name] = itemValue
                    //print("itemValue.date => \(itemValue.date)")
                case is Array<Date>.Type, is Optional<Array<Date>>.Type:
                    transformedDictionary[name] = itemValue.stringArray
                    // if let dates = itemValue.dateArray {
                    //     transformedDictionary[name] = dates
                    // }
                    //Log.warning("Could not process query parameter named '\(name)'.")
                default:
                    Log.warning("Could not process query parameter named '\(name)'.")
            }
        }

        Log.verbose("Transformed query parameters: \(transformedDictionary).")
        if transformedDictionary.count != rawParams.count {
            Log.warning("One or more query parameters provided in the request were not processed.")
        }
        let jsonData: Data = try JSONSerialization.data(withJSONObject: transformedDictionary)
        let decoder = JSONDecoder()
        //TBD - http://benscheirman.com/2017/06/ultimate-guide-to-json-parsing-with-swift-4/
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        //TBD
        let query: Q = try decoder.decode(Q.self, from: jsonData)
        // Log.verbose("Query instance: \(query)")
        return query
        //return emptyQuery
    }
}
*/