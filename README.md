# Livefyre-iOS-SDK

NOTE: This SDK is still under heavy development.  Kindly consider this code to be alpha quality.

## Getting Started

If you'd like to see the Livefyre SDK in action, the simplest way to see something immediately is to build the SDK from scratch and run the associated unit tests direct from Xcode.  These aren't really "unit" tests as they will make calls to the Livefyre v3 test environment and run through most of the API calls we currently have implemented.

### Building The SDK

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

### Running The Tests
Once everything builds ok above, you can run the test suite from directly in Xcode.  Make sure you have the LivefyreClient project selected and then press Cmd-U to run the tests.  You can open the Log Navigator by pressing Cmd-7 to watch the test run output.  The results should look something like [this](http://i.imgur.com/85XNr.png).

The Livefyre client code is all contained in the LivefyreClient folder, so poke around in there if you'd like to take a look at how we wrapped the API.  And the LivefyreClientTests folder has the code you saw running in the previous test, so those are good examples of how you'd instantiate the client and make API calls.

Hopefully that should be enough to get you guys started taking a look at the SDK.




# [WIP] Ignore Everything Below Here

[ we're actively working on making a much, much better readme, and the stuff in this section is a work in progress. ]


## Framework Setup

The simplest way to get started with the Livefyre iOS SDK is with the prebuilt
framework.

1. Download or build LivefyreClient.framework
2. Open the project you wish to add the SDK to, and drag
   LivefyreClient.framework into the Frameworks folder in the project
3. Select your project in the file navigator and click on the Build Phases
   tab.
4. Add the following libraries to Link Binary With Libraries: (some may already
   be present)
    1. CFNetwork.framework
    2. MobileCoreServices.framework
    3. libz.dylib
    4. SystemConfiguration.framework
4. (optional) Move the added libraries to the Frameworks group

### Building the framework

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
it fails, make sure it's using `clang` and not `llvm-gcc`. Right-click on
libLivefyreClient.a in Products and select Show in Finder to reveal the folder
containing LivefyreClient.framework.

### Using CocoaPods

Rather than the framework, [CocoaPods](http://cocoapods.org/) can be used to
add the SDK to a project.

Install CocoaPods if needed:

  $ sudo gem install cocoapods
  $ pod setup

Create a Podfile. The minimum file required is:

    platform :ios, :deployment_target => '5.0'

    dependency 'Livefyre', :git => 'https://github.com/Livefyre/Livefyre-iOS-SDK.git'

Run `pod install <yourproject>.xcodeproj`.

Open the workspace. Select the Pods project, and under Build Settings set iOS
Deployment Target to iOS 5.0 or iOS 5.1. Build.

## Building the example client

### Using CocoaPods

  $ sudo gem install cocoapods
  $ pod setup
  $ pod install PodExample.xcodeproj
  $ open PodExample.xcworkspace

Select the Pods project, and under Build Settings set iOS Deployment Target to
iOS 5.0 or iOS 5.1. Set the target to ExampleClient. Build.

## With the Framework

Copy LivefyreClient.framework to ExampleClient/, building it if needed.

Open ExampleClient.xcodeproj, select the appropriate target, and build/run.

## With the library included as a dependent project

Set up the library using CocoaPods, then open DirectExample.xcodeproj.
