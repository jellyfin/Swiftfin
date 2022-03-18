#import <Foundation/Foundation.h>

#import <GoogleCast/GCKDefines.h>

/**
 * @file GCKHLSVideoSegmentFormat.h
 * GCKHLSVideoSegmentFormat enum.
 */

NS_ASSUME_NONNULL_BEGIN

/** HLS video segment types. */
typedef NS_ENUM(NSInteger, GCKHLSVideoSegmentFormat) {
  /** Undefined. Used when streaming protocol is not HLS. */
  GCKHLSVideoSegmentFormatUndefined = 0,
  /** HLS segment type MPEG2 TS. */
  GCKHLSVideoSegmentFormatMPEG2_TS = 1,
  /** HLS segment type FMP4. */
  GCKHLSVideoSegmentFormatFMP4 = 2,
};

/**
 * Class that provides helpers to convert between @c GCKHLSVideoSegmentFormat and
 * @c NSString.
 */
GCK_EXPORT
@interface GCKHLSVideoSegment : NSObject

/**
 * Helper method to convert from @c GCKHLSVideoSegmentFormat to @c NSString.
 *
 * @return NSString The string value corresponding to @c GCKHLSVideoSegmentFormat. @c nil for @c
 * GCKHLSVideoSegmentFormatUndefined and invalid enum values.
 *
 * @since 4.6.0
 */
+ (nullable NSString *)mapHLSVideoSegmentFormatToString:
    (GCKHLSVideoSegmentFormat)hlsVideoSegmentFormat;

/**
 * Helper method to convert from @c to @c GCKHLSVidoeSegmentFormat. The
 * comparison is case insensitive.
 *
 * @return GCKHLSVideoSegmentFormat The corresponding @c GCKHLSVideoSegmentFormat enum value. @c
 * GCKHLSVideoSegmentFormatUndefined for invalid string.
 *
 * @since 4.6.0
 */
+ (GCKHLSVideoSegmentFormat)mapHLSVideoSegmentFormatStringToEnum:
    (NSString *)hlsVideoSegmentFormatString;

@end

NS_ASSUME_NONNULL_END
