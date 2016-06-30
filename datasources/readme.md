# Adding a new Datasource
This directory contains instructions on how to change the Mobile App Builder Store Catalog iOS application's datasource to a customized backend on Bluemix.

### Remove the current project configuration
1. Open project with Xcode
2. Select project in left navigator
3. Select info tab in project
4. Select "None" for all configurations options

### Add BMS Core using CocoaPods
1. Open terminal and navigate to app path
2. Create the pod file typing `pod init`
3. Edit the pod file, replacing 'Storecatalog' by your project name:

```ruby
platform :ios, '8.0'
use_frameworks!

target 'Storecatalog' do
    pod 'BMSCore', '~> 1.0'
end

target 'StorecatalogTests' do

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

### Install pods
Type `pod install` in your terminal.

A file **.xcworkspace** will be created in your project path. Open it in XCode.

### Create API Connect datasource

#### Create a Swift bridge class
In XCode, create a **BMSRestClient.swift** file at IOSApp, in the Datasources folder, with the following content, replacing appRoute, appGuide, and bluemixRegion with current values for your backend. These values can be recovered by navigating to your **Mobile Client Access** service instance on Bluemix and clicking the **Mobile Options** button. (Accept the creation of the Swift bridge):

```Swift
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
```

#### Compile project
The Objective-C classes are generated automatically.

#### Create a API Connect datasource implementation using the previous class
Create **APIConnectBMSDatasource.h** and **APIConnectBMSDatasource.m** files in Datasources folder and replace "Storecatalog" in the Swift import clause by your current project:

**APIConnectBMSDatasource.h**
```objectivec
#import <Foundation/Foundation.h>
#import "RODatasource.h"
#import "ROPagination.h"

@protocol ROSearchable;

@interface APIConnectBMSDatasource : NSObject <RODatasource, ROPagination>

@property (nonatomic, assign) Class objectsClass;
@property (nonatomic, strong) NSString *urlString;
@property (nonatomic, strong) NSString *resourceId;
@property (nonatomic, strong) NSObject<ROSearchable> *delegate;
@property (nonatomic, strong) NSString *searchField;

- (instancetype)initWithUrlString:(NSString *)urlString
                       resourceId:(NSString *)resourceId
                     objectsClass:(__unsafe_unretained Class)objectsClass;

+ (instancetype)datasourceWithUrlString:(NSString *)urlString
                             resourceId:(NSString *)resourceId
                           objectsClass:(__unsafe_unretained Class)objectsClass;

@end
```

**APIConnectBMSDatasource.m**
```objectivec
#import "APIConnectBMSDatasource.h"
#import "ROOptionsFilter.h"
#import "ROError.h"
#import "ROFilter.h"
#import "NSString+RO.h"
#import "ROSearchable.h"
#import "Storecatalog-Swift.h"

@interface APIConnectBMSDatasource ()

@property (nonatomic, strong) BMSRestClient *restClient;

@end

@implementation APIConnectBMSDatasource

static NSString *const kAPIConnectBMSConditionsParam       = @"filter";
static NSString *const kAPIConnectBMSSortParam             = @"order";
static NSString *const kAPIConnectBMSSkipParam             = @"skip";
static NSString *const kAPIConnectBMSLimitParam            = @"limit";
static NSString *const kAPIConnectBMSDistinctParam         = @"distinct";
static NSInteger const kAPIConnectBMSDataPageSize          = 20;

- (instancetype)initWithUrlString:(NSString *)urlString resourceId:(NSString *)resourceId objectsClass:(__unsafe_unretained Class)objectsClass {
    self = [super init];
    if (self) {
        _urlString = urlString;
        _resourceId = resourceId;
        _objectsClass = objectsClass;
        _restClient = [BMSRestClient new];
    }
    return self;
}

+ (instancetype)datasourceWithUrlString:(NSString *)urlString resourceId:(NSString *)resourceId objectsClass:(__unsafe_unretained Class)objectsClass {
    return [[self alloc] initWithUrlString:urlString
                                resourceId:resourceId
                              objectsClass:objectsClass];
}

#pragma mark - <RODatasource>

- (void)loadOnSuccess:(RODatasourceSuccessBlock)successBlock onFailure:(RODatasourceErrorBlock)failureBlock {
    [self loadWithOptionsFilter:nil onSuccess:successBlock onFailure:failureBlock];
}

- (void)loadWithOptionsFilter:(ROOptionsFilter *)optionsFilter onSuccess:(RODatasourceSuccessBlock)successBlock onFailure:(RODatasourceErrorBlock)failureBlock {
    NSMutableDictionary *requestParams = [self requestParams:optionsFilter];

    NSString *restAPIURL = [self.urlString stringByAppendingString:self.resourceId];

    [self.restClient get:restAPIURL parameters:requestParams success:^(NSArray *response) {
        if (successBlock) {
            NSMutableArray *responseArray = [response mutableCopy];
            NSMutableArray *itemArray = [[NSMutableArray alloc] init];

            for (NSDictionary *dic in responseArray) {
                [itemArray addObject:[[self.objectsClass alloc] initWithDictionary:dic]];
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                successBlock(itemArray);
            });
        }

    } failure:^(NSError *error) {
        if (failureBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                failureBlock(error, nil);
            });
        }
    }];
}

- (void)distinctValues:(NSString *)columnName filters:(NSArray *)filters onSuccess:(RODatasourceSuccessBlock)successBlock onFailure:(RODatasourceErrorBlock)failureBlock {
}

- (NSString *)imagePath:(NSString *)path {
    return path;
}

#pragma mark - <ROPagination>

