// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@class GCKMultizoneDevice;

NS_ASSUME_NONNULL_BEGIN

/**
 * The status of a multizone group.
 *
 * @since 3.1
 */
GCK_EXPORT
@interface GCKMultizoneStatus : NSObject <NSCopying, NSSecureCoding>

/** The member devices of the multizone group. */
@property(nonatomic, copy, readonly) NSArray<GCKMultizoneDevice *> *devices;

/** Initializes the object with the given JSON data. */
- (instancetype)initWithJSONObject:(id)JSONObject
    GCK_DEPRECATED("GCKMultizoneStatus should only be initialized internally.");

/** Initializes the object with the given list of member devices. */
- (instancetype)initWithDevices:(NSArray<GCKMultizoneDevice *> *)devices
    GCK_DEPRECATED("GCKMultizoneStatus should only be initialized internally.");

- (instancetype)init NS_UNAVAILABLE;

@end  // GCKMultizoneStatus

NS_ASSUME_NONNULL_END
