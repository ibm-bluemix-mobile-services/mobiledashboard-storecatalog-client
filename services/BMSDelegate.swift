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
