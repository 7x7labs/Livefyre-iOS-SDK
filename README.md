# Livefyre-iOS-SDK

NOTE: This SDK is still under heavy development.  Kindly consider this code to
be alpha quality.

## Changelog

v0.1.0: Initial alpha version. Introduce `environment` and `bootstrapHost` parameters to be used when instantiating a LivefyreClient.

## Getting Started

### Adding the SDK to a project

1. Download a recent release of the SDK framework.
2. Open or create an iOS Xcode project
3. Switch to the Project Navigator (⌘1).
3. Drag the downloaded copy of LivefyreClient.embeddedframework into the Frameworks
   group in the project.
4. Click on the project in the Project Navigator.
5. Click on the Build Settings tab
6. Add -ObjC to Other Linker Flags
7. Click on the Build Phases tab
8. Add the following libraries to Link Binary With Libraries: (some may already
   be present)
    1. CFNetwork.framework
    2. MessageUI.framework
    3. MobileCoreServices.framework
    4. SystemConfiguration.framework
    5. libxml2.dylib
    6. libz.dylib
9. Move the added libraries to the Frameworks group
10. Import the SDK headers with #import <LivefyreClient/LivefyreClient.h> in
   either the prefix header or just the files which need it.
11. Build the project to verify that installation was successful.

### Using the SDK

The simplest way to use the SDK is to simply use the standard Livefyre
UI:

```Objective-C
// First import the SDK headers
#import <LivefyreClient/LivefyreClient.h>

// The view controller which will open the Livefyre comments screen
@implementation YourViewController
- (void)showLivefyre {
    // The ID of the article to show the comments of
    NSString *articleId = @"my-awesome-article";
    // The signed livefyre user token for the current user. Can be nil,
    // which will result in the user being unable to post their own comments.
    NSString *userToken = nil;

    // The following parameters are supplied by Livefyre when you sign up

    // The Livefyre network to use
    NSString *livefyreDomain = @"7x7-1.livefyre.co";
    // The ID of the site within the network
    NSString *siteId = @"303643"

    // The name of the environment to use
    NSString *environment = @"t402.livefyre.com";
    // The hostname for the bootstrap data
    NSString *bootstrapHost = @"http://bootstrap-json-dev.s3.amazonaws.com";
    // The above two may be nil for production environments

    // Display the modal view
    [LivefyreClient showModalUIInViewController:self
                                    article:articleId
                                       site:siteId
                                     domain:livefyreDomain
                                environment:environment
                              bootstrapHost:boostrapHost
                                  userToken:userToken];
}
@end
```

For more control, you can instead use the SDK to get access to the Livefyre
data and present it in a manner of your choice. A short example which
initializes a collection for an anonymous user then logs the most recent posts
in the collection:

