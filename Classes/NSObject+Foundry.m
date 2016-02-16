//
//  NSObject+Foundry.m
//  
//
//  Created by John Tumminaro on 4/21/14.
//
//

#import "NSObject+Foundry.h"
#import <Gizou/Gizou.h>
#import <objc/runtime.h>

@interface TGFoundryGlobal

+ (NSDateFormatter*)foundryDateFormatter;

@end

@implementation TGFoundryGlobal

+ (NSDateFormatter*)foundryDateFormatter
{
    static NSDateFormatter* sharedFormatter = nil;
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^
                  {
                      sharedFormatter = [[NSDateFormatter alloc] init];
                      if (!sharedFormatter)
                      {
                          NSException*    exception = [NSException exceptionWithName:@"Foundry Exception"
                                                                              reason:@"sharedFormatter is missing!"
                                                                            userInfo:nil];
                          @throw exception;
                      }
                  });
    
    return sharedFormatter;
}

@end

@implementation NSObject (Foundry)

+ (instancetype)foundryBuild
{
    return [self foundryBuildWithAttributes:@{}];
}

+ (instancetype)foundryBuildWithAttributes:(NSDictionary*)attributes
{
    [self foundryWillBuildObject];
    id newObject = [[self alloc] init];
    
    NSDictionary *finalAttributes = [newObject foundryAttributesWithAttributes:attributes];

    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList([self class], &outCount);
    for (i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        const char *propName = property_getName(property);
        if(propName) {
            NSString *propertyName = [NSString stringWithUTF8String:propName];
            NSString *attribute = finalAttributes[propertyName];
            if (attribute && ![attribute isEqual:[NSNull null]]) {
                [newObject setValue:attribute forKey:propertyName];
            }
        }
    }
    free(properties);
    [self foundryDidBuildObject:newObject];
    return newObject;
}

+ (NSArray *)foundryBuildNumber:(NSUInteger)number
{
    return [self foundryBuildNumber:number
                     withAttributes:@{}];
}

+ (NSArray *)foundryBuildNumber:(NSUInteger)number
                 withAttributes:(NSDictionary*)attributes
{
    NSMutableArray *returnArray = [NSMutableArray new];
    for (int i = 0; i < number; i++) {
        [returnArray addObject:[self foundryBuildWithAttributes:attributes]];
    }
    
    return [NSArray arrayWithArray:returnArray];
}

+ (NSDictionary *)foundryBuildSpecs
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

+ (NSDictionary *)foundryAttributes
{
    return [self foundryAttributesWithAttributes:@{}
                                       andObject:nil
                                     andWithSpec:[self foundryBuildSpecs]];
}

+ (NSDictionary *)foundryAttributesWithAttributes:(NSDictionary*)attributes {
    return [self foundryAttributesWithAttributes:attributes
                                       andObject:nil
                                     andWithSpec:[self foundryBuildSpecs]];
}

