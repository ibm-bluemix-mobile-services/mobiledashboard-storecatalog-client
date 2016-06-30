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
