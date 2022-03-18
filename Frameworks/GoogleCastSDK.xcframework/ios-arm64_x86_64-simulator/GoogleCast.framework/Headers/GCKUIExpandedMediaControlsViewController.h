// Copyright 2016 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKUIMediaButtonBarProtocol.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A view controller which implements the expanded controls fullscreen view.
 *
 * @since 3.1
 */
GCK_EXPORT
@interface GCKUIExpandedMediaControlsViewController : UIViewController <GCKUIMediaButtonBarProtocol>

/**
 * Whether stream position controls (including the stream position slider, the stream position
 * label, the stream duration label, and the stream progress view) should be hidden for live
 * content. The default value is <code>NO</code>.
 *
 * @since 4.0
 */
@property(nonatomic, assign) BOOL hideStreamPositionControlsForLiveContent;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
