// Copyright 2016 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

/**
 * @file GCKUIImageHints.h
 * GCKMediaMetadataImageType enum
 */

#import <GoogleCast/GCKDefines.h>

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKMediaMetadataImageType
 * Enum defining a media metadata image type.
 *
 * @since 3.0
 */
typedef NS_ENUM(NSInteger, GCKMediaMetadataImageType) {
  /** An image used by a custom view provided by the application. */
  GCKMediaMetadataImageTypeCustom = 0,
  /** An image used in the Cast dialog, which appears when tapping the Cast button. */
  GCKMediaMetadataImageTypeCastDialog = 1,
  /** An image used in the mini media controller. */
  GCKMediaMetadataImageTypeMiniController = 2,
  /** An image displayed as a background, poster, or fullscreen image. */
  GCKMediaMetadataImageTypeBackground = 3,
};

/**
 * An object that provides hints to a GCKUIImagePicker about the type and size of an image to be
 * selected for display in the UI.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKUIImageHints : NSObject <NSCopying, NSSecureCoding>

/**
 * The image type.
 */
@property(nonatomic, assign, readonly) GCKMediaMetadataImageType imageType;

/**
 * The size at which the image will be displayed.
 */
@property(nonatomic, assign, readonly) CGSize imageSize;

/**
 * Optional custom data that can be used to identify the image. It must be key-value coding
 * compliant.
 */
@property(nonatomic, copy, readonly, nullable) NSObject<NSSecureCoding> *customData;

/**
 * Convenience initializer. Sets the custom data to <code>nil</code>.
 *
 * @param imageType The image type.
 * @param imageSize The image size.
 */
- (instancetype)initWithImageType:(GCKMediaMetadataImageType)imageType imageSize:(CGSize)imageSize;

/**
 * Designated initializer.
 *
 * @param imageType The image type.
 * @param imageSize The image size.
 * @param customData The arbitrary custom data that can be used by a custom GCKUIImagePicker to
 * select an image.
 */
- (instancetype)initWithImageType:(GCKMediaMetadataImageType)imageType
                        imageSize:(CGSize)imageSize
                       customData:(nullable NSObject<NSSecureCoding> *)customData;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
