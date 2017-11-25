import Foundation

extension String {
    public static var parameter: String {
        get {
            return ":string"
        }
    }
}

extension Int {
    public static var parameter: String {
        get {
            return ":int"
        }
    }
}

extension String {

    public var int: Int? {
        return Int(self)
    }

    public var uInt: UInt? {
        return UInt(self)
    }

    public var float: Float? {
        return Float(self)
    }

    public var double: Double? {         
        return Double(self)
    }

    public var boolean: Bool? {
        return Bool(self)
    }

    public var string: String {
        get { return self}
    }

    public var intArray: [Int]? {
        let strs: [String] = self.components(separatedBy: ",")
        let ints: [Int] = strs.map { Int($0) }.filter { $0 != nil }.map { $0! }
        if ints.count == strs.count {
            return ints
        }
        return nil
    }

    public var floatArray: [Float]? {
        let strs: [String] = self.components(separatedBy: ",")
        let floats: [Float] = strs.map { Float($0) }.filter { $0 != nil }.map { $0! }
        if floats.count == strs.count {
            return floats
        }
        return nil
    }

    public var doubleArray: [Double]? { 
        let strs: [String] = self.components(separatedBy: ",")
        let doubles: [Double] = strs.map { Double($0) }.filter { $0 != nil }.map { $0! }
        if doubles.count == strs.count {
            return doubles
        }
        return nil
    }

    public var stringArray: [String] {
        let strs: [String] = self.components(separatedBy: ",")
        return strs
    }

    public func decodable<T: Decodable>(_ type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        let obj: T? = try? JSONDecoder().decode(type, from: data)
        return obj
     }

}
