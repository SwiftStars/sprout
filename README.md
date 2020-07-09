# Sprout
A simple client for installing your GitHub project onto Macs.

## What is Sprout?
Sprout is a CLI that clones and installs your repo onto the your users computer, using your build and install commands.

Sprout supports any kind of project you have for Macs, as long as you can install it with shell commands. You can make a CLI, app, system library, driver, a combination of those, or something else.

Some nice terms to know:
- Sprout (with capital S) is this project.
- A sprout (with lowercase s) is your project.

## How to use Sprout
### Installing a sprout
To install a sprout, all you have to do is run:
```shell
sprout user/repo
```
Which will assume the repo is at `github.com/user/repo`.
If the sprout you are installing is not of GitHub, you will have to link to the raw SproutFile, like this:
```shell
sprout https://raw.githubusercontent.com/user/repo/master/SproutFile
```
**Tip:** The SproutFile link works even if the SproutFile is on your local repo, so you can test the installation process of your sprout without posting any changes. You can even put in the SproutFile to clone your local project.
```shell
sprout file://<drag-in-SproutFile>
```

Other end user commands:
```shell
sprout uninstall
```
```shell
sprout detail
```
```shell
sprout list
```

### Making a sprout
Making a sprout is as simple as adding a SproutFile to your project.
```SproutFile
#!/usr/local/bin/sprout check --location
# ^ Not required, but might (not) be useful

% projectname: Sprout
# % builtcli: .build/release/sprout
% giturl: https://github.com/SwiftStars/sprout.git
# % snapto: latest

% build {

    swift build -c release

% }

% install {

    install->bin .build/release/sprout

}
```
```shell
$ sprout check
SproutFile passed checks.
```
**Notes:** (some will to change)
- None of the `%` values can have spaces...
- `projectname` should be the same as the name of the directory git clones into.
- `giturl` is compared to the user's input and will ask if the user wants use their or your url.
- `builtcli` is the same as the install action `install->bin` and will run before install actions.
- `snapto` (coming soon) will snap the version of your project to a given value (like `latest`, v2.0, `branch->master`, `beta`...)
- There is also a `webpage` option.
- `uninstall`, `preinstall`, `postinstall` are coming soon.
- `install->bin` and `install->app` are both custom commands.
- Commands are run in `sh`. If you want them to run in a different shell, write `<shell> -c "<command>"`
- Pushing your own output is coming. (This would be text or command output).

## Contributing
Feel free to contribute! I don't have a set vision for Sprout yet, so anything is welcome.

## Installable with Sprout
Well, you can't install anything (that I know of) with sprout yet (other than Sprout and my [SwiftTests](https://github.com/BenSova/SwiftTests)). That does not mean Sprout is not a good idea for your project. The more people that use Sprout, the more it gets discovered, the more people use Sprout...

```shell
sprout BenSova/SwiftTests
swift tests
```
```shell
sprout SwiftStars/Sprout
sprout <subcommand>/<url>
```

# Installation
Simply run:
```shell
mint install SwiftStars/sprout
```
```shell
/bin/bash -c $(curl -fsSL https://raw.githubusercontent.com/user/repo/master/install.sh)
```
Alternatives coming... (Sprout is not currently eligible for Homebrew)
