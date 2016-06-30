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
