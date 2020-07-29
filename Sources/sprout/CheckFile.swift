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
            var inside = InsideKey?.none

            checkPrompt("Ready to check (checkFile func)? ")

            SproutFileArray.forEach { (OGLINE, index) in
                checkPrompt("Checking at \(index)...")
                var line = OGLINE
                repeatUntil { (_, _) -> (Bool, Never?) in
                    if line.hasPrefix("\t") || line.hasPrefix(" ") || line.hasPrefix("%") {
                        checkPrompt("Removing white space.")
                        line.removeFirst(1)
                        return (false, nil)
                    }
                    checkPrompt("Continuing reading.")
                    return (true, nil)
                }
                if line.hasPrefix("#") || line.isEmpty || line == "" { printV("(\(index + 1)) Empty/Comment Line, ignoring..."); return }
                if inside == nil {
                    Tokens.allCases.forEach { token in
                        if line.hasPrefix(token.id) {
                            if case .bool(let location) = token.key {
                                sproutFile[keyPath: location] = true
                            } else if case .string(let location) = token.key {
                                line.removeFirst(token.id.count + 1)
                                sproutFile[keyPath: location] = line
                            } else if case .url(let location) = token.key {
                                line.removeFirst(token.id.count + 1)
                                sproutFile[keyPath: location] = URL(string: line)
                            } else if case .action(let insideKey) = token.key {
                                inside = insideKey
                            } else if case .single(let location, let convert) = token.key {
                                line.removeFirst(token.id.count + 1)
                                if sproutFile[keyPath: location] == nil { sproutFile[keyPath: location] = [convert(line)] } else { sproutFile[keyPath: location]!.append(convert(line)) }
                            }
                        }
                    }
                } else {
                    let result = inside!.check(line, index, verbose)
                    if result.end { inside = nil; return }
                    if let action = result.action {
                        if sproutFile[keyPath: inside!.location] == nil { sproutFile[keyPath: inside!.location] = [action] } else { sproutFile[keyPath: inside!.location]!.append(action) }
                    }
                }
            }
            return sproutFile.checkDetails { (violations) -> Never in
                ifViolates(violations, sproutFile)
            }
        }
    }
}

func checkBuildLine(_ line: String, _ index: Int, _ verbose: Bool) -> (action: SproutFileAction?, end: Bool) {
    let printV: (String) -> Void = { if verbose { print($0) } }
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

func checkInstallLine(_ line: String, _ index: Int, _ verbose: Bool) -> (action: SproutFileAction?, end: Bool) {
    let printV: (String) -> Void = { if verbose { print($0) } }
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
