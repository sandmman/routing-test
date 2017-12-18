/*
 * Copyright IBM Corporation 2017
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import LoggerAPI

extension CharacterSet {
    static let customURLQueryAllowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~=:&")
}

/// Param Encoder
public class ParamEncoder: Encoder {
    
    private var route: String = ""
    
    fileprivate var isOptional = false

    public var codingPath: [CodingKey] = []
    
    public var userInfo: [CodingUserInfoKey: Any] = [:]

    public init() {}

    /// Helper method to extract the field name from a CodingKey array
    public static func getFieldName(from codingPath: [CodingKey]) -> String {
        return codingPath.flatMap({"\($0)"}).joined(separator: ".")
    }
    
    /// Encodes an Encodable object to a String -> String dictionary
    ///
    /// - Parameter _ value: The Encodable object to encode to its Parameter representation
    public func encode<T: Encodable>(_ value: T) throws -> String {
        let fieldName = ParamEncoder.getFieldName(from: codingPath)
        
        Log.verbose("fieldName: \(fieldName), fieldValue: \(value)")
        
        switch value {
        /// Ints
        case _ as String                     : route += "/" + "\(fieldName)/:\(fieldName)"
        case _ as Array<String>              : route += "/" + "\(fieldName)/:\(fieldName)+"
        case _ as Int                        : route += "/" + "\(fieldName)/:\(fieldName)(\\d+)"
        case _ as Array<Int>                 : route += "/" + "\(fieldName)/:\(fieldName)(\\d+)+"
        default:
            if fieldName.isEmpty {
                self.route = ""   // Make encoder instance reusable
                try value.encode(to: self)
            } else {
                do {
                    let jsonData = try JSONEncoder().encode(value)
                    route += String(data: jsonData, encoding: .utf8)!
                } catch let error {
                    throw encodingError(value, underlyingError: error)
                }
            }
        }
        return self.route
    }
    
    public func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
        return KeyedEncodingContainer(KeyedContainer<Key>(encoder: self))
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        return UnkeyedContanier(encoder: self)
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        return UnkeyedContanier(encoder: self)
    }
    
    private func encodingError(_ value: Any, underlyingError: Swift.Error?) -> EncodingError {
        let fieldName = ParamEncoder.getFieldName(from: codingPath)
        let errorCtx = EncodingError.Context(codingPath: codingPath, debugDescription: "Could not process field named '\(fieldName)'.", underlyingError: underlyingError)
        return EncodingError.invalidValue(value, errorCtx)
    }
    
    private struct KeyedContainer<Key: CodingKey>: KeyedEncodingContainerProtocol {
        var encoder: ParamEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
            self.encoder.codingPath.append(key)
            defer { self.encoder.codingPath.removeLast() }
            let _: String = try encoder.encode(value)
        }

        //
        // Custom encode if prsent methods to enable encoding optional values however we want
        //
        
        public mutating func encodeIfPresent(_ value: Int?, forKey key: Key) throws {
            print("encode if present int")
        }
    
        public mutating func encodeIfPresent<T : Encodable>(_ value: T?, forKey key: Key) throws {
            print("encode if present")
        }

        func encodeNil(forKey key: Key) throws {
            print("hello")
        }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
            return encoder.unkeyedContainer()
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func superEncoder(forKey key: Key) -> Encoder {
            return encoder
        }
    }
    
    private struct UnkeyedContanier: UnkeyedEncodingContainer, SingleValueEncodingContainer {
        var encoder: ParamEncoder
        
        var codingPath: [CodingKey] { return [] }
        
        var count: Int { return 0 }
        
        func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
            return encoder.container(keyedBy: keyType)
        }
        
        func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
            return self
        }
        
        func superEncoder() -> Encoder {
            return encoder
        }
        
        func encodeNil() throws {}
        
        func encode<T>(_ value: T) throws where T : Encodable {}
    }
}

