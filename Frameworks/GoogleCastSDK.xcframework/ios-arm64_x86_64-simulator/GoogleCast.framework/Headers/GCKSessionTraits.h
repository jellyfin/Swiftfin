// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An object describing the traits and capabilities of a session.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKSessionTraits : NSObject <NSCopying, NSSecureCoding>

/**
 * The minimum volume value. Must be non-negative and less than or equal to the maximum volume.
 */
@property(nonatomic, assign, readonly) float minimumVolume;

/**
 * The maximum volume value. Must be non-negative and greater than or equal to the minimum volume.
 */
@property(nonatomic, assign, readonly) float maximumVolume;

/**
 * The volume increment for up/down volume adjustments. May be 0 to indicate fixed volume. Must
 * be non-negative and less than or equal to the difference between the maximum volume and minimum
 * volume.
 */
@property(nonatomic, assign, readonly) float volumeIncrement;

/**
 * Whether the audio can be muted.
 */
@property(nonatomic, assign, readonly) BOOL supportsMuting;

/**
 * Designated initializer.
 */
- (instancetype)initWithMinimumVolume:(float)minimumVolume
                        maximumVolume:(float)maximumVolume
                      volumeIncrement:(float)volumeIncrement
                       supportsMuting:(BOOL)supportsMuting NS_DESIGNATED_INITIALIZER;

/**
 * Convenience initializer. Sets the volume range to [0.0, 1.0], the volume increment to 0.05 (5%),
 * and the supportsMuting flag to <code>YES</code>.
 */
- (instancetype)init;

/**
 * Whether this is a fixed volume device.
 */
- (BOOL)isFixedVolume;

@end

NS_ASSUME_NONNULL_END
