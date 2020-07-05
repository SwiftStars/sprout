//
//  CheckFile.swift
//  sprout
//
//  Created by Benjamin Sova on 6/30/20.
//

import Foundation
import StdLibX

protocol SPRTCheckFile: SPRTVerbose {
    
}

extension SPRTCheckFile {
    func checkFile(_ SproutFileArray: [String], ifViolates: @escaping ([String], SproutFileBuilder) -> Never) -> SproutFile {
        return SproutFile.decodeFile { () -> SproutFile in
            var sproutFile = SproutFileBuilder()
            var inside = "nil"
            
            SproutFileArray.forEach { (OGLINE, index) in
                var line = OGLINE
                repeatUntil { (_, _) -> (Bool, Never?) in
                    if line.hasPrefix("\t") || line.hasPrefix(" ") {
                        line.removeFirst(1)
                        return (true, nil)
                    }
                    return (false, nil)
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
                            }
                            else if insideInside == "projectname" {
                                sproutFile.packageName = String(word)
                                printV("(\(index + 1)) Project Name is defined. (\(word))")
                            }
                            else if insideInside == "cliname" {
                                sproutFile.packageCLIName = String(word)
                                printV("(\(index + 1)) CLI Name is defined. (\(word))")
                            }
                            else if insideInside == "builtcli" {
                                sproutFile.builtCLI = String(word)
                                printV("(\(index + 1)) Built CLI Location is defined. (\(word))")
                            }
                            else if insideInside == "giturl" {
                                sproutFile.packageGitURL = URL(string: String(word))
                                printV("(\(index + 1)) The Git URL is defined. (\(word))")
                            }
                            else if insideInside == "website" {
                                sproutFile.packageWebpage = URL(string: String(word))
                                printV("(\(index + 1)) The Package Webpage is defined. (\(word))")
                            }
                            else if insideInside == "build" {
                                inside = "build"
                                printV("(\(index + 1)) Started reading build actions. (build)")
                            }
                        }
                    }
                }
                else if inside == "build" {
                    let checkResult = checkBuildLine(line, index)
                    if checkResult.action == nil && checkResult.end == true {
                        inside = "nil"
                    }
                    else if checkResult.action != nil {
                        if sproutFile.buildActions == nil { sproutFile.buildActions = [] }
                        sproutFile.buildActions!.append(checkResult.action!)
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
            printV("(\(index + 1)) Stopped reading build actions. (build)")
            return (nil, true)
        }
        printV("(\(index + 1)) Read a shell action. (\(line))")
        return (.shell(line), false)
    }
    
}
