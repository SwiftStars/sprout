//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation
import StdLibX

protocol SPRTCheckPrompts {
    var checkPrompts: Bool { get set }
}

extension SPRTCheckPrompts {
    var checkPrompts: Bool {
        get {
            return false
        }
        set {}
    }
}

extension SPRTCheckPrompts {
    func checkPrompt(_ string: String) {
        if checkPrompts { _ = prompt(string) }
    }
}

protocol SPRTCheckFile: SPRTVerbose, SPRTCheckPrompts {

}

extension SPRTCheckFile {
    func checkFile(_ SproutFileArray: [String], ifViolates: @escaping ([String], SproutFileBuilder) -> Never) -> SproutFile {
        return SproutFile.decodeFile { () -> SproutFile in
            var sproutFile = SproutFileBuilder()
            var inside = "nil"

            checkPrompt("Ready to check (checkFile func)? ")

            SproutFileArray.forEach { (OGLINE, index) in
                checkPrompt("Checking at \(index)...")
                var line = OGLINE
                repeatUntil { (_, _) -> (Bool, Never?) in
                    if line.hasPrefix("\t") || line.hasPrefix(" ") {
                        checkPrompt("Removing white space.")
                        line.removeFirst(1)
                        return (false, nil)
                    }
                    checkPrompt("Continuing reading.")
                    return (true, nil)
                }
                var insideInside = "nil"
                if inside == "nil" {
                    if line.hasPrefix("#") || line.isEmpty || line == "" { printV("(\(index + 1)) Empty/Comment Line, ignoring..."); return }
                    if line.hasPrefix("%") {
                        line.split(separator: " ").forEach { (word) in
                            if insideInside == "nil" {
                                if word == "%" { return }
                                if word == "projectname:" { insideInside = "projectname" }
                                if word == "cliname:" { insideInside = "cliname" }
                                if word == "builtcli:" { insideInside = "builtcli" }
                                if word == "giturl:" { insideInside = "giturl" }
                                if word == "website:" { insideInside = "website" }
                                if word == "build" { insideInside = "build" }
                                if word == "install" { insideInside = "install" }
                            } else if insideInside == "projectname" {
                                sproutFile.packageName = String(word)
                                printV("(\(index + 1)) Project Name is defined. (\(word))")
                            } else if insideInside == "cliname" {
                                sproutFile.packageCLIName = String(word)
                                printV("(\(index + 1)) CLI Name is defined. (\(word))")
                            } else if insideInside == "builtcli" {
                                sproutFile.installActions = [.installBin(String(word), "/usr/local/bin/\(sproutFile.packageCLIName ?? (sproutFile.packageName?.replacingOccurrences(of: " ", with: "-")) ?? "nilfile")")]
                                printV("(\(index + 1)) Built CLI Location (as install action) is defined. (\(word))")
                            } else if insideInside == "giturl" {
                                sproutFile.packageGitURL = URL(string: String(word))
                                printV("(\(index + 1)) The Git URL is defined. (\(word))")
                            } else if insideInside == "website" {
                                sproutFile.packageWebpage = URL(string: String(word))
                                printV("(\(index + 1)) The Package Webpage is defined. (\(word))")
                            } else if insideInside == "build" {
                                inside = "build"
                                printV("(\(index + 1)) Started reading build actions. (build)")
                            } else if insideInside == "install" {
                                inside = "install"
                                printV("(\(index + 1)) Started reading install actions. (install)")
                            }
                        }
                    }
                } else if inside == "build" {
                    let checkResult = checkBuildLine(line, index)
                    if checkResult.action == nil && checkResult.end == true {
                        inside = "nil"
                    } else if checkResult.action != nil {
                        if sproutFile.buildActions == nil { sproutFile.buildActions = [] }
                        sproutFile.buildActions!.append(checkResult.action!)
                    }
                } else if inside == "install" {
                    let checkResult = checkInstallLine(line, index)
                    if checkResult.action == nil && checkResult.end == true {
                        inside = "nil"
                    } else if checkResult.action != nil {
                        if sproutFile.installActions == nil { sproutFile.installActions = [] }
                        sproutFile.installActions!.append(checkResult.action!)
                    }
                }
            }
            return sproutFile.checkDetails { (violations) -> Never in
                ifViolates(violations, sproutFile)
            }
        }
    }
}

