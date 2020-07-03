//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import Foundation
import Files

struct SproutFile {
    
    let packageName: String
    let packageDescription: String?
    let packageGitURL: URL
    let packageWebpage: URL?
    let packageCLIName: String?
    
    let builtCLI: String
    
    let buildActions: [SproutFileAction]
    
//    public static func decodeFile(
//        packageName: @escaping () -> String,
//        packageDescription: @escaping () -> String?,
//        packageGitURL: @escaping () -> URL,
//        packageWebpage: @escaping () -> URL?,
//        currentCommit: @escaping () -> String,
//        builtCLI: @escaping () -> File,
//        buildActions: @escaping () -> [SproutAction]
//    ) -> SproutFile {
//        .init(
//            packageName: packageName(),
//            packageDescription: packageDescription(),
//            packageGitURL: packageGitURL(),
//            packageWebpage: packageWebpage(),
//            currentCommit: currentCommit(),
//            builtCLI: builtCLI(),
//            buildActions: buildActions()
//        )
//    }
    
    public static func decodeFile(file: @escaping () -> SproutFile) -> SproutFile {
        file()
    }
    
}

struct SproutFileBuilder {
    
    var packageName: String?
    var packageDescription: String?
    var packageGitURL: URL?
    var packageWebpage: URL?
    var packageCLIName: String?
    
    var builtCLI: String?
    
    var buildActions: [SproutFileAction]?
    
    func checkDetails(catch catchAction: ([String]) -> Never) -> SproutFile {
        var violations : [String] = []
        if packageName == nil { violations.append("packageName") }
        if packageGitURL == nil { violations.append("packageGitURL") }
        if builtCLI == nil { violations.append("builtCLI") }
        if buildActions == nil || buildActions?.count == 0 { violations.append("buildActions") }
        if violations.count > 0 {
            catchAction(violations)
        }
        return .init(
            packageName: packageName!,
            packageDescription: packageDescription,
            packageGitURL: packageGitURL!,
            packageWebpage: packageWebpage,
            packageCLIName: packageCLIName,
            builtCLI: builtCLI!,
            buildActions: buildActions!
        )
    }
    
    init() {
        packageName = nil
        packageDescription = nil
        packageGitURL = nil
        packageWebpage = nil
        packageCLIName = nil
        builtCLI = nil
        buildActions = nil
    }
}

enum SproutFileAction {
    case shell(String)
}
