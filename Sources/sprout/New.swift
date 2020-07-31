//
//  New.swift
//  sprout
//
//  Created by Benjamin Sova on 7/11/20.
//

import Foundation
import ArgumentParser
import Files
import StdLibX
import ShellOut

struct SproutNew: ParsableCommand {

    static var configuration: CommandConfiguration = .init(
        commandName: "new",
        abstract: "Create a new sprout."
    )

    @Flag(help: "Get info about each section of the SproutFile.")
    var guided: Bool = false

    func run() throws {

        // MARK: Prompts

        gPrint("The name of your sprout is the name that Sprout uses to find your package amongs all the other sprouts the user has installed.")
        gPrint("It should be unique and should be the same as the name of the folder that Git clones into.")
        var name = prompt("What is the package called: (\(Folder.current.name)) ")
        let websitePrompt = prompt("Where is your website: (if you have one) ")
        var website: URL?
        if !(websitePrompt.isEmpty) { website = URL(string: websitePrompt) }
        if name.isEmpty { name = Folder.current.name }
        var remote: String?
        do {
            remote = try shellOut(to: "git remote get-url origin")
            if remote!.hasPrefix("git@") {
                remote!.removeFirst(4)
                remote = "https://\(remote!)"
            }
        } catch {}
        gPrint("The Git URL is the prefered URL to clone from when grabbing the full repository.")
        gPrint("If your project uses an alias that is more update than your GitHub, this is a good place to put it.")
        gPrint("Note: The user can still chose to use your GitHub repo anyway.")
        var gitURLPrompt = prompt("What is the Git URL: (\(remote ?? "required")) ")
        if gitURLPrompt.isEmpty && remote == nil {
            print("Cannot use an empty or invalid Git URL"); Foundation.exit(1)
        } else if gitURLPrompt.isEmpty { gitURLPrompt = remote! }
        let gitURL = URL(string: gitURLPrompt)!
        gPrint("If you make a cli and there is only one cli that needs to be installed, built cli helps shorten your SproutFile.")
        gPrint("Built cli is the same as the install command install->bin. It copies the cli at the location provided to /usr/local/lib/sprout/bin where it is SymLinked to /usr/local/bin/")
        gPrint("Of course, this is only useful if your project is a cli, but if it's not (or you have multiple) you can just press enter.")
        var cliName: String? = prompt("Where is the built cli location: (if applicable) ")
        if cliName!.isEmpty { cliName = nil }

        // MARK: Generate SproutFile

        print("Generating SproutFile based on input.")
        var SproutFileString = """
        #!/usr/local/bin/sprout check --location

        % projectname: \(name)
        % giturl: \(gitURL)
        """
        if website != nil { SproutFileString.append("\n% website: \(website!)") }
        if cliName != nil { SproutFileString.append("\n% builtcli: \(cliName!)") }
        SproutFileString.append("""
        \n
        % build {

            # Build Commands Go Here

        }
        """)
        if cliName == nil { SproutFileString.append("""
        \n
        % install {

            # Install Commands Go Here

        }
        """) }
        do {
            let sproutFile = try Folder.current.createFile(at: "SproutFile")
            try sproutFile.write(SproutFileString)
        } catch let error as WriteError {
            print("Unable to create SproutFile")
            print(error.description)
        }
        print("Finished creating SproutFile!")
        gPrint("Now make sure to fill in the blanks (like build/install commands)")
        gPrint("And run \"sprout check\" to make sure everything is correct.")
        gPrint("You should also try \"sprout file://<drag-in-sproutfile>\" to make sure Sprout installs your package correctly.")
    }

    func gPrint(_ str: String) {
        if guided {
            print(str)
        }
    }

}
