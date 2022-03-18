// Copyright 2016 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKUIStyleAttributes.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *
 * @since 3.3
 */
GCK_EXPORT
@interface GCKUIStyle : NSObject

/**
 * Returns the GCKUIStyle singleton instance.
 */
+ (GCKUIStyle *)sharedInstance;

/**
 * Forces a refresh of all currently visible views, so that any changes to the styling will
 * take effect immediately.
 */
- (void)applyStyle;

/**
 * The root of the styling attributes tree.
 */
@property(nonatomic, strong, readonly) GCKUIStyleAttributesCastViews *castViews;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
