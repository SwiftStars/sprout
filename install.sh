#!/bin/bash
set -e

if [[ "$(uname)" = "Darwin" ]]; then
    echo Starting install of Sprout.
else
    echo Unable to run Sprout on non-macos computers.
fi

echo Creating Directories...

mkdir /usr/local/lib/sprout
mkdir /usr/local/lib/sprout/repos
mkdir /usr/local/lib/sprout/bin

echo Created Directories.

echo Cloning Sprout...

git clone https://github.com/SwiftStars/Sprout /usr/local/lib/sprout/repos/Sprout

echo Cloned Sprout

cd /usr/local/lib/sprout/repos/Sprout

echo Building Sprout

swift build -c release

echo Built Sprout

echo Installing Sprout

cp -f .build/release/sprout /usr/local/lib/sprout/bin/sprout
ln -s /usr/local/lib/sprout/bin/sprout /usr/local/bin/sprout

echo Finished installing Sprout