- (NSInteger)pageSize {
    return kAPIConnectBMSDataPageSize;
}

- (void)loadPageNum:(NSInteger)pageNum onSuccess:(RODatasourceSuccessBlock)successBlock onFailure:(RODatasourceErrorBlock)failureBlock {
    [self loadPageNum:pageNum withOptionsFilter:nil onSuccess:successBlock onFailure:failureBlock];
}

- (void)loadPageNum:(NSInteger)pageNum withOptionsFilter:(ROOptionsFilter *)optionsFilter onSuccess:(RODatasourceSuccessBlock)successBlock onFailure:(RODatasourceErrorBlock)failureBlock {

    if (!optionsFilter) {
        optionsFilter = [ROOptionsFilter new];
    }

    NSInteger size = optionsFilter.pageSize ? [optionsFilter.pageSize integerValue] : [self pageSize];
    NSInteger skip = pageNum * size;
    [optionsFilter.extra setObject:@(skip)
                            forKey:kAPIConnectBMSSkipParam];

    [optionsFilter.extra setObject:@(size)
                            forKey:kAPIConnectBMSLimitParam];

    [self loadWithOptionsFilter:optionsFilter onSuccess:successBlock onFailure:failureBlock];
}

#pragma mark - Private methods

- (NSMutableDictionary *)requestParams:(ROOptionsFilter *)optionsFilter {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionaryWithDictionary:optionsFilter.extra];

    NSMutableArray *exps = [NSMutableArray new];
    NSArray *searchableFields;

    if (self.searchField) {
        searchableFields = [NSArray arrayWithObject:self.searchField];

    }
    else {
        if (self.delegate) {
            searchableFields = [self.delegate searchableFields];
        }
        else {
            searchableFields = [NSArray new];
        }
    }

    if (searchableFields && searchableFields.count > 0 && optionsFilter.searchText) {
        NSMutableArray* searches = [NSMutableArray new];
        for (int i = 0; i < searchableFields.count; i++) {
            [searches addObject:[NSString stringWithFormat:@"{\"%@\":{\"$regex\":\"%@\",\"$options\":\"i\"}}",
                                 searchableFields[i],
                                 optionsFilter.searchText
                                 ]];
        }
        [exps addObject:[NSString stringWithFormat:@"\"$or\":[%@]",
                         [searches componentsJoinedByString:@","]]];
    }

    for (NSObject<ROFilter> *filter in optionsFilter.filters) {
        NSString *qs = [filter getQueryString];
        if(qs) {
            [exps addObject:qs];
        }
    }

    if (optionsFilter.baseFilters && optionsFilter.baseFilters.count != 0) {
        NSMutableArray *baseFilters = [NSMutableArray new];
        for (NSObject<ROFilter> *filter in optionsFilter.baseFilters) {
            NSString *qs = [filter getQueryString];
            if (qs) {
                [baseFilters addObject:[NSString stringWithFormat:@"{%@}", qs]];
            }
        }
        if (baseFilters.count != 0) {
            [exps addObject:[NSString stringWithFormat:@"\"$and\":[%@]",
                             [baseFilters componentsJoinedByString:@","]]];
        }
    }

    NSMutableString *where = [NSMutableString new];
    if(exps.count > 0) {
        [where appendFormat:@"{%@}", [exps componentsJoinedByString:@","]];

        [where replaceOccurrencesOfString:@"{\"$regex\":"
                               withString:@""
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [where length])];


        [where replaceOccurrencesOfString:@",\"$options\":\"i\"}"
                               withString:@""
                                  options:NSLiteralSearch
                                    range:NSMakeRange(0, [where length])];
    }

    if (optionsFilter.sortColumn) {
        NSString *sortParam = [NSString stringWithFormat:@",\"%@\":\"%@ %@\"", kAPIConnectBMSSortParam, optionsFilter.sortColumn, optionsFilter.sortAscending ? @"ASC" : @"DESC"];
        [where appendString:sortParam];
    }

    for (NSString *key in optionsFilter.extra) {
        [where appendFormat:@",\"%@\":%@", key, [optionsFilter.extra objectForKey:key]];
    }

    [requestParams setObject:[NSString stringWithFormat:@"{\"where\":%@}", where]
                      forKey:kAPIConnectBMSConditionsParam];

    return requestParams;
}

@end
```

### Modify ProductDS using the previous datasource
Replace "Storecatalog" in the Swift import clause by your current project name:

**ProductsDS.h**
```objectivec
#import "RORestDatasource.h"
#import "ROSearchable.h"
#import "APIConnectBMSDatasource.h"

@interface ProductsDS : APIConnectBMSDatasource <ROSearchable>

@end
```

**ProductsDS.m**
```objectivec
#import "ProductsDS.h"
#import "ROUtils.h"
#import "NSString+RO.h"
#import "ProductsDSItem.h"
#import "Storecatalog-Swift.h"

@implementation ProductsDS

static NSString *const kResourceId = @"/api/Products";

- (instancetype)init {
    self = [super initWithUrlString:BMSRestClient.appRoute
                         resourceId:kResourceId
                       objectsClass:[ProductsDSItem class]];
    if (self) {
        self.delegate = self;
    }

    return self;
}

- (NSString *)imagePath:(NSString *)path {
    if ([path isUrl]) {
        return path;
    }

    return [NSString stringWithFormat:@"%@%@", BMSRestClient.appRoute, path];
}

#pragma mark - <ROSearchable>

- (NSArray *)searchableFields {
    return @[kProductsDSItemName, kProductsDSItemDescription, kProductsDSItemCategory, kProductsDSItemPrice, kProductsDSItemRating, kProductsDSItemId];
}

@end

```
