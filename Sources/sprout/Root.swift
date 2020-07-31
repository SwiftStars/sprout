//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import ArgumentParser
import StdLibX

struct SproutRoot: ParsableCommand {

    static var configuration: CommandConfiguration = .init(
        commandName: "sprout",
        abstract: "A simple CLI installer with little setup.",
        version: "Sprout v0.0.0 alpha 1",
        subcommands: [SproutInstall.self, SproutCheck.self, SproutDetail.self, SproutUninstall.self, SproutList.self, SproutNew.self],
        defaultSubcommand: SproutInstall.self
    )
}

struct SproutList: ParsableCommand {

    static var configuration: CommandConfiguration = .init(
        commandName: "list",
        abstract: "List all installed packages."
    )

    @Flag(name: .customShort("1"), help: "Print one package per line. (Useful for automated scripts)")
    var onePerLine: Bool = false

    func run() throws {
        system("ls \(onePerLine ? "-1 " : "")/usr/local/lib/sprout/repos")
    }

}
