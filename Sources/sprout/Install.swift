//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import ArgumentParser
import ShellOut
import StdLibX
import Files

struct SproutInstall: ParsableCommand, SPRTVerbose, SPRTCheckFile {

    static var configuration: CommandConfiguration = .init(
        commandName: "install",
        abstract: "Install a CLI to your computer."
    )

    @Argument(help: "The url of the command to install.")
    var url: String

    @Flag(help: "Print extra output.")
    var verbose: Bool = false

    @Flag(help: "Ignore prompts throughout installation.")
    var skipPrompts: Bool = false

    func run() throws {

        // MARK: Validate URL

        printV("Validating URL, \(url), to make sure it is a valid GitHub repo reference.")
        printV("First checking to see if it is a complete URL on it's own.")
        var useSproutURL = true
        var alreadyCalledSlash = false
        if url.allSatisfy({ (char) -> Bool in
            if char == "/" && !alreadyCalledSlash {
                alreadyCalledSlash = true
                return true
            } else if char == "/" {
                return false
            } else {
                return true
            }
        }) {
            useSproutURL = false
        }
        printV("Now checking to see if the generated url is valid.")
        printV("URL passed validation.")

        // MARK: Obtain SproutFile

        let SproutFileURL = !useSproutURL ? URL(string: "https://raw.githubusercontent.com/\(url)/master/SproutFile")! : URL(string: url)!
        printV(
            "Obtaining SproutFile at \(SproutFileURL)...",
            "Getting package information..."
        )
        printV("Checking to see if SproutFile exists...")
        var SproutFileData = Data(count: 0)
        if let sproutData = try? Data(contentsOf: SproutFileURL) {
            let sproutText = String(data: sproutData, encoding: .utf8)
            if sproutText == "404: Not Found" {
                print("Could not find SproutFile in package.")
                Foundation.exit(1)
            } else {
                SproutFileData = sproutData
            }
        } else { print("Could not find SproutFile in package."); Foundation.exit(1) }
        printV("Converting SproutFile Data into a String Array...")
        var SproutFileArray: [String] = []
        if let sproutText = String(data: SproutFileData, encoding: .utf8) {
            let substringArray = sproutText.split(separator: "\n")
            substringArray.forEach { string in
                SproutFileArray.append(.init(string))
            }
        }
        printV("Obtained SproutFile for package.")
        printV("Decoding SproutFile...")
        let sproutFile = self.checkFile(SproutFileArray) { (violations, sproutf) in
            if violations.count > 1 {
                print("The SproutFile provided by \(sproutf.packageName ?? "this package") does not contain a \(violations.orSplit()).")
            } else {
                print("The SproutFile provided by \(sproutf.packageName ?? "this package") does not contain a \(violations[0]).")
            }
            print("Please contact the owner of this package and tell them to include that information in their SproutFile.")
            Foundation.exit(1)
        }
        printV(
            "Finished decoding SproutFile.",
            "Obtained package information for \(sproutFile.packageName)."
        )

        // MARK: Make Sure Everything is Ready

        var gitHubURL = !useSproutURL ? URL(string: "https://github.com/\(url).git")! : sproutFile.packageGitURL
        printV("Second URL check...")
        if sproutFile.packageGitURL != gitHubURL && !skipPrompts {
            print("The URL used to obtain the the SproutFile and the url inside the SproutFile do not match.")
            let aws = prompt("Would you like to use your URL or the one in the SproutFile: (y/t/CANCEL) ")
            if aws == ("t" || "their" || "theirs") {
                gitHubURL = sproutFile.packageGitURL
            } else if aws != ("y" || "your" || "yours") {
                print("Stoping install...")
                Foundation.exit(1)
            }
        }
        var newUser = false
        printV("URL passed second check.")
        printV("Checking user details...")
        let sproutPath = try? Folder(path: "~/.sprout/")
        if sproutPath == nil {
            print("This appears to be your first time using Sprout. Welcome!")
            printV("Creating Sprout directories...")
            do {
                try Folder.home.createSubfolder(at: ".sprout/repos")
                try Folder.home.createSubfolder(at: ".sprout/bin")
                newUser = true
            } catch {
                print("Could not create a Sprout directory.")
                print("If you can, create a folder at ~/.sprout/repos and ~/.sprout/bin")
                Foundation.exit(1)
            }
        }
        var repoPath = Folder.home
        do {
            repoPath = try Folder(path: "~/.sprout/repos")
        } catch {
            do {
                repoPath = try Folder.home.createSubfolder(at: ".sprout/repos")
                newUser = true
            } catch {
                print("Unable to find or create a directory where repos can be stored.")
                print("If you can, create a folder at ~/.sprout/repos and ~/.sprout/bin if it doesn't already exist.")
                Foundation.exit(1)
            }
        }
        var binPath = Folder.home
        do {
            binPath = try Folder(path: "~/.sprout/bin")
        } catch {
            do {
                binPath = try Folder.home.createSubfolder(at: ".sprout/bin")
                newUser = true
            } catch {
                print("Unable to find or create a directory where repos can be stored.")
                print("If you can, create a folder at ~/.sprout/bin and ~/.sprout/repos if it doesn't already exist.")
                Foundation.exit(1)
            }
        }
        printV("User details passed or were created.")
        
        // MARK: Clone and Reset to Tag Repo
        
        print("Cloning \(sproutFile.packageName) from \(gitHubURL)")
        do {
            try shellOut(to: .gitClone(url: gitHubURL), at: repoPath.path)
        } catch let cloneError as ShellOutError {
            do {
                try shellOut(to: .gitPull(), at: try repoPath.subfolder(at: sproutFile.packageName).path)
            } catch let pullError as ShellOutError {
                print("Unable to update package.")
                print("You might already be on the latest version of \(sproutFile.packageName).")
                if !skipPrompts && prompt("Would you like to continue installation anyway: (y/CANCEL) ") != ("y" || "yes" || "c" || "continue") {
                    print(pullError.description)
                    Foundation.exit(1)
                }
            } catch {
                print("Unable to clone package.")
                print(cloneError.description)
            }
        }
        do {
            let tagList = try shellOut(to: "git tag --list", at: repoPath.path)
            let tagArray = tagList.split(separator: "\n")
            if !(tagArray.isEmpty) {
                if let currentTag = VersionGrab(tagArray) {
                    do {
                        try shellOut(to: "git reset \(currentTag) --hard")
                    } catch {
                        print("Unable to reset to latest tag, continuing with master.")
                    }
                }
            }
        } catch {}
        print("Cloned package.")
        
        // MARK: Build Package
        
        if newUser {
            print("Build (among others) scripts are provided by the owners of the package, not sprout.")
            print("These scripts can run any command, without your permission.")
        }
        if !skipPrompts && prompt("Would you like to continue, build and install \(sproutFile.packageName): (y/CANCEL) ") != ("y" || "yes") {
            print("Canceling install...")
            Foundation.exit(1)
        }
        var allowCustomOutput: Bool?
        print("Building package...")
        try sproutFile.buildActions.forEach { (action) in
            switch action {
            case .shell(let cmd):
                do {
                    try shellOut(to: cmd, at: repoPath.subfolder(at: sproutFile.packageName).path)
                } catch let error as ShellOutError {
                    print("A command part of the build actions for \(sproutFile.packageName) failed.")
                    print(error.description)
                    Foundation.exit(1)
                }
            case .installBin:
                print("Cannot install a file during a build process.")
                Foundation.exit(1)
            case .installApp:
                print("Cannot install an app during an install process.")
                Foundation.exit(1)
            case .echo(let output):
                if allowCustomOutput == nil {
                    if prompt("\(sproutFile.packageName) would like to print custom output: (y/IGNORE) ") == ("y" || "yes") {
                        allowCustomOutput = true
                        print(output)
                    } else {
                        allowCustomOutput = false
                    }
                } else if allowCustomOutput == true {
                    print(output)
                }
            case .push(let cmd):
                if allowCustomOutput == nil {
                    if prompt("\(sproutFile.packageName) would like to print custom output: (y/IGNORE) ") == ("y" || "yes") {
                        allowCustomOutput = true
                        let exitCode = system(cmd)
                        if exitCode != 0 {
                            print("A command part of the build actions for \(sproutFile.packageName) failed.")
                            print("Exit code: \(exitCode)")
                            Foundation.exit(1)
                        }
                    } else {
                        allowCustomOutput = false
                    }
                } else if allowCustomOutput == true {
                    system(cmd)
                }
            }
        }
        print("Successfully built \(sproutFile.packageName)")
        
        // MARK: Install Package
        
        print("Installing package...")
        try sproutFile.installActions.forEach({ (action) in
            switch action {
            case .shell(let cmd):
                do {
                    try shellOut(to: cmd, at: repoPath.subfolder(at: sproutFile.packageName).path)
                } catch let error as ShellOutError {
                    print("A command part of the install actions for \(sproutFile.packageName) failed.")
                    print(error.description)
                    Foundation.exit(1)
                }
            case .installBin(let find, let install):
                var cli: File
                do {
                    printV("Obtaining built CLI...")
                    cli = try repoPath.subfolder(at: sproutFile.packageName).file(at: find)
                    printV("Obtained cli.")
                } catch let error as LocationError {
                    print("Unable to find fully built cli to install.")
                    print(error.description)
                    Foundation.exit(1)
                }
                _ = try? binPath.file(at: cli.name).delete()
                let sproutCLI: File
                do {
                    printV("Copying built CLI to Sprout bin.")
                    sproutCLI = try cli.copy(to: binPath)
                    printV("Copied/Pasted CLI.")
                } catch let error as LocationError {
                    print("Unable to copy built cli to Sprout bin.")
                    print(error.description)
                    Foundation.exit(1)
                }
                _ = try? File(path: install).delete()
                do {
                    printV("Creating symlink from built CLI to usr/local/bin.")
                    try shellOut(to: "ln -s \"\(sproutCLI.path)\" \"\(install)\"")
                    printV("Created symlink.")
                } catch let error as ShellOutError {
                    print("Unable to create symlink from built CLI to usr/local/bin.")
                    print(error.description)
                    Foundation.exit(1)
                }
            case .installApp(let find, let install):
                var app: File?
                do {
                    printV("Obtaining app to install...")
                    app = try repoPath.subfolder(at: sproutFile.packageName).file(at: find)
                    printV("Obtained app.")
                } catch let error as LocationError {
                    print("Unable to find app to install.")
                    print(error.description)
                    Foundation.exit(1)
                }
                do {
                    printV("Copying app to Applications folder")
                    try shellOut(to: "cp -f \"\(app!.path)\" \"\(install)\"")
                    printV("Copied application.")
                } catch let error as ShellOutError {
                    print("Unable to copy app to Applications folder")
                    print(error.description)
                }
            case .echo(let output):
                if allowCustomOutput == nil {
                    if prompt("\(sproutFile.packageName) would like to print custom output: (y/IGNORE) ") == ("y" || "yes") {
                        allowCustomOutput = true
                        print(output)
                    } else {
                        allowCustomOutput = false
                    }
                } else if allowCustomOutput == true {
                    print(output)
                }
            case .push(let cmd):
                if allowCustomOutput == nil {
                    if prompt("\(sproutFile.packageName) would like to print custom output: (y/IGNORE) ") == ("y" || "yes") {
                        allowCustomOutput = true
                        let exitCode = system(cmd)
                        if exitCode != 0 {
                            print("A command part of the build actions for \(sproutFile.packageName) failed.")
                            print("Exit code: \(exitCode)")
                            Foundation.exit(1)
                        }
                    } else {
                        allowCustomOutput = false
                    }
                } else if allowCustomOutput == true {
                    system(cmd)
                }
            }
        })
        if sproutFile.runOnly {
            print("Cleaning up installation...")
            do {
                _ = try repoPath.subfolder(at: sproutFile.packageName).delete()
            } catch let error as LocationError {
                print("Unable to clean up installation (for an install once package).")
                print(error.description)
                Foundation.exit(1)
            }
            print("Finished clean up.")
        }
        print("Successfully installed \(sproutFile.packageName)!")
    }
}

