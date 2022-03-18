// Copyright 2012 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A category that adds some convenience methods to
 * <a href="https://goo.gl/ZtiYbw"><b>NSDictionary</b></a> for setting values of various types.
 * These methods are particularly useful for getting and setting fields of JSON data objects.
 */
@interface NSMutableDictionary (GCKAdditions)

/**
 * Sets an <a href="https://goo.gl/5dXzU6"><b>NSString</b></a> value for a key.
 *
 * @param value The value.
 * @param key The key.
 */
- (void)gck_setStringValue:(NSString *)value forKey:(NSString *)key;

/**
 * Sets an <a href="https://goo.gl/hQFeav"><b>NSInteger</b></a> value for a key.
 *
 * @param value The value.
 * @param key The key.
 */
- (void)gck_setIntegerValue:(NSInteger)value forKey:(NSString *)key;

/**
 * Sets an <a href="https://goo.gl/hQFeav"><b>NSUInteger</b></a> value for a key.
 *
 * @param value The value.
 * @param key The key.
 */
- (void)gck_setUIntegerValue:(NSUInteger)value forKey:(NSString *)key;

/**
 * Sets a <b>double</b> value for a key.
 *
 * @param value The value.
 * @param key The key.
 */
- (void)gck_setDoubleValue:(double)value forKey:(NSString *)key;

/**
 * Sets a <b>BOOL</b> value for a key.
 *
 * @param value The value.
 * @param key The key.
 */
- (void)gck_setBoolValue:(BOOL)value forKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
