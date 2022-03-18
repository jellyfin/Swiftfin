// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDynamicDevice.h>

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A member device of a multizone group.
 *
 * @since 3.1
 */
GCK_EXPORT
@interface GCKMultizoneDevice : GCKDynamicDevice <NSCopying, NSSecureCoding>

/** The device volume level. */
@property(nonatomic, assign, readonly) float volumeLevel;

/** Whether the device is muted. */
@property(nonatomic, assign, readonly) BOOL muted;

- (instancetype)init NS_UNAVAILABLE;

@end  // GCKMultizoneDevice

NS_ASSUME_NONNULL_END