public struct ComparisonContainer<Item: Equatable> {
    public let items: [Item]
    public let rules: Rule

    public enum Rule {
        case OR
        case AND
    }
}

extension ComparisonContainer {
    init(_ items: Item..., rules: Rule) {
        self.items = items
        self.rules = rules
    }
}

extension Equatable {
    static public func || (lhs: Self, rhs: Self) -> ComparisonContainer<Self> {
        return .init(items: [lhs, rhs], rules: .OR)
    }

    static public func || (lhs: ComparisonContainer<Self>, rhs: Self) -> ComparisonContainer<Self> {
        var new = lhs.items
        new.append(rhs)
        return .init(items: new, rules: .OR)
    }

    static public func == (lhs: Self, rhs: Self) -> ComparisonContainer<Self> {
        return .init(items: [lhs, rhs], rules: .AND)
    }

    static public func == (lhs: ComparisonContainer<Self>, rhs: Self) -> ComparisonContainer<Self> {
        var new = lhs.items
        new.append(rhs)
        return .init(items: new, rules: .AND)
    }

    static public func == (lhs: Self, rhs: ComparisonContainer<Self>) -> Bool {
        if rhs.rules == .OR {
            var aws = false
            rhs.items.forEach { (item) in
                if item == lhs {
                    aws = true
                }
            }
            return aws
        } else {
            var aws: Bool?
            rhs.items.forEach { (item) in
                if aws == false { return }
                if item == lhs {
                    aws = true
                } else {
                    aws = false
                }
            }
            return aws ?? false
        }
    }