+ (NSDictionary *)foundryAttributesWithAttributes:(NSDictionary*)attributes
                                        andObject:(id)newObject
                                      andWithSpec:(NSDictionary*)spec
{
    NSMutableDictionary *attributesDict = [attributes mutableCopy];
    NSArray*    keys = [[spec allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    for (NSString *key in keys) {
        if (!attributesDict[key]) {
            FoundryPropertyType type = [spec[key] integerValue];
            
            switch (type) {
                case FoundryPropertyTypeFirstName:
                    [attributesDict setObject:[GZNames firstName] forKey:key];
                    break;
                case FoundryPropertyTypeLastName:
                    [attributesDict setObject:[GZNames lastName] forKey:key];
                    break;
                case FoundryPropertyTypeFullName:
                    [attributesDict setObject:[GZNames name] forKey:key];
                    break;
                case FoundryPropertyTypeAddress:
                    [attributesDict setObject:[GZLocations streetAddress] forKey:key];
                    break;
                case FoundryPropertyTypeStreetName:
                    [attributesDict setObject:[GZLocations streetName] forKey:key];
                    break;
                case FoundryPropertyTypeCity:
                    [attributesDict setObject:[GZLocations city] forKey:key];
                    break;
                case FoundryPropertyTypeState:
                    [attributesDict setObject:[GZLocations state] forKey:key];
                    break;
                case FoundryPropertyTypeStateCode:
                    [attributesDict setObject:[GZLocations stateCode] forKey:key];
                    break;
                case FoundryPropertyTypeZipCode:
                    [attributesDict setObject:[GZLocations zipCode] forKey:key];
                    break;
                case FoundryPropertyTypeCountry:
                    [attributesDict setObject:[GZLocations country] forKey:key];
                    break;
                case FoundryPropertyTypeLatitude:
                {
                    [attributesDict setObject:[NSNumber numberWithDouble:[GZLocations latitude]] forKey:key];
                }
                    break;
                case FoundryPropertyTypeLongitude:
                {
                    [attributesDict setObject:[NSNumber numberWithDouble:[GZLocations longitude]] forKey:key];
                }
                    break;
                case FoundryPropertyTypeEmail:
                    [attributesDict setObject:[GZInternet email] forKey:key];
                    break;
                case FoundryPropertyTypeURL:
                    [attributesDict setObject:[GZInternet url] forKey:key];
                    break;
                case FoundryPropertyTypeipV4Address:
                    [attributesDict setObject:[GZInternet ipV4Address] forKey:key];
                    break;
                case FoundryPropertyTypeipV6Address:
                    [attributesDict setObject:[GZInternet ipv6Address] forKey:key];
                    break;
                case FoundryPropertyTypeLoremIpsumShort:
                    [attributesDict setObject:[GZWords sentence] forKey:key];
                    break;
                case FoundryPropertyTypeLoremIpsumMedium:
                    [attributesDict setObject:[GZWords paragraph] forKey:key];
                    break;
                case FoundryPropertyTypeLoremIpsumLong:
                    [attributesDict setObject:[GZWords paragraphs] forKey:key];
                    break;
                case FoundryPropertyTypePhoneNumber:
                    [attributesDict setObject:[GZPhoneNumbers phoneNumber] forKey:key];
                    break;
                case FoundryPropertyTypeDate:
                    [attributesDict setObject:[NSDate dateWithTimeIntervalSince1970:arc4random_uniform(36500) * 86400] forKey:key];
                    break;
                case FoundryPropertyTypeBoolean:
                    [attributesDict setObject:(arc4random_uniform(1) ? @YES : @NO) forKey:key];
                    break;
                case FoundryPropertyTypeUUID:
                    [attributesDict setObject:[[NSUUID UUID] UUIDString] forKey:key];
                    break;
                case FoundryPropertyTypeCustom:
                {
                    // Skip until second pass
                    break;
                }
                    
                case FoundryPropertyTypeTimezoneName:
                {
                    NSArray<NSString*>* items  = [NSTimeZone knownTimeZoneNames];
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeWeekdaySymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].weekdaySymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeShortWeekdaySymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].shortWeekdaySymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeVeryShortWeekdaySymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].veryShortWeekdaySymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeStandaloneWeekdaySymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].standaloneWeekdaySymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeShortStandaloneWeekdaySymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].shortStandaloneWeekdaySymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeVeryShortStandaloneWeekdaySymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].veryShortStandaloneWeekdaySymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeMonthSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].monthSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeShortMonthSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].shortMonthSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeVeryShortMonthSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].veryShortMonthSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeStandaloneMonthSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].standaloneMonthSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeShortStandaloneMonthSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].shortStandaloneMonthSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeVeryShortStandaloneMonthSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].veryShortStandaloneMonthSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeQuarterSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].quarterSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeShortQuarterSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].shortQuarterSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeStandaloneQuarterSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].standaloneQuarterSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeShortStandaloneQuarterSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].shortStandaloneQuarterSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeEraSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].eraSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                case FoundryPropertyTypeLongEraSymbol:
                {
                    NSArray<NSString*>* items  = [TGFoundryGlobal foundryDateFormatter].longEraSymbols;
                    [attributesDict setObject:items[arc4random_uniform(items.count)] forKey:key];
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
    
    for (NSString *key in keys) {
        if (!attributesDict[key]) {
            FoundryPropertyType type = [spec[key] integerValue];
            
            switch (type) {
                case FoundryPropertyTypeCustom:
                {
                    id  value = [self foundryAttributeForProperty:key
                                                       withObject:newObject
                                                    andAttributes:attributesDict];
                    if (value)
                    {
                        [attributesDict setObject:value forKey:key];
                    }
                    break;
                }

                default:
                    break;
            }
        }
    }
    
    return [NSDictionary dictionaryWithDictionary:attributesDict];
}

+ (NSArray *)foundryAttributesNumber:(NSUInteger)number
{
    return [self foundryAttributesNumber:number
                          withAttributes:@{}];
}

+ (NSArray *)foundryAttributesNumber:(NSUInteger)number
                      withAttributes:(NSDictionary*)attributes
{
    NSMutableArray *returnArray = [NSMutableArray new];
    for (int x = 0; x < number; x++) {
        [returnArray addObject:[self foundryAttributesWithAttributes:attributes]];
    }
    
    return [NSArray arrayWithArray:returnArray];
}

+ (void)foundryWillBuildObject
{
    // Override and customize
}

+ (void)foundryDidBuildObject:(id)object
{
    // Override and customize
}

- (NSDictionary *)foundryAttributes
{
    return [[self class] foundryAttributesWithAttributes:@{}
                                               andObject:self
                                             andWithSpec:[[self class] foundryBuildSpecs]];
}

- (NSDictionary *)foundryAttributesWithAttributes:(NSDictionary*)attributes {
    return [[self class] foundryAttributesWithAttributes:attributes
                                               andObject:self
                                             andWithSpec:[[self class] foundryBuildSpecs]];
}

@end
