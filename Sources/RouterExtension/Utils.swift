import Kitura
import Foundation
import Extensions
import Contracts
import LoggerAPI

extension Router {
    func createQuery<Q: Query>(from rawParams: [String : String], queryType: Q.Type) throws -> Q {
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
                    }
                    Log.warning("Could not process query parameter named '\(name)'.")
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
                    }
                    Log.warning("Could not process query parameter named '\(name)'.")
                // Doubles
                case is Double.Type, is Optional<Double>.Type:
                    transformedDictionary[name] = Double(itemValue)
                case is Array<Double>.Type, is Optional<Array<Double>>.Type:
                    if let doubles = itemValue.doubleArray {
                        transformedDictionary[name] = doubles
                    }
                    Log.warning("Could not process query parameter named '\(name)'.")
                default:
                    Log.warning("Could not process query parameter named '\(name)'.")
            }
        }

        Log.verbose("Transformed query parameters: \(transformedDictionary).")
        if transformedDictionary.count != rawParams.count {
            Log.warning("One or more query parameters provided in the request were not processed.")
        }
        let jsonData: Data = try JSONSerialization.data(withJSONObject: transformedDictionary)
        let query: Q = try JSONDecoder().decode(Q.self, from: jsonData)
        Log.verbose("Query instance: \(query)")
        return query
    }

}