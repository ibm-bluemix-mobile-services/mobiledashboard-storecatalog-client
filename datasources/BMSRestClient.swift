import Foundation
import BMSCore

public class BMSRestClient: NSObject {
    public static let appRoute = "http://storecatalogapic.mybluemix.net"
    public static let appGuid = "a106afbd-f622-4a6d-baa9-88dfbb421b6a"
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

        let request = Request.init(url: url,
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
                        success(NSArray.init(object: jsonResult))
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
