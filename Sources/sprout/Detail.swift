//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation
import ArgumentParser
import Files

struct SproutDetail: ParsableCommand, SPRTCheckFile {

    static var configuration: CommandConfiguration = .init(
        commandName: "detail",
        abstract: "Get details about a package."
    )

    @Argument(help: "The name of the package to get details from.")
    var name: String

    @Flag(help: "List build and install actions.")
    var listActions: Bool = false

    @Flag(help: "Print extra output (during decoding).")
    var verbose: Bool = false

    func run() throws {
        let repoPath: Folder
        do {
            repoPath = try Folder(path: "~/.sprout/repos")
        } catch {
            print("It looks like you haven't used sprout to install any packages before.")
            print("Please install the package before trying to check details.")
            print("If you want to see a package's details before installing look at the packages README or SproutFile")
            Foundation.exit(1)
        }
        let packagePath: Folder
        do {
            packagePath = try repoPath.subfolder(named: name)
        } catch {
            print("It looks like you haven't installed this package yet.")
            print("Please install the package before trying to check details.")
            print("If you want to see a package's details before installing look at the packages README or SproutFile")
            Foundation.exit(1)
        }
        let SproutFileArray: [String]
        do {
            let sproutFile = try packagePath.file(named: "SproutFile")
            let SproutFileString = try sproutFile.readAsString()
            SproutFileArray = SproutFileString.split(separator: "\n")
        } catch let error as LocationError {
            print("Unable to find SproutFile for package.")
            print(error.description)
            Foundation.exit(1)
        } catch let error as ReadError {
            print("Unable to convert SproutFile to a String.")
            print(error.description)
            Foundation.exit(1)
        }
        let sproutFile = checkFile(SproutFileArray) { (_, _) -> Never in
            print("Unable to fully decode the package's SproutFile.")
            Foundation.exit(1)
        }
        print("Package: \(sproutFile.packageName)")
        if sproutFile.packageDescription != nil {
            print(sproutFile.packageDescription!)
        }
        print("")
        if sproutFile.packageWebpage != nil {
            print("Website: \(sproutFile.packageWebpage!)")
        }
        print("Git Repo: \(sproutFile.packageGitURL)")
        if listActions {
            print("\nBuild actions:")
            sproutFile.buildActions.forEach { (action) in
                switch action {
                case .shell(let cmd):
                    print("shell:      \(cmd)")
                case .installBin(let from, let to):
                    print("bin:  from: \(from)")
                    print("      to:   \(to)")
                    print("INSTALL ACTIONS SHOULD NOT BE IN BUILD ACTIONS")
                case .installApp(let from, let to):
                    print("app:  from: \(from)")
                    print("      to:   \(to)")
                    print("INSTALL ACTIONS SHOULD NOT BE IN BUILD ACTIONS")
                }
            }
            print("\nInstall actions:")
            sproutFile.installActions.forEach { (action) in
                switch action {
                case .shell(let cmd):
                    print("shell:      \(cmd)")
                case .installBin(let from, let to):
                    print("bin:  from: \(from)")
                    print("      to:   \(to)")
                case .installApp(let from, let to):
                    print("app:  from: \(from)")
                    print("      to:   \(to)")
                }
            }
        }
    }

}
