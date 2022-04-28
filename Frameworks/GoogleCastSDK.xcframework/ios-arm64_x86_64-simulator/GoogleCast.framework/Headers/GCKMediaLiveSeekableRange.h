#import <Foundation/Foundation.h>
#import <GoogleCast/GCKDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that aggregates information about seekable range of a media stream.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaLiveSeekableRange : NSObject <NSCopying, NSSecureCoding>

/**
 * The start time of seekable range, which ranges from 0 to @c endTime if available.
 */
@property(nonatomic, readonly) NSTimeInterval startTime;

/**
 * The end time of seekable range, which ranges from 0 to end of duration if available.
 */
@property(nonatomic, readonly) NSTimeInterval endTime;

/**
 * A flag indicating whether the current seek range is a fixed-length, moving window or a expanding
 * range.
 */
@property(nonatomic, readonly) BOOL isMovingWindow;

/**
 * A flag indicating whether the current live stream is done. It's updated to YES when live stream
 * finishes.
 */
@property(nonatomic, readonly) BOOL isLiveDone;

@end

NS_ASSUME_NONNULL_END
