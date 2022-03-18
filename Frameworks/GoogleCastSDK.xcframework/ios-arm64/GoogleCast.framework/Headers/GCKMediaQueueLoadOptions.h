// Copyright 2017 Google Inc.

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaCommon.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Options for loading media queue items with GCKRemoteMediaClient.
 *
 * @since 4.3
 */
GCK_EXPORT
@interface GCKMediaQueueLoadOptions : NSObject <NSCopying, NSSecureCoding>

/**
 * Designated initializer. Initializes a GCKMediaLoadOptions with default values for all properties.
 */
- (instancetype)init;

/**
 * The index of the item in the queue items array that should be played first.
 */
@property(nonatomic, assign) NSUInteger startIndex;

/**
 * The initial playback position for the first item in the queue items array when it is first
 * played, relative to the beginning of the stream. This value is ignored when the same item is
 * played again, for example when the queue repeats, or the item is later jumped to. In those
 * cases the item's startTime is used.
 */
@property(nonatomic, assign) NSTimeInterval playPosition;

/**
 * The repeat mode for playing the queue.
 */
@property(nonatomic, assign) GCKMediaRepeatMode repeatMode;

/**
 * Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 */
@property(nonatomic, strong, nullable) id customData;

@end

NS_ASSUME_NONNULL_END
