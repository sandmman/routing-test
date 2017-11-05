import Models
import Foundation

print("Client running...")



func abc(id: String...) {

}

abc(id: "", "", "")

//let pattern1 = "/:([^/]*)/"
//let pattern1 = "/:([^/]*)(/|\\z)"
let pattern1 = "/:([^/]*)(?:/|\\z)"
let str = "/users/:id1/orders/:id2/other/:id3/qwdjqwkl/:id4"
//let str = "/users/:id1/orders"
guard let regex = try? NSRegularExpression(pattern: pattern1, options: []) else {
    exit(1)
}
let matches = regex.matches(in: str, options: [], range: NSRange(location: 0, length: str.characters.count))
print("matches: \(matches.count)")

let d = matches.map({ (value: NSTextCheckingResult) -> String in
    let range = value.range(at: 1)
   // let swiftRange = Range(range, in: str)
   // let s = str.substring(with: swiftRange!)
    //
    let start = str.index(str.startIndex, offsetBy: range.location)
    let end = str.index(start, offsetBy: range.length)
    let t = str[start..<end]
    print("and t is: \(t)")
    //
    
    return String(t)
})
print("d: \(d)")




for match in matches {
    for n in 0..<match.numberOfRanges {
        let range = match.range(at: n)
        print("range: \(range)")
        let start = str.index(str.startIndex, offsetBy: range.location)
        print("start: \(start)")
        let end = str.index(start, offsetBy: range.length)
        print("end: \(end)")
        let swiftRange = Range(range, in: str)
        let s = str.substring(with: swiftRange!)
        print("s = \(s)")

        //let r = str.startIndex.advanced(by: range.location) ..<
        //    str.startIndex.advanced(by: range.location+range.length)
        // sstr.substring(with: r)
    }
}
let nsString = NSString(string: str)
let results = matches.map { nsString.substring(with: $0.range) }
print("results: \(results)")

//  let start = string.index(string.startIndex, offsetBy: range.location)
//     let end = string.index(start, offsetBy: range.length)
//     return start..<end