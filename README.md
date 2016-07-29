This sample is deprecated as there is a new API for ReCap
=======================
Go to https://developer.autodesk.com/en/docs/reality-capture/v1/overview/ for more information


[![ReCap API](https://img.shields.io/badge/Recap%20API-3.1.0-blue.svg)](http://developer-recap-autodesk.github.io/)
[![CocoaPods](https://img.shields.io/badge/cocoapods-0.39.0-blue.svg)](https://cocoapods.org/)
![Xcode](https://img.shields.io/badge/Xcode-7.2.1-green.svg)
![Platforms (El Capitan)](https://img.shields.io/badge/platform-iOS%209.x-lightgray.svg)
[![License](http://img.shields.io/:license-mit-blue.svg)](http://opensource.org/licenses/MIT)


The iOS sample
=======================

<b>Note:</b> For using those samples you need a valid oAuth credential and a ReCap client ID. Visit this [page](http://developer-recap-autodesk.github.io/) for instructions to get on-board.


Dependencies
--------------------
This sample is dependent of five 3rd party assemblies which are already installed are ready to compile in the project. 
You can update/install them automatically via CocoaPods. Visit http://cocoapods.org/ for installing / using CocoaPods.

1. The RestKit pod

     RestKit is a framework for consuming and modelling RESTful web resources on iOS and OS X.
	 you need at least version 0.26.0. pod 'RestKit', '~> 0.26.0'
	 http://cocoapods.org/?q=restkit

2. The ZipKit pod

     An Objective-C Zip framework for Mac OS X and iOS.
	 you need at least version 1.0.3. pod 'ZipKit', '1.0.3'
	 http://cocoapods.org/?q=zipkit


3. The AFOAuth1Client pod

     AFNetworking Extension for OAuth 1.0a Authentication.
	 you need at least version 1.0.0. pod 'AFOAuth1Client', '1.0.0'
	 http://cocoapods.org/?q=AFOAuth1Client

	 
each pod comes with their own dependencies, but cocoapods will manage them for you.
	 
Building the sample
---------------------------
CocoaPods 1.0.0.beta.6 is available.
To update use: `gem install cocoapods --pre`

The sample was updated to use Xcode 7.2.1, but should build/work fine with any 5.x or 6.x version with appropriate changes. It also target iOS version 9.x, but can be ported back up to iOS 6.0 (not tested or originally written for iOS 7.x). 

  1. You first need to modify (or create) the UserSettings.h file and put your oAuth / ReCap credentials in it.
     There is a iOSReCap/iOSReCap/_UserSettings.h file that you can copy to create your own version.

     cp iOSReCap/iOSReCap/_UserSettings.h iOSReCap/iOSReCap/UserSettings.h

  2. Install the LibComponentLogging cocoa pods dependency using the following command:

     pod repo add lcl https://github.com/aharren/LibComponentLogging-CocoaPods-Specs.git

  3. The first time, you need to install the dependencies using cocoa pods. For this you need [cocoapods](http://guides.cocoapods.org/using/getting-started.html#toc_3) installed on your machine, and run the pods command below:

     pod install

  4. Next, you need to configure the LibComponentLogging pod, but running the following commands:

     chmod -R aog+w *
     Pods/LibComponentLogging-pods/configure/lcl_configure pod
     chmod -R aog+w *

  5. Open the LCLLogFileConfig.h file, and change the <UniquePrefix> into a unique ID of yours. i.e. MyTestApp for example

  6. Patch the files as documented in the patch section below. Or use the ones provided in the sample using the following command

     cp -R Patched-Files/* Pods/

  7. Load the Autodesk-ReCap-Samples.xcworkspace in Xcode.

  8. Select the Pods project, Pods-autodesk-oAuth target, Build Phases, Link Binary With Libraries, and add the libAFOAuth1Client.a

  9. The first time you are going to build the sample, it will fail ! the reason is that the sample also
     demonstrate how to build frameworks to be reused in other projects.
     As it needs both simulator and real device binaries and because cocoapods do not automate building both
     version at once, you need to switch from a simulator scheme to a real device scheme once and build each.
     That will force the pods to build in each scheme, and then you can build the project.

     a. Select the iOSReCap project with one of the simulator scheme, and build. This build will fail, but it is ok for now.

     b. Switch to your device scheme (or default ‘iOS Device’ scheme), and build. This time, the build will be successful and you can now use a simulator scheme or device scheme without any problem.


Patch Pods files
---------------------------
If you install or update the pods to a new version, you will also need to patch few files. If you downloaded the source from the DevTech GitHub repo, just ignore these instructions.

  a. in Pods/AFNetworking/AFNetworking/AFHTTPClient.h line #305, add the following

        - (NSMutableURLRequest *)multipartFormRequestWithMethodAllSigned:(NSString *)method
                                   path:(NSString *)path
                             parameters:(NSDictionary *)parameters
              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

  b. in Pods/AFNetworking/AFNetworking/AFHTTPClient.m line #548, add the following

        - (NSMutableURLRequest *)multipartFormRequestWithMethodAllSigned:(NSString *)method
                                   path:(NSString *)path
                             parameters:(NSDictionary *)parameters
              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
        {
            NSParameterAssert(method);
            NSParameterAssert(![method isEqualToString:@"GET"] && ![method isEqualToString:@"HEAD"]);
	
            NSMutableURLRequest *request = [self requestWithMethod:method path:path parameters:parameters];
	
            __block AFStreamingMultipartFormData *formData = [[AFStreamingMultipartFormData alloc] initWithURLRequest:request stringEncoding:self.stringEncoding];
	
            if (parameters) {
                for (AFQueryStringPair *pair in AFQueryStringPairsFromDictionary(parameters)) {
                    NSData *data = nil;
                    if ([pair.value isKindOfClass:[NSData class]]) {
                        data = pair.value;
                    } else if ([pair.value isEqual:[NSNull null]]) {
                        data = [NSData data];
                    } else {
                        data = [[pair.value description] dataUsingEncoding:self.stringEncoding];
                    }
			
                    if (data) {
                        [formData appendPartWithFormData:data name:[pair.field description]];
                    }
                }
            }
	
            if (block) {
                block(formData);
            }
	
            return [formData requestByFinalizingMultipartFormData];
        }

  e. In Pods/RestKit/Code/Network/RKObjectManager.h line #396, add the following

        - (NSMutableURLRequest *)multipartFormRequestWithObjectAllSigned:(id)object
                                method:(RKRequestMethod)method
                                  path:(NSString *)path
                            parameters:(NSDictionary *)parameters
             constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block;

  f. In Pods/RestKit/Code/Network/RKObjectManager.m line #529, add the following

        - (NSMutableURLRequest *)multipartFormRequestWithObjectAllSigned:(id)object
                                                 method:(RKRequestMethod)method
                                                   path:(NSString *)path
                                             parameters:(NSDictionary *)parameters
                              constructingBodyWithBlock:(void (^)(id <AFMultipartFormData> formData))block
        {
            NSString *requestPath = (path) ? path : [[self.router URLForObject:object method:method] relativeString];
            id requestParameters = [self mergedParametersWithObject:object method:method parameters:parameters];
            NSMutableURLRequest *multipartRequest = [self.HTTPClient multipartFormRequestWithMethodAllSigned:RKStringFromRequestMethod(method)
                                                                                       path:requestPath
                                                                                 parameters:requestParameters
                                                                  constructingBodyWithBlock:block];
            return multipartRequest;
        }
	 
Use of the sample
-------------------------

* when you launch the sample, the application will try to connect to the ReCap server and verifies that you are properly authorised on the Autodesk oAuth server. 
If you are, it will refresh your access token immediately. If not, it will ask you to get authorised.

The sample will show you the list of project(s) you get on your account. If you select one, it will open and display the commands and Photoscene' properties.
If you do not have a project yet, then press the '+' button to create one. It will appear selected automatically.

* Project View - There is 5 commands

   * Refresh - will refresh the project properties
   * Camera - to take photos - the sample will create an album in your 'Camera Roll' with the PhotosceneID as name. You can take as many photo you want.
   ReCap Photo needs a minimum of 4 photos to run, and usually 40 are enough for a 360 view of an object. You can also use the standard camera application 
   to create your photos, this command is just for convenience.
   * Photos - select photos and upload them on the ReCap Photo Server. There is a progress bar to show you when the upload is completed.
   * Process - will launch the Photoscene to create the mesh. There is a progress bar to show you when the Server has completed the process.
   Once it is done, you may need to use the Refresh command to verify it was successful or not.
   * Preview - the last command is to download and preview the resulting mesh on the device.
   
* Camera view

   * You can zoom in/out with 2 fingers Pinch as usual
   * Tap once anywhere to take a photo
   * Swipe to left to exit the camera mode
   
* Preview view

   * Tap once to auto animate (or stop)
   * Pan one finger to orbit the mesh
   * Pan two fingers to pan the mesh
   * You can zoom in/out with 2 fingers Pinch as usual
   * Swipe to left to exit the preview mode

   
To be implemented

   * Wait icon at start when the application is getting your Project list
   * Double Tap in preview view to create a screenshot
   * Logout button
   
   
--------
Written by Cyrille Fauvel (Autodesk Developer Network)  
http://www.autodesk.com/adn  
http://around-the-corner.typepad.com/  
