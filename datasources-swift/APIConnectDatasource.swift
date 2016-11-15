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
