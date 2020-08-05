//
//  Tokenizer.swift
//  sprout
//
//  Created by Benjamin Sova on 7/28/20.
//

import Foundation

struct TLTokens: CaseIterable {
    let id: String
    let key: CustomKeyPath

    static let projectName: Self = .init("projectname:", .string(\.packageName))
    static let gitDir: Self = .init("projectdir:", .string(\.packageDirectory))
    static let description: Self = .init("description:", .string(\.packageDescription))
    static let gitURL: Self = .init("giturl:", .url(\.packageGitURL))
    static let builtCLI: Self = .init("builtcli:", .single(\.installActions, { .installBin($0, $0.split(separator: "/").last!) }))
    static let website: Self = .init("website:", .url(\.packageWebpage))
    static let cliName: Self = .init("cliname:", .string(\.packageCLIName))
    static let runOnly: Self = .init("installonce", .bool(\.runOnly))

    static let buildActions: Self = .init("build", .action(.init(0, \.buildActions, checkBuildLine)))
    static let installActions: Self = .init("install", .action(.init(0, \.installActions, checkInstallLine)))

    static var allCases: [Self] {[
        .projectName,
        .description,
        .gitURL,
        .builtCLI,
        .website,
        .cliName,
        .runOnly,
        .buildActions,
        .installActions
    ]}

    fileprivate init(_ id: String, _ key: CustomKeyPath) {
        self.id = id
        self.key = key
    }
}

enum CustomKeyPath {
    case string(WritableKeyPath<SproutFileBuilder, String?>)
    case bool(WritableKeyPath<SproutFileBuilder, Bool?>)
    case url(WritableKeyPath<SproutFileBuilder, URL?>)
    case single(WritableKeyPath<SproutFileBuilder, [SproutFileAction]?>, (String) -> SproutFileAction)
    case action(InsideKey)
}

struct InsideKey: CaseIterable {
    let hashValue: Int
    let location: WritableKeyPath<SproutFileBuilder, [SproutFileAction]?>
    let check: (String, Int, Bool) -> (action: SproutFileAction?, end: Bool)

    static let build: InsideKey = .init(0, \.buildActions, checkBuildLine)
    static let install: InsideKey = .init(0, \.installActions, checkInstallLine)

    static var allCases: [InsideKey] {[
        .build,
        .install
    ]}

    init(_ hash: Int, _ location: WritableKeyPath<SproutFileBuilder, [SproutFileAction]?>, _ check: @escaping (String, Int, Bool) -> (action: SproutFileAction?, end: Bool)) {
        self.hashValue = hash
        self.location = location
        self.check = check
    }
}

struct BuildTokens: CaseIterable {
    let prefix: String
    let decode: (String) -> SproutFileAction
    
    static let echo: Self = .init("echo->", { .echo($0) })
    static let push: Self = .init("push->", { .push($0) })
    
    // NOTE: Keep "shell" last!
    static let shell: Self = .init("", { .shell($0) })
    
    static let allCases: [Self] = [
        .echo,
        .push,
        .shell
    ]
    
    init(_ prefix: String, _ decode: @escaping (String) -> SproutFileAction) {
        self.prefix = prefix
        self.decode = decode
    }
}
