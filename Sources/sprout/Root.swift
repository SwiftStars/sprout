//
// Sprout Source Code
// Copyright © Ben Sova (GNU GPLv3)
//

import ArgumentParser

struct SproutRoot: ParsableCommand {

    static var configuration: CommandConfiguration = .init(
        commandName: "sprout",
        abstract: "A simple CLI installer with little setup.",
        version: "Sprout v0.0.0 alpha 1",
        subcommands: [SproutInstall.self, SproutCheck.self, SproutDetail.self],
        defaultSubcommand: SproutInstall.self
    )

}
