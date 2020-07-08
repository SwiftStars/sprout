//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation
import ArgumentParser
import Files
import ShellOut

struct SproutUninstall: ParsableCommand, SPRTCheckFile {

    static var configuration: CommandConfiguration = .init(
        commandName: "uninstall",
        abstract: "Uninstall a package."
    )

    @Argument(help: "The name of the package to uninstall.")
    var name: String

    @Flag(help: "Print extra output.")
    var verbose: Bool = false

    func run() throws {
        printV("Finding package to uninstall.")
        let packagePath: Folder
        do {
            packagePath = try .init(path: "~/.sprout/repos/\(name)")
        } catch let error as LocationError {
            print("Unable to find a package named \"\(name)\".")
            print("Check the name and try again.")
            print(error.description)
            Foundation.exit(1)
        }
        printV("Found package.")
        printV("Obtaining SproutFile for uninstall directions.")
        let sproutFileFile: File
        do {
            sproutFileFile = try packagePath.file(at: "SproutFile")
        } catch let error as LocationError {
            print("Unable to obtain package SproutFile.")
            print(error.description)
            Foundation.exit(1)
        }
        printV("Obtained SproutFile.")
        printV("Getting details of package.")
        let sproutFile: SproutFile
        do {
            let SproutFileArray = try sproutFileFile.readAsString().split(separator: "\n")
            sproutFile = checkFile(SproutFileArray, ifViolates: { (_, _) in
                print("Unable to find valid package details.")
                Foundation.exit(1)
            })
        } catch let error as ReadError {
            print("Unable to read and decode SproutFile")
            print(error.description)
            Foundation.exit(1)
        }
        printV("Obtained package details.")
        print("Starting uninstall of \(name).")
        print("Warning: Support for uninstall actions is not yet implemented.")
        print("Sprout will infer actions based on install actions.")
        print("There may be fragments of \(name) left over.")
        try sproutFile.installActions.forEach { (action, index) in
            if case .shell(_) = action {
                printV("Action \(index) will be ignored since it is a shell action.")
            } else if case .installApp(_, let location) = action {
                printV("Uninstalling app at \(location)...")
                do {
                    let app = try File(path: location)
                    try app.delete()
                } catch let error as LocationError {
                    print("Unable to find or delete an app installed.")
                    print("The app was installed to \"\(location)\".")
                    print(error.description)
                }
            } else if case .installBin(let from, let location) = action {
                printV("Uninstalling cli from \"\(from)\" at \"\(location)\".")
                var cliName: String
                do {
                    cliName = try packagePath.file(at: from).name
                } catch {
                    printV("Unable to find built cli, so parsing string for name.")
                    var genName = "bad-sprout"
                    from.split(separator: "/").forEach { (string) in
                        genName = string
                    }
                    cliName = genName
                }
                do {
                    let file = try File(path: "~/.sprout/bin/\(cliName)")
                    try file.delete()
                } catch let error as LocationError {
                    print("Unable to find or delete a cli installed.")
                    print("The cli was installed to \"~/.sprout/bin/\(cliName)\",")
                    print("and symlinked to \"\(location)\".")
                    print(error.description)
                }
                do {
                    let file = try File(path: location)
                    try file.delete()
                } catch let filesError as LocationError {
                    printV("Unable to find or delete a symlink cli installed.")
                    printV("Trying again with rm.")
                    do {
                        try shellOut(to: "rm \"\(location)\"")
                    } catch let shellError as ShellOutError {
                        print("Unable to find or delete a symlink cli installed.")
                        print("The cli was installed to \"~/.sprout/bin/\(cliName)\",")
                        print("and symlinked to \"\(location)\".")
                        print(filesError.description)
                        print(shellError.description)
                    }
                }
            }
        }
        printV("Deleting package repo folder.")
        do {
            try packagePath.delete()
        } catch let error as LocationError {
            print("Could not delete repo folder at \"~/.sprout/repos/\(name)\"")
            print(error.description)
        }
        print("Finished uninstall of \(name).")
    }
}
