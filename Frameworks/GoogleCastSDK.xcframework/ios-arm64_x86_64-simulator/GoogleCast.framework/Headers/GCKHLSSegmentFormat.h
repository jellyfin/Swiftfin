#import <Foundation/Foundation.h>

#import <GoogleCast/GCKDefines.h>

/**
 * @file GCKHLSSegmentFormat.h
 * GCKHLSSegmentFormat enum.
 */

NS_ASSUME_NONNULL_BEGIN

/** HLS segment types. */
typedef NS_ENUM(NSInteger, GCKHLSSegmentFormat) {
  /** Undefined. Used when streaming protocol is not HLS. */
  GCKHLSSegmentFormatUndefined = 0,
  /** HLS segment type AAC. */
  GCKHLSSegmentFormatAAC = 1,
  /** HLS segment type AC3. */
  GCKHLSSegmentFormatAC3 = 2,
  /** HLS segment type MP3. */
  GCKHLSSegmentFormatMP3 = 3,
  /** HLS segment type TS. */
  GCKHLSSegmentFormatTS = 4,
  /** HLS segment type TS AAC. */
  GCKHLSSegmentFormatTS_AAC = 5,
  /** HLS segment type E AC3. */
  GCKHLSSegmentFormatE_AC3 = 6,
  /** HLS segment type FMP4. */
  GCKHLSSegmentFormatFMP4 = 7,
};

/**
 * Class that provides helpers to convert between @c GCKHLSSegmentFormat and
 * @c NSString.
 */
GCK_EXPORT
@interface GCKHLSSegment : NSObject

/**
 * Helper method to convert from @c GCKHLSSegmentFormat to @c NSString.
 *
 * @return NSString The string value corresponding to @c GCKHLSSegmentFormat. @c nil for @c
 * GCKHLSSegmentFormatUndefined and invalid enum values.
 *
 * @since 4.6.0
 */
+ (nullable NSString *)mapHLSSegmentFormatToString:(GCKHLSSegmentFormat)hlsSegmentFormat;

/**
 * Helper method to convert from @c NSString to @c GCKHLSSegmentFormat. The
 * comparison is case insensitive.
 *
 * @return GCKHLSSegmentFormat The corresponding @c GCKHLSSegmentFormat enum value. @c
 * GCKHLSSegmentFormatUndefined for invalid string.
 *
 * @since 4.6.0
 */
+ (GCKHLSSegmentFormat)mapHLSSegmentFormatStringToEnum:(NSString *)hlsSegmentFormatString;

@end

NS_ASSUME_NONNULL_END
