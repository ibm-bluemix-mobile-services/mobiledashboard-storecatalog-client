> **ATTENTION:** The UI starters have been deprecated and this sample no longer supported. Please visit [Bluemix](https://console.bluemix.net/developer/getting-started/) and choose a starter to add capabilities to download and start coding with a working project.

# Mobile Client for Bluemix
[![](https://img.shields.io/badge/bluemix-powered-blue.svg)](https://bluemix.net)

### IBM Mobile Dashboard Store Catalog iOS application
The Store Catalog Mobile Client provides instructions for how to integrate a **Bluemix Mobile** iOS Store Catalog application into your own [customized backend on Bluemix](https://github.com/ibm-bluemix-mobile-services/appbuilder-storecatalog-backend).

The backend uses the following IBM Bluemix services and runtime:

**Runtime**
* **API Connect** for a single point of REST integration using Loopback with Node.js

**Services**
* **Cloudant NoSQL DB** to hold a list products in a NoSQL database
* **Object Storage** to store product images
* **Mobile Client Access** for protecting resources
* **Push Notifications** for sending notifications to customers
* **Mobile Analytics** for monitoring trends and performance of the application

### Data architecture
<img src="readme/data.gif" alt="data architecture" width="400px"/>

## Getting started

The repository has a [datasources-swift/](datasources-swift) folder which shows how to modify the Store Catalog iOS application to retrieve data from your custom backend using **API Connect** as a single point of REST integration connected to the **Cloudant NoSQL DB** and **Object Storage** services on Bluemix.

### Before you begin
Ensure that you have:

* Provisioned your own [customized backend on Bluemix](https://github.com/ibm-bluemix-mobile-services/mobiledashboard-storecatalog-backend)

	<img src="readme/bluegen.gif" alt="bluegen" width="400px"/>


### Create the Mobile Dashboard Store Catalog iOS application

Click the **Try Bluemix** button to get started:

<a href="https://console.ng.bluemix.net/mobile/getting-started/" target="_blank"><img src="readme/try.png" alt="try button" width="150px"/></a>

1. Navigate to the Mobile area of Bluemix

	<img src="readme/getting-started.png" width="400px"/>

2. Click **Create Project** button

	<img src="readme/projects.png" width="400px"/>

3. Select the Store Catalog Starter

	<img src="readme/catalog.png" width="400px"/>

4. Add capabilities to your project

	<img src="readme/capabilities.png" width="400px"/>

	> **Note:** At this time, the Project page does not allow the reuse of existing service capabilities. The easiest way to use the service instances from your custom backend is adding new capabilities, and subsequently, replacing the credentials in your downloaded code's `BMSCredentials.plist` file with the credentials of the service instances you created while running `bluegen`.

4. Design the application

	<img src="readme/ui-builder.png" width="400px"/>

5. Get the source code for iOS in Swift and read accompanying README to install dependencies

	<img src="readme/code.png" width="400px"/>

6. Run the Store Catalog application in Xcode

	<img src="readme/xcode.png" width="400px"/>

### Next steps

Follow instructions in [datasources-swift/](datasources-swift) to change the datasource to your custom backend and retrieve data from **Cloudant NoSQL DB** and **Object Storage** services through **API Connect**.

### License
This package contains sample code provided in source code form. The samples are licensed under the Apache License, Version 2.0 (the "License"). You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0 and may also view the license in the license file within this package.