    static public func != (lhs: Self, rhs: ComparisonContainer<Self>) -> Bool {
        return !(lhs == rhs)
    }
}

//var array = ["v1.0", "v2.4-beta2", "v2.4", "v3.1", "v1.1", "v2.4-beta1"].sorted { (one, two) -> Bool in
//    if one.hasPrefix(two) {
//        return false
//    }
//    if two.hasPrefix(one) {
//        return true
//    }
//    if [one, two].sorted()[0] == one {
//        return false
//    }
//    else {
//        return true
//    }
//}

func VersionSort(_ array: [String]) -> [String] {
    array.sorted { (one, two) -> Bool in
        if one.hasPrefix(two) {
            return false
        }
        if two.hasPrefix(one) {
            return true
        }
        if [one, two].sorted()[0] == one {
            return false
        } else {
            return true
        }
    }
}

func VersionGrab(_ array: [String], isIgnored: (String) -> Bool = { !($0.contains("beta") || $0.contains("alpha")) }) -> String? {
    let filteredArray = array.rmMap { isIgnored($0) ? nil : $0 }
    return filteredArray.isEmpty ? nil : VersionSort(filteredArray)[0]
}

extension Sequence {
    public func rmMap<T>(_ matches: (Element) -> T?) -> [T] {
        var returnItem = [] as [T]
        forEach {
            if let item = matches($0) {
                returnItem.append(item)
            }
        }
        return returnItem
    }
}
