import Foundation

public class Coder {

    public let dateFormatter: DateFormatter

    public init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.timeZone = TimeZone(identifier: "UTC")
        self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    }

    public static func getFieldName(from codingPath: [CodingKey]) -> String {
        return codingPath.flatMap({"\($0)"}).joined(separator: ".")
    }
}
