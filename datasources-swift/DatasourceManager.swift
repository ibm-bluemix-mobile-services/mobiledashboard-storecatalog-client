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
