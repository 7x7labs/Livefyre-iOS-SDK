# Getting Started

## Adding the SDK to a project

1. Download a recent release of the SDK framework.
2. Open or create an iOS Xcode project
3. Switch to the Project Navigator (⌘1).
3. Drag the downloaded copy of LivefyreClient.framework into the Frameworks
   group in the project.
4. Click on the project in the Project Navigator.
5. Click on the Build Settings tab
6. Add -ObjC to Other Linker Flags
7. Click on the Build Phases tab
8. Add the following libraries to Link Binary With Libraries: (some may already
   be present)
    1. CFNetwork.framework
    2. MobileCoreServices.framework
    3. libz.dylib
    4. SystemConfiguration.framework
    5. MessageUI.framework
9. Move the added libraries to the Frameworks group
10. Import the SDK headers with #import <LivefyreClient/LivefyreClient.h> in
   either the prefix header or just the files which need it.
11. Build the project to verify that installation was successful.

## Using the SDK

A short example which initializes a collection for an anonymous user then logs
the most recent posts in the collection:

    // First import the SDK headers
    #import <LivefyreClient/LivefyreClient.h>

    @interface Example : NSObject
    @end

    @implementation Example
    - (void)entry {
        // The Livefyre network to use
        NSString *livefyreDomain = @"7x7-1.livefyre.co";
        // The secret key for the Livefyre network. If this is supplied, the client
        // can generate Livefyre user tokens for you. In this case, we're assuming
        // that the tokens are generated elsewhere.
        NSString *domainKey = nil;
        // The name of the environment to use, if not using production
        NSString *environment = @"t402.livefyre.com";

        // First create an instance of the client
        LivefyreClient *client = [LivefyreClient clientWithDomain:livefyreDomain
                                                      environment:environment
                                                        domainKey:domainKey];

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

The SDK has a very minimal sample client in the ExampleClient directory. To
build it, place a copy of the SDK framework in the ExampleClient directory,
then open ExampleClient.xcodeproj, set the target to ExampleClient > iPhone 5.1
Simulator, and build.

More interesting examples of using the API can be found in the tests.
testTwoUserPostingAndStream in LivefyreClientTests/LivefyreClientTests.m covers
much of the functionality of the library. The other files mostly have unit
tests operating on mock data, and so will probably be less interesting.

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
