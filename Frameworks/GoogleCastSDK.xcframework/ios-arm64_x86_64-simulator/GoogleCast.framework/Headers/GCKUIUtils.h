// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * User interface utility methods.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKUIUtils : NSObject

/**
 * Returns the currently active view controller, by navigating through the view controller
 * hierarchy beginning with the root view controller.
 */
+ (nullable UIViewController *)currentViewController;

/** Formats a time interval in MM:SS or H:MM:SS format. */
+ (NSString *)timeIntervalAsString:(NSTimeInterval)timeInterval;

/**
 * Formats a local time based on the current locale.
 *
 * @since 4.3.4
 */
+ (NSString *)localTimeAsString:(NSTimeInterval)localTime;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
