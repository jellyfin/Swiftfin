// Copyright 2017 Google Inc.

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaCommon.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Options for seeking within media with GCKRemoteMediaClient.
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKMediaSeekOptions : NSObject <NSCopying, NSSecureCoding>

/**
 * Designated initializer. Initializes a GCKMediaSeekOptions with default values for all properties.
 */
- (instancetype)init;

/**
 * The time interval by which to seek. The default value is <code>0</code>.
 */
@property(nonatomic, assign) NSTimeInterval interval;

/**
 * Whether the time interval is relative to the current stream position (<code>YES</code>) or to the
 * beginning of the stream (<code>NO</code>). The default value is <code>NO</code>, indicating an
 * absolute seek position.
 */
@property(nonatomic, assign) BOOL relative;

/**
 * The action to take after the seek operation has finished. The default value is
 * GCKMediaResumeStateUnchanged.
 */
@property(nonatomic, assign) GCKMediaResumeState resumeState;

/**
 * Whether seek to end of stream or live.
 *
 * @since 4.4.1
 */
@property(nonatomic, assign) BOOL seekToInfinite;

/**
 * Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 */
@property(nonatomic, strong, nullable) id customData;

@end

NS_ASSUME_NONNULL_END
