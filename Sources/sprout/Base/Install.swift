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
    
    func run() throws {
        
        // MARK: Validate URL
        
        printV("Validating URL, \(url), to make sure it is a valid GitHub repo reference.")
//        printV("First checking to see if it is a complete URL on it's own (That is not currently supported).")
//        if URL(string: url) != nil {
//            print("The URL provided, \(url), does not properly represent a GitHub repo.")
//            print("Try using a URL like SwiftStars/sprout, which would be automatically converted to \"https://github.com/SwiftStars/sprout.git\".")
//            Foundation.exit(1)
//        }
        printV("Now checking to see if the generated url is valid.")
        if URL(string: "https://github.com/\(url).git") == nil {
            print("The URL provided, \(url), does not properly represent a GitHub repo.")
            print("Try using a url like SwiftStars/sprout, which would be automatically converted to \"https://github.com/SwiftStars/sprout.git\".")
            Foundation.exit(1)
        }
        printV("URL passed validation.")
        
        // MARK: Obtain SproutFile
        
        let SproutFileURL = URL(string: "https://raw.githubusercontent.com/\(url)/master/SproutFile")!
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
            }
            else {
                SproutFileData = sproutData
            }
        }
        else { print("Could not find SproutFile in package."); Foundation.exit(1) }
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
            }
            else {
                print("The SproutFile provided by \(sproutf.packageName ?? "this package") does not contain a \(violations[0]).")
            }
            print("Please contact the owner of this package and tell them to include that information in their SproutFile.")
            Foundation.exit(1)
        }
        printV(
            "Finished decoding SproutFile.",
            "Obtained package information for \(sproutFile.packageName)."
        )
        var gitHubURL = URL(string: "https://github.com/\(url).git")!
        printV("Second URL check...")
        if sproutFile.packageGitURL != gitHubURL {
            print("The URL used to obtain the the SproutFile and the url inside the SproutFile do not match.")
            let aws = prompt("Would you like to use your URL or the one in the SproutFile: (y/t/CANCEL) ")
            if aws == ("y" || "your" || "yours") {}
            else if aws == ("t" || "their" || "theirs") {
                gitHubURL = sproutFile.packageGitURL
            }
            else {
                print("Stoping install...")
                Foundation.exit(-1)
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
            }
            catch {
                print("Could not create a Sprout directory.")
                print("If you can, create a folder at ~/.sprout/repos and ~/.sprout/bin")
                Foundation.exit(1)
            }
        }
        var repoPath = Folder.home
        do {
            repoPath = try Folder(path: "~/.sprout/repos")
        }
        catch {
            do {
                repoPath = try Folder.home.createSubfolder(at: ".sprout/repos")
                newUser = true
            }
            catch {
                print("Unable to find or create a directory where repos can be stored.")
                print("If you can, create a folder at ~/.sprout/repos and ~/.sprout/bin if it doesn't already exist.")
                Foundation.exit(1)
            }
        }
        var binPath = Folder.home
        do {
            binPath = try Folder(path: "~/.sprout/bin")
        }
        catch {
            do {
                binPath = try Folder.home.createSubfolder(at: ".sprout/bin")
                newUser = true
            }
            catch {
                print("Unable to find or create a directory where repos can be stored.")
                print("If you can, create a folder at ~/.sprout/bin and ~/.sprout/repos if it doesn't already exist.")
                Foundation.exit(1)
            }
        }
        printV("User details passed or were created.")
        print("Cloning \(sproutFile.packageName) from \(gitHubURL)")
        do {
            try shellOut(to: .gitClone(url: gitHubURL), at: repoPath.path)
        }
        catch let cloneError as ShellOutError {
            do {
                try shellOut(to: .gitPull(), at: try repoPath.subfolder(at: sproutFile.packageName).path)
            }
            catch let pullError as ShellOutError {
                print("Unable to update package.")
                print("You might already be on the latest version of \(sproutFile.packageName).")
                if prompt("Would you like to continue installation anyway: (y/CANCEL) ") != ("y" || "yes" || "c" || "continue") {
                    print(pullError.description)
                    Foundation.exit(1)
                }
            }
            catch {
                print("Unable to clone package.")
                print(cloneError.description)
            }
        }
        print("Cloned package.")
        if newUser {
            print("Build (among others) scripts are provided by the owners of the package, not sprout.")
            print("These scripts can run any command, without your permission.")
        }
        if prompt("Would you like to continue, build and install \(sproutFile.packageName): (y/CANCEL) ") != ("y" || "yes") {
            print("Canceling install...")
            Foundation.exit(1)
        }
        print("Building package...")
        try sproutFile.buildActions.forEach { (action) in
            var command = ""
            switch action {
            case .shell(let cmd):
                command = cmd
            }
            do {
                try shellOut(to: command, at: repoPath.subfolder(at: sproutFile.packageName).path)
            }
            catch let error as ShellOutError {
                print("A command part of the build actions for \(sproutFile.packageName) failed.")
                print(error.description)
                Foundation.exit(1)
            }
        }
        print("Successfully built \(sproutFile.packageName)")
        print("Installing package...")
        var builtCLI: File? = nil
        do {
            printV("Obtaining built CLI...")
            builtCLI = try repoPath.subfolder(at: sproutFile.packageName).file(at: sproutFile.builtCLI)
            printV("Obtained cli.")
        }
        catch {
            print("Unable to find fully built cli to install.")
            Foundation.exit(1)
        }
        _ = try? binPath.file(at: builtCLI!.name).delete()
        do {
            printV("Copying built CLI to Sprout bin.")
            try builtCLI!.copy(to: binPath)
            printV("Copied/Pasted CLI.")
        }
        catch let error as LocationError {
            print("Unable to copy built cli to Sprout bin.")
            print(error.description)
            Foundation.exit(1)
        }
        do {
            printV("Creating symlink from built CLI to usr/local/bin.")
            try shellOut(to: "ln -s \(builtCLI!.path) /usr/local/bin/\(sproutFile.packageCLIName ?? sproutFile.packageName.replacingOccurrences(of: " ", with: "-"))")
            printV("Created symlink.")
        }
        catch let error as ShellOutError {
            print("Unable to create symlink from built CLI to usr/local/bin.")
            print(error.description)
            Foundation.exit(1)
        }
        print("Successfully installed \(sproutFile.packageName)!")
    }
}

