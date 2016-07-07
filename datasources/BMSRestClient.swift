import Foundation
import BMSCore

public class BMSRestClient: NSObject {
    // CHANGE CREDENTIALS HERE
    public static let appRoute = "REPLACE APP ROUTE INSIDE QUOTES"
    public static let appGuid = "REPLACE APP GUID INSIDE QUOTES"
		// Change the region if you are outside of the US
    public static let bluemixRegion = BMSClient.REGION_US_SOUTH

    public override init() {
        BMSClient.sharedInstance
            .initializeWithBluemixAppRoute(BMSRestClient.appRoute,
                                           bluemixAppGUID: BMSRestClient.appGuid,
                                           bluemixRegion: BMSRestClient.bluemixRegion)
    }

    public func get(url: String, parameters: NSDictionary?, success: ((NSArray) -> Void), failure: ((NSError?) -> Void)) {
        var queryParameters = [String : String]()
        for (key, value) in parameters! {
            queryParameters[key as! String] = value as? String
        }

        let request = Request(url: url,
                                   headers: nil,
                                   queryParameters: queryParameters,
                                   method: .GET,
                                   timeout: 30,
                                   cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData)

        request.sendWithCompletionHandler { (response, error) in
            if let error = error {
                failure(error)
            }
            else if let data = response?.responseData {
                do {
                    let jsonResult = try NSJSONSerialization.JSONObjectWithData(data, options: .MutableContainers)
                    if jsonResult is NSArray {
                        success(jsonResult as! NSArray)
                    }
                    else {
                        success(NSArray(object: jsonResult))
                    }

                } catch let jsonError as NSError {
                    failure(jsonError)
                }
            }
            else {
                success(NSArray())
            }
        }
    }
}
