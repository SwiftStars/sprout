//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation

struct TrueURL {
    var url: URL

    var contents: Data? {
        do {
            return try .init(contentsOf: url)
        } catch {
            return nil
        }
    }

    var stringContents: String? {
        do {
            return try .init(contentsOf: url)
        } catch {
            return nil
        }
    }

    /// Generate a TrueURL and throw if not valid.
    /// - Parameter string: The url to generate
    /// - Throws: `TrueURLError`
    init?(nil string: String) {
        let new = URL(string: string)
        if new == nil {
            return nil
        }
        if (try? Data(contentsOf: new!)) == nil {
            return nil
        }
        url = new!
    }

    /// Generate a TrueURL and throw if not valid.
    /// - Parameter string: The url to generate
    /// - Throws: `TrueURLError`
    init(throw string: String) throws {
        let new = URL(string: string)
        if new == nil {
            throw TrueURLError.invalidURL
        }
        if (try? Data(contentsOf: new!)) == nil {
            throw TrueURLError.cannotPing
        }
        url = new!
    }

    init(throw link: URL) throws {
        if (try? Data(contentsOf: link)) == nil {
            throw TrueURLError.cannotPing
        }
        url = link
    }

}

enum TrueURLError: Error {
    case invalidURL
    case cannotPing
}
