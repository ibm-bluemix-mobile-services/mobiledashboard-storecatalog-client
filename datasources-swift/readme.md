# Adding a new Datasource
This directory contains instructions on how to change the Mobile Dashboard Store Catalog iOS application's datasource to a customized backend on Bluemix.

### Before you begin
Ensure that you have:
* [Xcode](https://itunes.apple.com/us/app/xcode/id497799835?mt=12) Version >= 8.0
* [CocoaPods](https://cocoapods.org/) Version >= 1.1.0.rc.2

  `sudo gem install cocoapods --pre`

### Add BMS Core using CocoaPods
1. Open terminal and navigate to app path
2. Add the latest `BMSCore` dependency

  `pod 'BMSCore', '~> 2.0'`

3. Install the dependencies by running the commands

  ```bash
  pod update
  pod install
  ```

4. A file **.xcworkspace** will be created in your project path. Open it in Xcode.

### Create API Connect datasource

Create and modify the following four files in your **Datasources** folder on Xcode. Remember to replace the `baseUrl` variable in **DatasourceConfig.swift** with your bluegen backend route.

[**APIConnectDatasource.swift**](APIConnectDatasource.swift)

```swift
import Foundation

class APIConnectDatasource <T:Item> {

    let kAPIConnectDatasourceSort         = "order"
    let kAPIConnectDatasourceSkip         = "skip"
    let kAPIConnectDatasourceLimit        = "limit"
    let kAPIConnectDatasourceConditions   = "filter"
    let kAPIConnectDatasourceDistinct     = "distinct"

    var baseUrl: String!
    var resource: String?
    var searchableFields: [String]?

    var restClient: HttpClient<T>

    var progress:((Int64, Int64, Int64) -> Void)?

    let filter = APIConnectDatasourceFilter()

    init(baseUrl: String, resource: String, searchableFields : [String]) {
        self.baseUrl = baseUrl
        self.resource = resource
        self.searchableFields = searchableFields
        restClient = HttpClient<T>()
    }

    func requestParameters(options: DatasourceOptions?) -> [String : AnyObject] {
        var params: [String: AnyObject] = [:]

        guard let datasourceOptions = options else {
            return params
        }

        // Sort options
        if datasourceOptions.sortOptions.count != 0 {
            let sortOptions = datasourceOptions.sortOptions[0]
            if var sortField = sortOptions.field,
                let sortAscending = sortOptions.ascending {
                if !sortAscending {
                    sortField.insert("-", atIndex: sortField.startIndex.advancedBy(0))
                }
                params[kAPIConnectDatasourceSort] = sortField
            }
        }

        var conditions: [String] = []

        // Search text
        if let searchText = datasourceOptions.searchText,
            let searchableFields = searchableFields {

            var searches: [String] = []
            for field in searchableFields {
                let q = "{\"\(field)\":{\"like\":\"\(searchText)\"}}"
                searches.append(q)
            }
            conditions.append("\"or\":[\(searches.joinWithSeparator(","))]")
        }

        // Runtime filters
        if datasourceOptions.filters.count != 0 {
            for filter in datasourceOptions.filters {
                if let filterQuery = filter.filter() {
                    conditions.append(filterQuery)
                }
            }
        }

        // Design filters
        if datasourceOptions.designFilters.count != 0 {
            var filters: [String] = []
            for filter in datasourceOptions.designFilters {
                if let filterQuery = filter.filter() {
                    filters.append("{\(filterQuery)}")
                }
            }
            if filters.count != 0 {
                conditions.append("\"and\":[\(filters.joinWithSeparator(","))]")
            }
        }

        let skip = datasourceOptions.limit * datasourceOptions.skip

        var condition = "\"\(kAPIConnectDatasourceSkip)\":\(skip),\"\(kAPIConnectDatasourceLimit)\":\(datasourceOptions.limit)"

        if conditions.count != 0 {
            condition += ",\"where\":{\(conditions.joinWithSeparator(","))}"
        }

        params[kAPIConnectDatasourceConditions] = "{\(condition)}"

        return params
    }

    func loadData<T>(parameters: [String : AnyObject]?, success: (([T]) -> Void), failure: ((NSError?) -> Void)) {
        if let baseUrl = baseUrl, resource = resource {
            let url = "\(baseUrl)\(resource)"
            restClient.get(url, parameters: parameters, success: { (response) in
                if response is [T] {
                    AnalyticsManager.sharedInstance?.analytics?.logAction("read", entity:String(T))
                    success(response as! [T])
                } else {
                    let error = ErrorManager.mapping(response)
                    AnalyticsManager.sharedInstance?.logger?.log(String(error), level: .Error)
                    failure(error)
                }
                } , failure: failure, progress: progress)
        } else {

            let error = ErrorManager.invalidUrl()
            AnalyticsManager.sharedInstance?.logger?.log(String(error), level: .Error)
            failure(error)
        }
    }
}

extension APIConnectDatasource : Datasource {
    var datasourceFilter: DatasourceFilter {
        return filter
    }

    func imagePath(path: String?) -> String? {
        guard let path = path else {
            return nil
        }

        if path.isUrl() {
            return path
        }

        return "\(baseUrl)\(path)"
    }

    func refreshData<T>(options: DatasourceOptions?, success: (([T]) -> Void), failure: ((NSError?) -> Void)) {
        //TODO: clear cache
        if let options = options {
            options.skip = 0
        }
        loadData(options, success: success, failure: failure)
    }

    func loadData<T>(options: DatasourceOptions?, success: (([T]) -> Void), failure: ((NSError?) -> Void)) {
        let parameters = requestParameters(options)

        loadData(parameters, success: success, failure: failure)
    }

    func loadData<T>(identifier: AnyObject?, success: ((T?) -> Void), failure: ((NSError?) -> Void)) {
        if let baseUrl = baseUrl, resource = resource, identifier = identifier {
            let url = "\(baseUrl)\(resource)/\(identifier)"
            restClient.get(url, parameters: nil, success: { (response) in
                success(response as? T)
                }, failure: failure, progress: progress)
        } else {
            failure(ErrorManager.invalidUrl())
        }
    }

    func distinctValues(name: String, filters: [Filter]?, success: (([String]) -> Void), failure: ((NSError?) -> Void)) {
        let options = DatasourceOptions()
        if let filters = filters {
            options.designFilters.appendContentsOf(filters)
        }

        loadData(options, success: { (response: [T]) in
            var values : [String] = []

            for item in response {
                for property in Mirror(reflecting: item).children {
                    guard let key = property.label else {
                        continue
                    }
                    guard let value = self.unwrap(property.value) else {
                        continue
                    }
                    if(key == name) {
                        if(values.indexOf(value) == nil) {
                            values.append(value)
                        }
                        break
                    }
                }
            }

            success(values)
            }, failure: failure)
    }

    private func unwrap(subject: Any) -> String? {
        var value: String?
        let mirrored = Mirror(reflecting:subject)
        if mirrored.displayStyle != .Optional {
            value = String(subject)
        } else if let firstChild = mirrored.children.first {
            value = String(firstChild.value)
        }
        return value
    }
}

extension APIConnectDatasource: CRUD {

    func create<T>(params: [String : AnyObject], success: ((T?) -> Void), failure: ((NSError?) -> Void)) {
        if let baseUrl = baseUrl, resource = resource {
            let url = "\(baseUrl)\(resource)"
            restClient.post(url, parameters: params, success: { (response) in
                AnalyticsManager.sharedInstance?.analytics?.logAction("created", entity:String(T))
                success(response as? T)
                } , failure: failure, progress: progress)

        } else {
            invalidUrl(failure)
        }
    }

    func read<T>(identifier: AnyObject?, success: ((T?) -> Void), failure: ((NSError?) -> Void)) {
        loadData(identifier, success: success, failure: failure)
    }

    func update<T>(identifier: AnyObject?, params: [String : AnyObject], success: ((T?) -> Void), failure: ((NSError?) -> Void)) {
        if let baseUrl = baseUrl, resource = resource, identifier = identifier as? String {
            if identifier.isEmpty {
                failure(ErrorManager.invalidUrl())
            } else {
                let url = "\(baseUrl)\(resource)/\(identifier)"
                restClient.put(url, parameters: params, success: { (response) in

                    AnalyticsManager.sharedInstance?.analytics?.logAction("updated", entity:String(T), identifier: String(identifier))

                    success(response as? T)

                    } , failure: failure, progress: progress)
            }
        } else {
            invalidUrl(failure)
        }
    }

    func delete<T>(identifier: AnyObject?, success: ((T?) -> Void), failure: ((NSError?) -> Void)) {
        if let baseUrl = baseUrl, resource = resource, identifier = identifier as? String {
            if identifier.isEmpty {
                failure(ErrorManager.invalidUrl())
            } else {

                let url = "\(baseUrl)\(resource)/\(identifier)"
                restClient.delete(url, parameters: nil, success: { (response) in
                    AnalyticsManager.sharedInstance?.analytics?.logAction("deleted", entity:String(T), identifier: String(identifier))

                    success(response as? T)

                    } , failure: failure, progress: progress)
            }

        } else {
            invalidUrl(failure)
        }
    }

    func invalidUrl(failure: ((NSError?) -> Void)) {
        let error = ErrorManager.invalidUrl()
        AnalyticsManager.sharedInstance?.logger?.log(String(error), level: .Error)
        failure(error)
    }
}
```

[**APIConnectDatasourceFilter.swift**](APIConnectDatasourceFilter.swift)

```swift
import CoreLocation

class APIConnectDatasourceFilter : DatasourceFilter {
    func create(field: String, string: String) -> StringFilter? {
        return APIConnectStringFilter(field: field, string: string)
    }

    func create(field: String, stringList: [String]) -> StringListFilter? {
        return APIConnectStringListFilter(field: field, list: stringList)
    }

    func create(field: String, number: Double) -> NumberFilter? {
        return APIConnectNumberFilter(field: field, number: number)
    }

    func create(field: String, dateMin: NSDate?, dateMax: NSDate?) -> DateRangeFilter? {
        return APIConnectDateRangeFilter(field: field, dateMin: dateMin, dateMax: dateMax)
    }
}

extension APIConnectDatasourceFilter: DatasourceGeoFilter {
    func create(field: String, neCorrd: CLLocationCoordinate2D, swCoord: CLLocationCoordinate2D) -> GeoBoundingBoxFilter? {
        return CloudGeoBoundingBoxFilter(field: field, neCoord: neCorrd, swCoord: swCoord)
    }

    func create(field: String, coord: CLLocationCoordinate2D) -> GeoNearFilter? {
        return CloudGeoNearFilter(field: field, coord: coord)
    }
}

class APIConnectStringFilter: StringFilter {

    var field: String!
    var value: AnyObject?
    var string: String?

    init(field: String?, string: String?) {

        self.field = field
        self.string = string
    }

    func filter() -> String? {
        guard let f = field, s = string else {
            return nil
        }

        return "\"\(f)\":{\"like\":\"\(s)\"}"
    }
}

class APIConnectStringListFilter: StringListFilter {

    var field: String!
    var value: AnyObject?
    var list: [String]?

    init(field: String?, list: [String]?) {
        self.field = field
        self.list = list
    }

    func filter() -> String? {
        guard let f = field, l = list else {
            return nil
        }

        return "\"\(f)\":{\"inq\":[\"\(l.joinWithSeparator("\",\""))\"]}"
    }
}

class APIConnectNumberFilter : NumberFilter {

    var field: String!
    var value: AnyObject?
    var number: Double?

    init(field: String?, number: Double?) {
        self.field = field
        self.number = number
    }

    func filter() -> String? {
        guard let f = field, n = number else {
            return nil
        }

        return "\"\(f)\": \(n)"
    }
}

class APIConnectDateRangeFilter : DateRangeFilter {

    var field: String!
    var value: AnyObject?
    var dateMin: NSDate?
    var dateMax: NSDate?

    lazy var formatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.timeZone = NSTimeZone(abbreviation: "GMT")
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter
    }()

    init(field: String?, dateMin: NSDate?, dateMax: NSDate?) {
        self.field = field
        self.dateMin = dateMin
        self.dateMax = dateMax
    }

    func filter() -> String? {
        guard let f = field else {

            return nil
        }

        var paths: [String] = []

        if let dMin = dateMin {
            paths.append("\"gt\":\"\(formatter.stringFromDate(dMin))\"")
        }

        if let dMax = dateMax {
            paths.append("\"lt\":\"\(formatter.stringFromDate(dMax))\"")
        }

        guard paths.count != 0 else {
            return nil
        }

        return "\"\(f)\":{\(paths.joinWithSeparator(","))}"
    }
}

class APIConnectGeoBoundingBoxFilter : GeoBoundingBoxFilter {

    var field: String!
    var value: AnyObject?
    var neCoord: CLLocationCoordinate2D?
    var swCoord: CLLocationCoordinate2D?

    init(field: String?, neCoord: CLLocationCoordinate2D?, swCoord: CLLocationCoordinate2D?) {
        self.field = field
        self.neCoord = neCoord
        self.swCoord = swCoord
    }

    func filter() -> String? {
        return nil
    }
}

class APIConnectGeoNearFilter : GeoNearFilter {

    var field: String!
    var value: AnyObject?
    var coord: CLLocationCoordinate2D?

    init(field: String?, coord: CLLocationCoordinate2D?) {
        self.field = field
        self.coord = coord
    }

    func filter() -> String? {
        guard let f = field, c = coord else {
            return nil
        }

        return "\"\(f)\":{\"near\": \(c.longitude),\(c.latitude)}"
    }
}
```

[**DatasourceConfig.swift**](DatasourceConfig.swift)

```swift
import Foundation

 enum DatasourceConfig {

	enum Cloud {
		// Replace your baseURL to your bluegen backend (e.g. https://example.mybluemix.net)
		static let baseUrl = "REPLACE WITH YOUR BLUEGEN BACKEND ROUTE"

		enum ProductsDS{
            static let resource = "/api/Products"
		}

		enum ContactScreen1DS{

			static let resource = "/app/582b67eea64a600400c65a5d/r/contactScreen1DS"
			static let apiKey = "Hnze3DeT"
		}
	}


}
```

[**DatasourceManager.swift**](DatasourceManager.swift)

```swift
import Foundation

class DatasourceManager {
    static let sharedInstance = DatasourceManager()
    lazy var ProductsDS: APIConnectDatasource<ProductsDSItem> = {
        return APIConnectDatasource<ProductsDSItem>(baseUrl: DatasourceConfig.Cloud.baseUrl,
                                                    resource: DatasourceConfig.Cloud.ProductsDS.resource,
                                                    searchableFields: [ProductsDSItemMapping.name, ProductsDSItemMapping.description, ProductsDSItemMapping.category, ProductsDSItemMapping.price, ProductsDSItemMapping.rating])
    }()

    lazy var ContactScreen1DS: CloudDatasource<ContactScreen1DSItem> = {
        return CloudDatasource<ContactScreen1DSItem>(baseUrl: DatasourceConfig.Cloud.baseUrl,
                                                     resource: DatasourceConfig.Cloud.ContactScreen1DS.resource,
                                                     apikey: DatasourceConfig.Cloud.ContactScreen1DS.apiKey,
                                                     searchableFields: [ContactScreen1DSItemMapping.address, ContactScreen1DSItemMapping.phone, ContactScreen1DSItemMapping.email])
    }()
}
```


### Run the Store Catalog application in Xcode

Remember to replace your `baseUrl` variable in **DatasourceConfig.swift** and compile and run the Store Catalog application.

All of the code updates that we've just made should have the Store Catalog application now retrieving data from our customized backend on Bluemix.

> **Note:** If you update the images in your customized backend, the old pictures may still be cached in your emulator or device. Make sure you reset the device to ensure the new images are being added to the Store Catalog. Also, at this time, you will have to restart your Bluemix application when you redeploy data to the **Cloudant NoSQL DB** database. This is because **API Connect** needs to reconnect to your datasource.
