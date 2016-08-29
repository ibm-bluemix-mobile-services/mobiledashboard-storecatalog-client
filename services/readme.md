# Adding Bluemix Mobile services
This directory contains instructions on how to add the the Mobile Client Access and Mobile Analytics Swift Client SDKs to the Mobile Dashboard Store Catalog iOS application.

### Before you begin
Ensure that you have:
* Connected your datasource to your custom backend following the instructions [here](../datasources).
* Added **Push Notifications** to your application in the UI Builder.

### Setting up Bluemix Mobile services
Because Bluemix Mobile still generates UI Starters in Objective-C, there are a few steps we need to complete to add the Swift SDKs for each service.

The following sections will explain how to set up the **Mobile Client Access** and **Mobile Analytics** Swift SDKs for our iOS Store Catalog application.

#### Add Mobile services Swift SDKs using CocoaPods
1. Open terminal and navigate to app path
2. Edit the pod file, replacing "Storecatalog" by your project name:

[**Podfile**](Podfile)

```ruby
platform :ios, '8.0'
use_frameworks!

target 'storecatalog' do
    pod 'BMSSecurity', '~> 1.0'
    pod 'BMSAnalytics'
    pod 'BMSCore', '~> 1.0'
end

target 'storecatalogTests' do

end

# keeping the current configuration
post_install do |installer|
    installer.pods_project.targets.each do |target|
        puts "Updating #{target.name} OTHER_LDFLAGS"
        target.build_configurations.each do |config|
            xcconfig_path = config.base_configuration_reference.real_path
            xcconfig = File.read(xcconfig_path)
            new_xcconfig = xcconfig.sub('OTHER_LDFLAGS = $(inherited)', 'OTHER_LDFLAGS = $(inherited) -ObjC -l"xml2" -l"sqlite3" -l"z" -framework "CoreGraphics" -framework "CoreText" -framework "ImageIO" -framework "MediaPlayer" -framework "MobileCoreServices" -framework "QuartzCore" -framework "Security" -framework "SystemConfiguration" -framework "MapKit"')
            File.open(xcconfig_path, "w") { |file| file << new_xcconfig }
        end
    end
end
```

3. Perform a `pod install`

#### Add BMSDelegate.swift

We are going to add a `BMSDelegate.swift` file with some functions to interact with our Bluemix Mobile services. **Remember** to
replace your credentials after you copy the code into your project. You can get the `appRoute` and `appGuid` values by navigating
to your Mobile Client Access instance and clicking the **Mobile Options** tab. You can recover your `apikey` for Mobile Analytics
by going to your Mobile Analytics service instance and clicking the **Service Credentials** tab.

[**BMSDelegate.swift**](BMSDelegate.swift)

```swift
import Foundation

import BMSCore
import BMSSecurity
import BMSAnalytics


public class BMSDelegate: NSObject {
    /*
        CHANGE THESE VALUES to match your Bluemix backend. You can recover these values by
        clicking the Mobile Options button in your MCA service instance.
    */
    public static let appRoute = "REPLACE APP ROUTE INSIDE QUOTES"
    public static let appGuid = "REPLACE APP GUID INSIDE QUOTES"
    private static let bluemixRegion = BMSClient.REGION_US_SOUTH

    /*
        In our init function, we are going to connect to our backend on Bluemix.
    */
    public override init() {
        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(
                BMSDelegate.appRoute,
                bluemixAppGUID: BMSDelegate.appGuid,
                bluemixRegion: BMSDelegate.bluemixRegion)
    }

    /*
        In our mca function, we are going to make a REST request to a protected endpoint
        we set up on our Bluemix backend. This will automatically kick off the authorization
        process and if successful, will log the message from our Node.js server.
     */
    public func mca() {
        BMSClient.sharedInstance.authorizationManager = MCAAuthorizationManager.sharedInstance

        let request = Request(url: BMSDelegate.appRoute + "/api/Products/protected", method: HttpMethod.GET)
        request.sendWithCompletionHandler { (response, error) -> Void in
            if let error = error {
                print ("Error: \(error)")
            } else {
                print ("Response from our Bluemix instance: \(response?.responseText)")
            }
        }

    }

    /*
        In our anayltics function, we are going to authenticate with our Mobile Analytics service
        instance and send some data to it. After the data is sent, we can go back to our Mobile
        Anayltics service instance and look at our updated active users.
    */
    public func analytics() {
        Analytics.initializeWithAppName(
            "REPLACE APP NAME INSIDE QUOTES",
            apiKey: "REPLACE API KEY INSIDE QUOTES",
            deviceEvents: DeviceEvent.LIFECYCLE)

        Analytics.send();
    }

}
```

#### Call BMSDelegate.swift from AppDelegate.m

1. Add the following header to the top of the project to import the functions from `BMSDelegate.swift`:

```objectivec
#import "Storecatalog-Swift.h"
```

2. Add the code below in the `didFinishLaunchingWithOptions` to run the MCA and Mobile Analytics functions:

```objectivec
BMSDelegate *services = [BMSDelegate new];
[services mca];
[services analytics];
```

### Run the Store Catalog application in Xcode
Compile and run the Store Catalog application.

All of the code updates that we've just made should have the Store Catalog application now connecting to your protected endpoint and sending
analytics to your Mobile Analytics service instance on Bluemix.

### Future work
We are working to remove these manual steps in future releases of the new Mobile experience. In addition, we are working on better code generation in the Swift programming language for enhanced readability and improved support with our new Swift Client SDKs.

Stay tuned for updates.
