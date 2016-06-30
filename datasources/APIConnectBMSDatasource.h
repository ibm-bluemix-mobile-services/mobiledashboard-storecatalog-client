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
