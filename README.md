# Sprout Package Manager
A simple package installer (for anything) made in Swift.

**NOTE:** Sprout is a work in progress. There are several features I am working on adding.

## What is Sprout
Sprout is a simple package installer for any CLI, similar to brew.

Sprout is inspired by Mint, but designed for broader use cases.

## Usage
### Installing a package
Sprout is used simply by running:
```shell
sprout user/repo
```

### Making a package
To create a Sprout package start by creating a SproutFile:
```
#!/usr/local/bin/sprout check --location
# ^ 100% optional, but I thought it's kind of funny you can do that.


% projectname: SwiftTests
% cliname: swift-tests
% builtcli: .build/release/swifttests
% giturl: https://github.com/BenSova/SwiftTests.git
% webpage: https://bensova.github.io/SwiftTests

% build {

# a comment
swift build -c release
# another-commented-out-command

% }
```
Some notes:
- Whitespace at the beginning of a line will not be ignored (as of right now)
- `cliname` and `webpage` are optional.
- All options may not have spaces (the last word will be used) (as of right now)

## Installation
You can install Sprout with Mint:
```shell
mint install BenSova/sprout
```
(Alternatives coming...)