```Objective-C
// First import the SDK headers
#import <LivefyreClient/LivefyreClient.h>

@interface Example : NSObject
@end

@implementation Example
- (void)entry {
    // The Livefyre network to use
    NSString *livefyreDomain = @"7x7-1.livefyre.co";

    // The name of the environment to use
    NSString *environment = @"t402.livefyre.com";
    // The hostname for the bootstrap data
    // Either or both of these can be set to nil or left out entirely to simply
    // use the production servers.
    NSString *bootstrapHost = @"http://bootstrap-json-dev.s3.amazonaws.com";

    // First create an instance of the client
    LivefyreClient *client = [LivefyreClient clientWithDomain:livefyreDomain
                                                bootstrapHost:boostrapHost
                                                  environment:environment];

    // As most of the client's operations require hitting the Livefyre servers
    // at some point, they all operate asynchronously, and rather than returning
    // a value they take a callback which is invoked with the result of the
    // operation on the GUI thread.

    // After creating an instance of the client, the next step is to initialize
    // a collection. Here we're getting the collection as an anonymous user, and
    // will be unable to create new posts or like existing posts. To get the
    // collection for a user, either fetch the user first with authenticateUser,
    // or replace forUser with forUserWithToken (or if a domain key was
    // supplied, forUserWithName).
    [client getCollectionForArticle:@"1"
                             inSite:@"303643"
                            forUser:nil
                      gotCollection:^(BOOL error, id resultOrError) {
                          if (error) {
                              // If getting the collection failed for any
                              // reason, error will be set to YES and
                              // resultOrError will contain an error message.
                              NSLog(@"error: %@", resultOrError);
                              return;
                          }

                          // Otherwise resultOrError will be the collection we
                          // asked for. Next, we'll get the posrs in the
                          // collection.
                          [self getPostsInCollection:resultOrError client:client];
                      }];
}

- (void)getPostsInCollection:(Collection *)collection client:(LivefyreClient *)client {
    // fetchBootstrap (and fetchPage and fetchRange) follow the same general
    // design as LivefyreClient's asynchronous methods.
    [collection fetchBootstrap:^(BOOL error, id resultOrError) {
        if (error) {
            NSLog(@"error: %@", resultOrError);
            return;
        }

        // We should now have the most recent posts available in the collection.
        // resultOrError is an array of the newly added posts, but we'll ignore
        // it for now in favor of getting them from the client directly.
        for (Post *post in collection.posts) {
            // As a simple example we'll just log each post in the collection
            [self printPost:post indent:0];
        }
    }];
}

- (void)printPost:(Post *)post indent:(int)indent {
    // Indent four spaces for each level of nesting
    NSString *indentStr = [@"" stringByPaddingToLength:(indent * 4) withString:@" " startingAtIndex:0];


    NSLog(@"%@Author: %@\n", indentStr, post.author.displayName);
    NSLog(@"%@Likes: %u\n", indentStr, [post.likes count]);
    NSLog(@"%@Body: %@\n\n", indentStr, post.body);

    // Recursively print replies to this post
    for (Post *reply in post.children) {
        [self printPost:reply indent:(indent + 1)];
    }
}
@end
```

## Documentation and Example Client Code

The SDK's API documentation can be accessed in three ways:

1. Online in your web browser at http://livefyre.github.com/Livefyre-iOS-SDK/.
2. Directly within Xcode. Open Xcode Preferences and switch to the
   Documentation tab. Click the + button and add the Livefyre iOS SDK feed:
   feed://TODO.atom
3. By generating the documentation directly from the source code. This requires
   appledoc, which is available with homebrew. Navigate to the LivefyreClient
   directory, then run `appledoc .`. The documentation will be generated into
   the `doc` directory and registered with Xcode.

The SDK has a simple sample client in the ExampleClient directory, which
supports displaying the comments for an article and making new comments if a
user token is supplied. To build it, first get a copy of the SDK framework and
place it in the ExampleClient directory. Then open ExampleClient.xcodeproj, set
the target to ExampleClient > iPhone 5.1 Simulator, and click the Run button to
build and run the app. Enter your Livefyre configuration paramters in the config
screen, then touch Save to load the collection.

## Building the SDK

Building the SDK requires Xcode 4.4 and [CocoaPods](http://cocoapods.org/),
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

### Running the tests

After building the SDK you will probably want to run the test suite to verify
that everything is working correctly, which can be done from within Xcode.
Change the compilation target to LivefyreClient > iPhone 5.1 Simulator, then
run the tests (Product > Test or ⌘U). You can open the Log Navigator by
pressing ⌘-7 to watch the test run output. The results should look something
like [this](http://i.imgur.com/85XNr.png).

The tests are a mixture of unit tests and integration tests which require
hitting remote servers, so it it possible that some may fail due to network
issues or remote changes.

## Using CocoaPods

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

## License
Copyright (c) 2012, Livefyre Inc

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.
* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.
* Neither the name of the <organization> nor the names of its contributors may
  be used to endorse or promote products derived from this software without
  specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
