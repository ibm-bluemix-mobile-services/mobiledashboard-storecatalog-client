import CoreLocation

class APIConnectDatasourceFilter : DatasourceFilter {
    func create(field: String, string: String?) -> StringFilter? {
        return APIConnectStringFilter(field: field, string: string)
    }

    func create(field: String, stringList: [String]) -> StringListFilter? {
        return APIConnectStringListFilter(field: field, list: stringList)
    }

    func create(field: String, number: NSNumber?) -> NumberFilter? {
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
    var number: NSNumber?

    init(field: String?, number: NSNumber?) {
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
