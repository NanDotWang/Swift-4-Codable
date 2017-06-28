
/* Codable = Encodable & Decodable */

/*
 it is actually a union type consisting of Encodable & Decodable

 Almost everything in this playground is coming from this blog:

 "Ultimate Guide to JSON Parsing With Swift 4"
 Reference: http://benscheirman.com/2017/06/ultimate-guide-to-json-parsing-with-swift-4/

 I did some refacotring and made the demo into details, tried to gather everything in this playground.
 */

import Foundation

/* Beer model example */

let beerResponse =
"""
{
    "name": "Endeavor",
    "abv": 8.9,
    "brewery": "Saint Arnold",
    "style": "ipa"
}
"""
struct Beer: Codable {

    enum Style: String, Codable {
        case ipa
        case stout
        case kolsch
    }

    let name: String
    let abv: Double // alcohol_by_volume
    let brewery: String
    let style: Style
}

/* Utility parameters & functions */

var decoder = JSONDecoder()
var encoder = JSONEncoder()

/// Decode from json
func decode<T: Codable>(from json: String) -> T {
    let jsonData = json.data(using: .utf8)!
    return try! decoder.decode(T.self, from: jsonData)
}

/// Encode from object
func encode<T: Codable>(from object: T) -> String {
    let data = try! encoder.encode(object)
    return String(data: data, encoding: .utf8)!
}

/* Basic Usage */

let beer: Beer = decode(from: beerResponse)

let json = encode(from: beer)

/* Handling Dates */

/*
   .iso8601
   .formatted(DateFormatter) – for when you have a non-standard date format string you need to support. Supply your own date formatter instance.
   .custom( (Date, Encoder) throws -> Void ) – for when you have something really custom, you can pass a block here that will encode the date into the provided encoder.
   .millisecondsSince1970 and .secondsSince1970, which aren’t very common in APIs. It is not really recommended to use a format like this as time zone information is completely absent from the encoded representation, which makes it easier for  someone to make the wrong assumption.
*/

struct Foo: Codable {
    let date: Date
}

let foo = Foo(date: Date())
encoder.dateEncodingStrategy = .iso8601
let fooJSON = encode(from: foo)


/* Handling Floats */

/*
Floats and are another area where JSON doesn’t quite match up with Swift’s Float type. What happens if the server returns an invalid “NaN” as a string? What about positive or negative Infinity? These do not map to any specific values in Swift.

The default implementation is .throw, meaning if the decoder encounters these values then an error will be raised, but we can provide a mapping if we need to handle this:
 */

let floatJSON =
"""
{
    "a": "NaN",
    "b": "+Infinity",
    "c": "-Infinity"
}
"""

struct Numbers: Codable {
    let a: Float
    let b: Float
    let c: Float
}

decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "+Infinity", negativeInfinity: "-Infinity", nan: "NaN")

let numbers: Numbers = decode(from: floatJSON)


/* Handling Data */
/*
 Sometimes you’ll find APIs that send small bits of data as base64 encoded strings.

 To handle this automatically, you can give JSONEncoder one of these encoding strategies:

 .base64
 .custom( (Data, Encoder) throws -> Void)
 To decode it, you can provide JSONDecoder with a decoding strategy:

 .base64
 .custom( (Decoder) throws -> Data)
 Obviously .base64 will be the common choice here, but if you need to do anything custom you can use on of the block-based strategies.
 */


/* Wrapper Keys */

let beersJSON =
"""
{
"beers": [
    {
        "name": "Endeavor",
        "abv": 8.9,
        "brewery": "Saint Arnold",
        "style": "ipa"
    },
    {
        "name": "Carlsberg",
        "abv": 9.9,
        "brewery": "Sweden",
        "style": "kolsch"
    }
]
}
"""

/// To represent this in Swift, we can create a new type for this response:
struct BeerList: Codable {
    let beers: [Beer]
}

let beerList: BeerList = decode(from: beersJSON)


/* Root Level Arrays */

let beersArrayJSON =
"""
[
    {
        "name": "Endeavor",
        "abv": 8.9,
        "brewery": "Saint Arnold",
        "style": "ipa"
    },
    {
        "name": "Carlsberg",
        "abv": 9.9,
        "brewery": "Sweden",
        "style": "kolsch"
    }
]
"""
let beers: [Beer] = decode(from: beersArrayJSON)


/* Dealing with Object Wrapping Keys */

let objectWrappingKeys =
"""
[
    {
        "beer": {
            "id": "uuid12459078214",
            "name": "Endeavor",
            "abv": 8.9,
            "brewery": "Saint Arnold",
            "style": "ipa"
        }
    }
]
"""
let beersWrapped: [[String: Beer]] = decode(from: objectWrappingKeys)


/* More Complex Nested Response */
let nestedResponse =
"""
{
    "meta": {
        "page": 1,
        "total_pages": 4,
        "per_page": 10,
        "total_records": 38
    },
    "breweries": [
        {
            "id": 1234,
            "name": "Saint Arnold"
        },
        {
            "id": 52892,
            "name": "Buffalo Bayou"
        }
    ]
}
"""
struct PagedBreweries: Codable {

    struct Meta: Codable {
        let page: Int
        let totalPages: Int
        let perPage: Int
        let totalRecords: Int

        enum CodingKeys: String, CodingKey {
            case page
            case totalPages = "total_pages"
            case perPage = "per_page"
            case totalRecords = "total_records"
        }
    }

    struct Brewery: Codable {
        let id: Int
        let name: String
    }

    let meta: Meta
    let breweries: [Brewery]
}

let pagedBreweries: PagedBreweries = decode(from: nestedResponse)
