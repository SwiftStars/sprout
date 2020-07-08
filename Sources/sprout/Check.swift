//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation
import ArgumentParser
import Files
import StdLibX

struct SproutCheck: ParsableCommand, SPRTVerbose, SPRTCheckFile {

    static var configuration: CommandConfiguration = .init(
        commandName: "check",
        abstract: "Validate a SproutFile and report errors."
    )

    @Flag(help: "Print extra output.")
    var verbose: Bool = false

    @Option(help: "The location of the SproutFile")
    var location: String = "SproutFile"

    @Flag(name: .long, help: "Print the SproutFile class after successful check.")
    var printSproutFile: Bool = false

    @Flag(name: .long, help: "Use several status prompts to show status.")
    var checkPrompts: Bool = false

    func run() throws {
        var sproutFile: File?
        if checkPrompts { _ = prompt("Ready to Start? ") }
        printV("Finding SproutFile...")
        do {
            sproutFile = try File(path: location)
            do {
                let SproutFileArray = try sproutFile!.readAsString().split(separator: "\n")
                printV("Found SproutFile...")
                if checkPrompts { _ = prompt("Ready to check? ") }
                printV("Checking SproutFile...")
                let sproutFileClass = checkFile(SproutFileArray) { (violations, _) in
                    if violations.count > 1 {
                        print("This SproutFile does not pass checks.")
                        print("Please include \(violations.orSplit()) in your SproutFile.")
                    } else {
                        print("This SproutFile does not pass checks.")
                        print("Please include \(violations[0]) in your SproutFile.")
                    }
                    print("Please fix these problems before releasing/updating your package.")
                    Foundation.exit(1)
                }
                print("SproutFile passed checks.")
                if printSproutFile { print(sproutFileClass) }
            } catch {
                print("Unable to convert SproutFile to text.")
            }
        } catch {
            print("Unable to find SproutFile.")
            if location == "SproutFile" {
                print("Try adding the argument --location to this command, then drag your SproutFile into your file")
            } else {
                print("Check the path to your SproutFile and try again.")
            }
            Foundation.exit(404)
        }
    }
}
