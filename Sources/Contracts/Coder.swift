import Foundation

protocol Coder {
    static var dateDecodingFormatter: DateFormatter { get }
}

extension Coder {
    public static var dateDecodingFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: "UTC")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return dateFormatter
    }

    public static func getFieldName(from codingPath: [CodingKey]) -> String {
        return codingPath.flatMap({"\($0)"}).joined(separator: ".")
    }
}
