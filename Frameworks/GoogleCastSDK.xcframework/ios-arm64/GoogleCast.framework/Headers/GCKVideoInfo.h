// Copyright 2016 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

/**
 * @enum GCKVideoInfoHDRType
 * An enum describing video HDR types.
 */
typedef NS_ENUM(NSInteger, GCKVideoInfoHDRType) {
  /** Unknown HDR type. */
  GCKVideoInfoHDRTypeUnknown = -1,
  /** Standard dynamic range. */
  GCKVideoInfoHDRTypeSDR = 0,
  /** Dolby Vision. */
  GCKVideoInfoHDRTypeDV = 1,
  /** High dynamic range. */
  GCKVideoInfoHDRTypeHDR = 2
};

NS_ASSUME_NONNULL_BEGIN

/**
 * A class representing video format details.
 *
 * @since 3.3
 */
GCK_EXPORT
@interface GCKVideoInfo : NSObject <NSCopying, NSSecureCoding>

/** The width of the video, in pixels. */
@property(nonatomic, assign, readonly) NSUInteger width;

/** The height of the video, in pixels. */
@property(nonatomic, assign, readonly) NSUInteger height;

/** The HDR type employed int the video, if any. */
@property(nonatomic, assign, readonly) GCKVideoInfoHDRType hdrType;

@end

NS_ASSUME_NONNULL_END
