import Foundation

extension String {
    public func insert(offset: Int) -> String {
        let offset = offset == 1 ? 0 : offset - 2
        if let last = self.last, ["*", "+", "?"].contains(String(last)) {
            let start = self.index(before: self.endIndex)
            let end = self.endIndex
            return self.replacingCharacters(in: start..<end, with: "\(offset)\(last)")
        }
        return self + String(offset)
    }
}
extension String {
    public static var parameter: String {
        return ":string"
    }
}

extension Optional where Wrapped == String {
    public static var parameter: String {
        return ":string?"
    }
}

extension Int {
    public static var parameter: String {
        get {
            return ":int"
        }
    }
}

extension Optional where Wrapped == Int {
    public static var parameter: String {
        return ":string?"
    }
}
extension Array where Element == Int {
    public static var parameter: String {
        get {
            return ":int+"
        }
    }
}

extension Array where Element == String {
    public static var parameter: String {
        get {
            return ":string+"
        }
    }
}
