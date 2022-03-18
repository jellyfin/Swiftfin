// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A protocol that defines a means of retrieving and caching images. A default implementation is
 * used internally by the framework to cache media artwork that is displayed in the user interface.
 * The application can provide a custom implementation by setting the GCKCastContext::imageCache
 * property.
 *
 * @since 3.0
 */
GCK_EXPORT
@protocol GCKUIImageCache <NSObject>

/**
 * Fetches the image at the given URL, and returns a scaled version of the image. This is an
 * asynchronous operation.
 *
 * @param imageURL The URL of the image.
 * @param completion A block to invoke once the image has been retrieved. The image should be passed
 * to the block. If there was an error retrieving the image, <code>nil</code> should be passed
 * instead. The block should only be invoked on the main thread.
 */
- (void)fetchImageForURL:(NSURL *)imageURL
              completion:(void (^)(UIImage *_Nullable))completion;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
