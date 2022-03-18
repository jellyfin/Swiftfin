// Copyright 2012 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Utility methods for working with JSON data.
 */
GCK_EXPORT
@interface GCKJSONUtils : NSObject

/**
 * Parses a JSON string into an object.
 *
 * @param json The JSON string to parse.
 * @return The root object of the object hierarchy that represents the data (either an
 * <a href="https://goo.gl/q3tY5n"><b>NSArray</b></a> or an
 * <a href="https://goo.gl/0kFoNp"><b>NSDictionary</b></a>), or <code>nil</code> if the parsing
 * failed.
 */
+ (nullable id)parseJSON:(NSString *)json;

/**
 * Parses a JSON string into an object.
 *
 * @param json The JSON string to parse.
 * @param error If not nil, the location at which to store a pointer to an
 * <a href="https://goo.gl/WJbrdL"><b>NSError</b></a> if the parsing fails.
 * @return The root object of the object hierarchy that represents the data (either an
 * <a href="https://goo.gl/q3tY5n"><b>NSArray</b></a> or an
 * <a href="https://goo.gl/0kFoNp"><b>NSDictionary</b></a>), or <code>nil</code> if the parsing
 * failed.
 */
+ (nullable id)parseJSON:(NSString *)json error:(NSError **)error;

/**
 * Writes an object hierarchy of data to a JSON string.
 *
 * @param object The root object of the object hierarchy to encode. This must be either an
 * <a href="https://goo.gl/q3tY5n"><b>NSArray</b></a> or an
 * <a href="https://goo.gl/0kFoNp"><b>NSDictionary</b></a>.
 * @return An <a href="https://goo.gl/5dXzU6"><b>NSString</b></a> containing the JSON encoding, or
 * <code>nil</code> if the data could not be encoded.
 */
+ (NSString *)writeJSON:(id)object;

/**
 * Tests if two JSON strings are equivalent. This does a deep comparison of the JSON data in the
 * two strings, but ignores any differences in the ordering of keys within a JSON object. For
 * example, <code>{ "width":64, "height":32 }</code> is considered to be equivalent to
 * <code>{ "height":32, "width":64 }</code>.
 */
+ (BOOL)isJSONString:(NSString *)actual equivalentTo:(NSString *)expected;

/**
 * Tests if two JSON objects are equivalent. This does a deep comparison of the JSON data in the
 * two objects, but ignores any differences in the ordering of keys within a JSON object. For
 * example, <code>{ "width":64, "height":32 }</code> is considered to be equivalent to
 * <code>{ "height":32, "width":64 }</code>.
 */
+ (BOOL)isJSONObject:(id)actual equivalentTo:(id)expected;

@end

NS_ASSUME_NONNULL_END