public struct Container<Item: Equatable> {
    public let items: [Item]
    public let rules: Rule
    
    public enum Rule {
        case OR
        case AND
    }
}

extension Equatable {
    static public func || (lhs: Self, rhs: Self) -> Container<Self> {
        return .init(items: [lhs, rhs], rules: .OR)
    }
    
    static public func || (lhs: Container<Self>, rhs: Self) -> Container<Self> {
        var new = lhs.items
        new.append(rhs)
        return .init(items: new, rules: .OR)
    }
    
    static public func == (lhs: Self, rhs: Self) -> Container<Self> {
        return .init(items: [lhs, rhs], rules: .AND)
    }
    
    static public func == (lhs: Container<Self>, rhs: Self) -> Container<Self> {
        var new = lhs.items
        new.append(rhs)
        return .init(items: new, rules: .AND)
    }
    
    static public func == (lhs: Self, rhs: Container<Self>) -> Bool {
        if rhs.rules == .OR {
            var aws = false
            rhs.items.forEach { (item) in
                if item == lhs {
                    aws = true
                }
            }
            return aws
        }
        else {
            var aws: Bool? = nil
            rhs.items.forEach { (item) in
                if aws == false { return }
                if item == lhs {
                    aws = true
                }
                else {
                    aws = false
                }
            }
            return aws ?? false
        }
    }
    
    static public func != (lhs: Self, rhs: Container<Self>) -> Bool {
        return !(lhs == rhs)
    }
}
