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

    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }

    public var dateArray: [Date]? {
        let strs: [String] = self.components(separatedBy: ",")
        let dates: [Date] = strs.map { dateFormatter.date(from: $0) }.filter { $0 != nil }.map { $0! }
        if dates.count == strs.count {
            return dates
        }
        return nil
    }

    public var date: Date? {

        let date = dateFormatter.date(from: self)
        print("date => \(date)")
        print("me => \(self)")
        return date
    }

    public func codable<T: Codable>(_ type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        let obj: T? = try? JSONDecoder().decode(type, from: data)
        return obj
     }

}
