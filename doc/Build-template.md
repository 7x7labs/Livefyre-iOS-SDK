# Building the SDK

Building the SDK requires Xcode 4.3 and [CocoaPods](http://cocoapods.org/),
which can be installed with the following commands:

    $ sudo gem install cocoapods
    $ pod setup

Next, to build the framework:

    $ git clone git://github.com/Livefyre/Livefyre-iOS-SDK.git
    $ cd Livefyre-iOS-SDK
    $ pod install
    $ open LivefyreClient.xcodeproj

Set the target to Universal Framework (which device doesn't matter). Build. If
it fails, make sure it's using `clang` and not `llvm-gcc`.

By default, Xcode places the output framework in a very well hidden location.
To find it easily, switch to the Project Navigator (⌘1), right-click
libLivefyreClient.a in the Products and select Show in Finder. The compiled
framework will be in the same directory.

## Running the tests

After building the SDK you will probably want to run the test suite to verify
that everything is working correctly, which can be done from within Xcode.
Change the compilation target to LivefyreClient > iPhone 5.1 Simulator, then
run the tests (Product > Test or ⌘U). You can open the Log Navigator by
pressing ⌘-7 to watch the test run output. The results should look something
like [this](http://i.imgur.com/85XNr.png).

The tests are a mixture of unit tests and integration tests which require
hitting remote servers, so it it possible that some may fail due to network
issues or remote changes.

## Documentation and Example Client Code

Building the documentation requires
[appledoc](https://github.com/tomaz/appledoc), which is available via
homebrew. Navigate to the LivefyreClient directory, then run `appledoc .`. The
documentation will be generated into the `doc` directory and registered with
Xcode.

The SDK has a very minimal sample client in the ExampleClient directory. To
build it, place a copy of the SDK framework in the ExampleClient directory,
then open ExampleClient.xcodeproj, set the target to ExampleClient > iPhone 5.1
Simulator, and build.

More interesting examples of using the API can be found in the tests.
testTwoUserPostingAndStream in LivefyreClientTests/LivefyreClientTests.m covers
much of the functionality of the library. The other files mostly have unit
tests operating on mock data, and so will probably be less interesting.