extension SPRTCheckFile {

    fileprivate func checkBuildLine(_ line: String, _ index: Int) -> (action: SproutFileAction?, end: Bool) {
        if line.isEmpty || line.hasPrefix("#") {
            printV("(\(index + 1)) Empty/Comment Line in build details, ignoring...")
            return (nil, false)
        }
        if line.hasPrefix("}") || line.hasPrefix("% }") || line.hasPrefix("%}") {
            printV("(\(index + 1)) Stopped reading build actions. (\(line))")
            return (nil, true)
        }
        if line.hasPrefix("install->bin") {
            print("(\(index + 1)) Build actions cannot have install actions.")
            Foundation.exit(1)
        }
        if line.hasPrefix("install->app") {
            print("(\(index + 1)) Build actions cannot have install actions.")
            Foundation.exit(1)
        }
        if line.hasPrefix("push->") {
            var without = line
            without.removeFirst(7)
            printV("(\(index + 1)) Read a shell command with push output. (\(without))")
            return (.push(without), false)
        }
        if line.hasPrefix("echo->") {
            var without = line
            without.removeFirst(7)
            printV("(\(index + 1)) Read an echo command. (\(without))")
            return (.echo(without), false)
        }
        printV("(\(index + 1)) Read a shell action. (\(line))")
        return (.shell(line), false)
    }

    fileprivate func checkInstallLine(_ line: String, _ index: Int) -> (action: SproutFileAction?, end: Bool) {
        if line.isEmpty || line.hasPrefix("#") {
            printV("(\(index + 1)) Empty/Comment Line in install details, ignoring...")
            return (nil, false)
        }
        if line.hasPrefix("}") || line.hasPrefix("% }") || line.hasPrefix("%}") {
            printV("(\(index + 1)) Stopped reading install actions. (install)")
            return (nil, true)
        }
        if line.hasPrefix("install->bin") {
            var without = line
            without.removeFirst(13)
            let args = without.split(separator: " ")
            if args.count < 1 {
                print("(\(index + 1)) Install to bin action does not have enough arguments.")
                Foundation.exit(1)
            } else if args.count > 2 {
                print("(\(index + 1)) Install to bin action has two many arguments.")
                Foundation.exit(1)
            }
            printV("(\(index + 1)) Read an install to bin action. (\(line))")
            if args.count == 1 {
                var name: String = "failed-sprout"
                args[0].split(separator: "/").forEach { (path) in
                    name = path
                }
                return (.installBin(args[0], "/usr/local/bin/\(name)"), false)
            } else {
                return (.installBin(args[0], "/usr/local/bin/\(args[1])"), false)
            }
        }
        if line.hasPrefix("install->app") {
            var without = line
            without.removeFirst(13)
            let args = without.split(separator: " ")
            if args.count < 1 {
                print("(\(index + 1)) Install app action does not have enough arguments.")
                Foundation.exit(1)
            } else if args.count > 2 {
                print("(\(index + 1)) Install app action has two many arguments.")
                Foundation.exit(1)
            }
            printV("(\(index + 1)) Read an install app action. (\(line))")
            if args.count == 1 {
                var name: String = "failed-sprout.app"
                args[0].split(separator: "/").forEach { (path) in
                    name = path
                }
                return (.installApp(args[0], "/Applications/\(name)"), false)
            } else {
                return (.installApp(args[0], "/Applications/\(args[1])"), false)
            }
        }
        if line.hasPrefix("push->") {
            var without = line
            without.removeFirst(7)
            printV("(\(index + 1)) Read a shell command with push output. (\(without))")
            return (.push(without), false)
        }
        if line.hasPrefix("echo->") {
            var without = line
            without.removeFirst(7)
            printV("(\(index + 1)) Read an echo command. (\(without))")
            return (.echo(without), false)
        }
        printV("(\(index + 1)) Read a shell action. (\(line))")
        return (.shell(line), false)
    }
}
