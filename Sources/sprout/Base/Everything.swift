//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation

protocol SPRTVerbose {
    
    var verbose: Bool { get set }
    
}

extension SPRTVerbose {
    func printV(_ message: String, _ normal: String? = nil) {
        if verbose {
            print(message)
        }
        else if normal != nil {
            print(normal!)
        }
    }
}

extension Array {
    public func forEach(action: (Element, Int) throws -> Void) rethrows {
        var index = 0
        try forEach { (element) in
            try action(element, index)
            index += 1
        }
    }
}

extension String {
    public func split(separator character: Character) -> [String] {
        let substringArray: [Substring] = self.split(separator: character)
        var stringArray: [String] = []
        substringArray.forEach { (substring) in
            stringArray.append(.init(substring))
        }
        return stringArray
    }
}
