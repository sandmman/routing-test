import Foundation
import LoggerAPI
import Extensions

public protocol Query: Codable {
    init() // unfortunately we need this constructor to exist...
            // swift reflection does not have a mechanism to get the types of the field variables
            // unless you have a concrete instance of the type... :-/
    static var dateDecodingFormatter: DateFormatter { get }
}

// This would be the default date decoding formatter
// Developers can override this default formatter in their
// own extensions, which provides flexibility.
extension Query {
    public static var dateDecodingFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }
}

// This would be the default deserialization logic
// Developers could override this default behavior in their
// own extensions... though ideally, they should just leverage this
// implementation.
// Limitations that exist today with swift and reflection (not yet quite let what you get in Java :-/)
//https://stackoverflow.com/questions/46327302/init-an-object-conforming-to-codable-with-a-dictionary-array/46327303#46327303
//https://makeitnew.io/reflection-in-swift-68a06ba0cf0e
//https://stackoverflow.com/questions/33776699/how-to-get-a-mirror-in-swift-without-creating-an-instance
extension Query {
    public static func create(from rawParams: [String : String]) throws -> Self {        
        var transformedDictionary: [String : Any] = [:]
        let emptyQuery = self.init()
        let queryMirror = Mirror(reflecting: emptyQuery)
        for (name, value) in queryMirror.children {
            guard let name = name else { continue }
            guard let itemValue = rawParams[name] else { continue }
            Log.verbose("\(name): \(type(of: value)) = '\(value)'")
            let itemType = type(of: value)
            switch itemType {
                // Ints
                case is Int.Type, is Optional<Int>.Type:
                    transformedDictionary[name] = itemValue.int
                case is Array<Int>.Type, is Optional<Array<Int>>.Type:
                    if let ints = itemValue.intArray {
                        transformedDictionary[name] = ints
                    } else {
                        Log.warning("Could not process query parameter named '\(name)'.")
                    }
                // Strings
                case is String.Type, is Optional<String>.Type:
                    transformedDictionary[name] = itemValue.string
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
                // Dates (dates must be treated like strings)
                // See http://benscheirman.com/2017/06/ultimate-guide-to-json-parsing-with-swift-4/
                case is Date.Type, is Optional<Date>.Type:
                    transformedDictionary[name] = itemValue
                case is Array<Date>.Type, is Optional<Array<Date>>.Type:
                    transformedDictionary[name] = itemValue.stringArray
                default:
                    Log.warning("Could not process query parameter named '\(name)' (unknown type).")
            }
        }    

        Log.verbose("Transformed query parameters: \(transformedDictionary).")
        if transformedDictionary.count != rawParams.count {
            Log.warning("One or more query parameters provided in the request were not processed.")
        }
        let jsonData: Data = try JSONSerialization.data(withJSONObject: transformedDictionary)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(Self.dateDecodingFormatter)
        let query: Self = try decoder.decode(Self.self, from: jsonData)
        Log.verbose("Query instance: \(query)")
        return query   
    }
}
