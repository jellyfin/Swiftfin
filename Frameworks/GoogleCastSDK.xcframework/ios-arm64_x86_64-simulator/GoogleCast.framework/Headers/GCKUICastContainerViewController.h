// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GCKUIMiniMediaControlsViewController;
@class GCKUINextUpViewController;

NS_ASSUME_NONNULL_BEGIN

/**
 * A view controller which wraps another View Controller and adds a media playback notification
 * area below that controller. The notification can display a "now playing" item
 * that displays a thumbnail, title, and subtitle for the current media item, a stream progress bar,
 * and a play/pause toggle button. The controller shows and hides this item as appropriate
 * based on the current media playback state on the receiver.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKUICastContainerViewController : UIViewController

/** The view controller to be embedded as the content area of this view controller. */
@property(nonatomic, strong, readonly, nullable) UIViewController *contentViewController;

/** The "now playing" view controller. */
@property(nonatomic, strong, readonly, nullable)
    GCKUIMiniMediaControlsViewController *miniMediaControlsViewController;

/**
 * A flag indicating whether the "now playing" item should be enabled. If enabled, the item will
 * be displayed automatically whenever there is media content loaded or playing on the receiver.
 * The default value is <code>NO</code>.
 */
@property(nonatomic, assign) BOOL miniMediaControlsItemEnabled;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
