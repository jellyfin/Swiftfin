// Copyright 2017 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that can be used to implement a custom stream position and/or seek UI, in situations
 * where ordinary <a href="https://goo.gl/H71tKD"><b>UISlider</b></a>,
 * <a href="https://goo.gl/LoRoAx"><b>UIProgressView</b></a>, and
 * <a href="https://goo.gl/POkr7n"><b>UILabel</b></a> controls will not suffice.
 * The application may either subclass this class and override the
 * GCKUIStreamPositionController::streamPosition, GCKUIStreamPositionController::streamDuration,
 * and GCKUIStreamPositionController::inputEnabled
 * setters, or use KVO to listen for changes to these properties, and update its stream position
 * and/or seek UI control(s) accordingly.
 *
 * @since 3.4
 */
GCK_EXPORT
@interface GCKUIStreamPositionController : NSObject

/** Designated initializer. */
- (instancetype)init;

/**
 * The current stream position from the GCKRemoteMediaClient. The GCKUIMediaController writes this
 * property whenever the stream position changes; while the stream is advancing, the property will
 * be updated once per second. The GCKUIMediaController observes the property (unless it is
 * in the process of writing it) and if it changes, it issues the appropriate media command with
 * the GCKRemoteMediaPlayer to seek to the new stream position. Note that updating this value on
 * an unseekable stream will have no effect.
 */
@property(nonatomic, assign) NSTimeInterval streamPosition;

/**
 * The current stream duration from the GCKRemoteMediaClient. The GCKUIMediaController writes this
 * property whenever the stream duration changes. If the stream does not have a known duration
 * (because it is a live stream, for example), then the value written will be @ref
 * kGCKInvalidTimeInterval. It is not meaningful for the application to change this value.
 */
@property(nonatomic, assign) NSTimeInterval streamDuration;

/**
 * The GCKUIMediaController writes this property to enable or disable the UI control(s) managed by
 * this controller. Media-related UI controls are temporarily disabled while a media command is
 * in-flight.
 */
@property(nonatomic, assign) BOOL inputEnabled;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
