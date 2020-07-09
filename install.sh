#!/bin/bash
set -e

if [[ "$(uname)" = "Darwin" ]]; then
    echo Starting install of Sprout.
else
    echo Unable to run Sprout on non-macos computers.
fi

echo Creating Directories...

mkdir ~/.sprout
mkdir ~/.sprout/repos
mkdir ~/.sprout/bin

echo Created Directories.

echo Cloning Sprout...

git clone https://github.com/SwiftStars/Sprout ~/.sprout/repos/Sprout

echo Cloned Sprout

cd ~/.sprout/repos/Sprout

echo Building Sprout

swift build -c release

echo Built Sprout

echo Installing Sprout

cp -f .build/release/sprout ~/.sprout/bin/sprout
ln -s ~/.sprout/bin/sprout /usr/local/bin/sprout

echo Finished installing Sprout
