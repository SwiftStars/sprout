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

    let buildActions: [SproutFileAction]
    let installActions: [SproutFileAction]

    public static func decodeFile(file: @escaping () -> SproutFile) -> SproutFile {
        file()
    }

}

//extension SproutFile: FormatedObjectStringConvertable {
    
//    var formatedDescription: String {
//        var string = """
//        SproutFile (
//            packageName: "\(packageName)",
//            packageDescription: "\(packageDescription ?? "nil")",
//            packageGitURL: "\(packageGitURL)",
//            packageWebpage: "\(packageWebpage?.absoluteString ?? "nil")",
//            packageCLIName: "\(packageCLIName ?? "nil")",
//            buildActions: [
//        """
//        buildActions.forEach { (action) in
//            string.append("""
//
//
//            """
//        }
//        return string
//    }
    
//}

struct SproutFileBuilder {

    var packageName: String?
    var packageDescription: String?
    var packageGitURL: URL?
    var packageWebpage: URL?
    var packageCLIName: String?

    var buildActions: [SproutFileAction]?
    var installActions: [SproutFileAction]?

    func checkDetails(catch catchAction: ([String]) -> Never) -> SproutFile {
        var violations: [String] = []
        if packageName == nil { violations.append("packageName") }
        if packageGitURL == nil { violations.append("packageGitURL") }
        if buildActions == nil || buildActions?.count == 0 { violations.append("buildActions") }
        if installActions == nil || installActions?.count == 0 { violations.append("installActions") }
        if violations.count > 0 {
            catchAction(violations)
        }
        return .init(
            packageName: packageName!,
            packageDescription: packageDescription,
            packageGitURL: packageGitURL!,
            packageWebpage: packageWebpage,
            packageCLIName: packageCLIName,
            buildActions: buildActions!,
            installActions: installActions!
        )
    }

    init() {
        packageName = nil
        packageDescription = nil
        packageGitURL = nil
        packageWebpage = nil
        packageCLIName = nil
        buildActions = nil
    }
}

enum SproutFileAction {
    case shell(String)
    case installBin(String, String)
    case installApp(String, String)
    
//    var formatedDescription: String {
//        switch self {
//        case .shell(let str):
//            return "SproutFileAction.shell(\"\(str)\")"
//        case .installBin(let str, let str2):
//            return "SproutFileAction.installBin(\"\(str)\", \"\(str2)\")"
//    }
    
}
