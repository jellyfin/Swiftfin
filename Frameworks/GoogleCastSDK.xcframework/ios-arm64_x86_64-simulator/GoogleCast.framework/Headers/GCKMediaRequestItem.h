
// Copyright 2017 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

#import <GoogleCast/GCKHLSSegmentFormat.h>

/**
 * @file GCKMediaRequestItem.h
 * GCKStreamingProtocolType enum.
 */

NS_ASSUME_NONNULL_BEGIN

/** Media streaming protocol types. */
typedef NS_ENUM(NSInteger, GCKStreamingProtocolType) {
  /** Unknown streaming protocol. CAF receivers won't precache if protocol is unknown. */
  GCKStreamingProtocolTypeUnknown = 0,
  /** MPEG DASH protocol. CAF receivers will precache DASH contents only if MPL is used. */
  GCKStreamingProtocolTypeMPEGDASH = 1,
  /** HLS protocol. */
  GCKStreamingProtocolTypeHLS = 2,
  /** Smooth Streaming protocol. */
  GCKStreamingProtocolTypeSmoothStreaming = 3,
};

/**
 * A class representing a request item sent to Cast receivers. It can be used for precaching media
 * contents.
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKMediaRequestItem : NSObject <NSCopying, NSSecureCoding>

/**
 * Helper to convert from <code>GCKHLSSegmentFormat</code> to <code>NSString</code>
 *
 * @since 4.1
 */
+ (NSString *)mapHLSSegmentFormatToString:(GCKHLSSegmentFormat)hlsSegmentFormat
    GCK_DEPRECATED("Use GCKHLSSegment::mapHLSSegmentFormatToString.");

/**
 * Helper to convert from <code>NSString</code> to <code>GCKHLSSegmentFormat</code>
 *
 * @since 4.1
 */
+ (GCKHLSSegmentFormat)mapHLSSegmentFormatStringToEnum:(NSString *)hlsSegmentFormatString
    GCK_DEPRECATED("Use GCKHLSSegment::mapHLSSegmentFormatStringToEnum.");

/**
 * Designated initializer. Initializes a GCKMediaRequestItem with URL, protocol type, initial time,
 * and HLS segment type.
 */
- (instancetype)initWithURL:(NSURL *)url
               protocolType:(GCKStreamingProtocolType)protocolType
                initialTime:(NSTimeInterval)initialTime
           hlsSegmentFormat:(GCKHLSSegmentFormat)hlsSegmentFormat;

/**
 * Convenience initializer. Initializes a GCKMediaRequestItem with URL and protocol type and use
 * default values for other properties.
 */
- (instancetype)initWithURL:(NSURL *)url protocolType:(GCKStreamingProtocolType)protocolType;

/**
 * The URL of media content.
 */
@property(nonatomic, strong) NSURL *mediaURL;

/**
 * The media streaming protocol.
 */
@property(nonatomic, assign) GCKStreamingProtocolType protocolType;

/**
 * The initial time of media to precache. The default is 0.0.
 */
@property(nonatomic, assign) NSTimeInterval initialTime;

/**
 * The HLS segment format. It's required if protocolType == GCKStreamingProtocolTypeHLS. The default
 * is GCKHLSSegmentFormatUndefined.
 */
@property(nonatomic, assign) GCKHLSSegmentFormat hlsSegmentFormat;

@end

NS_ASSUME_NONNULL_END
