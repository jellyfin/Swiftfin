// Copyright 2016 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@class GCKImage;
@class GCKMediaMetadata;
@class GCKUIImageHints;

NS_ASSUME_NONNULL_BEGIN

/**
 * An object used for selecting an image for a given purpose from a GCKMediaMetadata object.
 * A default implementation is used internally by the framework which always selects the first
 * image from the metadata for all uses. The application can provide a custom implementation by
 * setting the GCKCastContext::imagePicker property.
 *
 * @since 3.0
 */
GCK_EXPORT
@protocol GCKUIImagePicker <NSObject>

/**
 * Returns an image of the specified type from the media metadata.
 *
 * @param imageHints The hints about how to pick the image.
 * @param metadata The media metadata to pick from.
 * @return The selected image, or <code>nil</code> if there is no appropriate image for the
 * requested type.
 */
- (nullable GCKImage *)getImageWithHints:(GCKUIImageHints *)imageHints
                            fromMetadata:(const GCKMediaMetadata *)metadata;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
