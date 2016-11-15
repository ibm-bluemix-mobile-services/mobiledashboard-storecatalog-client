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
