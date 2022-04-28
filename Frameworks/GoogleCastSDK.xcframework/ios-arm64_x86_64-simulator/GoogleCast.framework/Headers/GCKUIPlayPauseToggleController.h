// Copyright 2017 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

/**
 * @file GCKUIPlayPauseToggleController.h
 * GCKUIPlayPauseState enum.
 */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * @enum GCKUIPlayPauseState
 *
 * The play/pause state for a GCKUIPlayPauseToggleController.
 */
typedef NS_ENUM(NSInteger, GCKUIPlayPauseState) {
  GCKUIPlayPauseStateNone = 0,
  GCKUIPlayPauseStatePlay = 1,
  GCKUIPlayPauseStatePause = 2
};

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that can be used to implement a custom play/pause toggle UI, in situations where a
 * GCKUIMultistateButton will not suffice. The application may either subclass this class and
 * override the  GCKUIPlayPauseToggleController::playPauseState and
 * GCKUIPlayPauseToggleController::inputEnabled setters, or use KVO to listen for changes to these
 * properties, and update its play/pause UI control(s) accordingly.
 *
 * @since 3.4
 */
GCK_EXPORT
@interface GCKUIPlayPauseToggleController : NSObject

/** Designated initializer. */
- (instancetype)init;

/**
 * The current play/pause state of the GCKRemoteMediaClient. The GCKUIMediaController writes this
 * property whenever the receiver's play/pause state changes. It observes the property (unless it is
 * in the process of writing it) and if it changes, it issues the appropriate media command with
 * the GCKRemoteMediaClient to change the receiver's player state accordingly.
 */
@property(nonatomic, assign) GCKUIPlayPauseState playPauseState;

/**
 * The GCKUIMediaController writes this property to enable or disable the UI control(s) managed by
 * this controller. Media-related UI controls are temporarily disabled while a media command is
 * in-flight.
 */
@property(nonatomic, assign) BOOL inputEnabled;

@end

NS_ASSUME_NONNULL_END

/** @endcond */

