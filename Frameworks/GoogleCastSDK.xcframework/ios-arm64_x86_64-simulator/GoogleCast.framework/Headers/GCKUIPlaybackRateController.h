// Copyright 2017 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that can be used to implement a custom stream playback rate UI.
 * The application may either subclass this class and override the
 * GCKUIPlaybackRateController::playbackRate and GCKUIPlaybackRateController::inputEnabled
 * setters, or use KVO to listen for changes to these properties, and update its playback rate
 * and/or playback rate UI control(s) accordingly.
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKUIPlaybackRateController : NSObject

/** Designated initializer. */
- (instancetype)init;

/**
 * The current stream playback rate from the GCKRemoteMediaClient. The GCKUIMediaController writes
 * this property whenever the playback rate changes. The GCKUIMediaController observes the property
 * (unless it is in the process of writing it) and if it changes, it issues the appropriate media
 * command with the GCKRemoteMediaClient to change the playback rate.
 */
@property(nonatomic, assign) float playbackRate;

/**
 * The GCKUIMediaController writes this property to enable or disable the UI control(s) managed by
 * this controller. Media-related UI controls are temporarily disabled while a media command is
 * in-flight.
 */
@property(nonatomic, assign) BOOL inputEnabled;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
