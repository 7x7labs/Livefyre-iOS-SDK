# lf-client

## Getting Started

There are three ways to include LivefyreClient: using CocoaPods, using the
(possibly pre-built) framework, or by including it as a dependent project.

### Using the framework

#### Build the framework (optional)

	$ sudo gem install cocoapods
	$ pod setup
	$ pod install
	$ open LivefyreClient.xcodeproj

Set the target to Universal Framework (which device doesn't matter). Build. If
it fails, make sure it's using `clang` and not `llvm-gcc`. Right-click on
libLivefyreClient.a in Products and select Show in Finder to reveal the folder
containing LivefyreClient.framework.

#### Add the framework to a project

1. Drag LivefyreClient.framework into the Frameworks folder in the project
2. Select your project in the file navigator and click on the Build Phases
   tab.
3. Add the following libraries to Link Binary With Libraries:
    1. CFNetwork.framework
    2. MobileCoreServices.framework
    3. libz.dylib
    4. SystemConfiguration.framework
4. (optional) Move the added libraries to the Frameworks group

### Using CocoaPods

Install CocoaPods if needed:

	$ sudo gem install cocoapods
	$ pod setup

Create a Podfile. The minimum file required is:

    platform :ios, :deployment_target => '5.0'

    dependency 'Livefyre', :git => 'https://github.com/Livefyre/Livefyre-iOS-SDK.git'

Run `pod install <yourproject>.xcodeproj`.

Open the workspace. Select the Pods project, and under Build Settings set iOS
Deployment Target to iOS 5.0. Build.

## Building the example client

### Using CocoaPods

	$ sudo gem install cocoapods
	$ pod setup
  $ pod install PodExample.xcodeproj
  $ open PodExample.xcworkspace

Select the Pods project, and under Build Settings set iOS Deployment Target to
iOS 5.0. Set the target to ExampleClient. Build.

## With the Framework

Copy LivefyreClient.framework to ExampleClient/, building it if needed.

Open ExampleClient.xcodeproj, select the appropriate target, and build/run.

## With the library included as a dependent projet

Set up the library using CocoaPods, then open DirectExample.xcodeproj.
