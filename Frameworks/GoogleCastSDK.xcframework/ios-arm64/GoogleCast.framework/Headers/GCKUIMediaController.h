// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaStatus.h>
#import <GoogleCast/GCKRemoteMediaClient.h>
#import <GoogleCast/GCKSession.h>
#import <GoogleCast/GCKUIButton.h>
#import <GoogleCast/GCKUIImageHints.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * @file GCKUIMediaController.h
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * @var GCKUIControlStateRepeatOff
 * Custom <a href="https://goo.gl/tZWsqZ"><b>UIControlState</b></a> for the repeat mode button.
 * Corresponds to @ref GCKMediaRepeatModeOff.
 *
 * @deprecated Use GCKUIButtonStateRepeatOff with GCKUIMultistateButton.
 * @since 3.0
 */
GCK_EXTERN GCK_DEPRECATED("Use GCKUIButtonStateRepeatOff with GCKUIMultistateButton.")
const UIControlState GCKUIControlStateRepeatOff;

/**
 * @var GCKUIButtonStateRepeatOff
 * GCKUIMultistateButton state for the repeat mode button. Corresponds to
 * @ref GCKMediaRepeatModeOff.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStateRepeatOff;

/**
 * @var GCKUIControlStateRepeatAll
 * Custom <a href="https://goo.gl/tZWsqZ"><b>UIControlState</b></a> for the repeat mode button.
 * Corresponds to @ref GCKMediaRepeatModeAll.
 *
 * @deprecated Use GCKUIButtonStateRepeatAll with GCKUIMultistateButton.
 * @since 3.0
 */
GCK_EXTERN GCK_DEPRECATED("Use GCKUIButtonStateRepeatAll with GCKUIMultistateButton.")
const UIControlState GCKUIControlStateRepeatAll;

/**
 * @var GCKUIButtonStateRepeatAll
 * GCKUIMultistateButton state for the repeat mode button. Corresponds to
 * @ref GCKMediaRepeatModeAll.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStateRepeatAll;

/**
 * @var GCKUIControlStateRepeatSingle
 * Custom <a href="https://goo.gl/tZWsqZ"><b>UIControlState</b></a> for the repeat mode button.
 * Corresponds to @ref GCKMediaRepeatModeSingle.
 *
 * @deprecated Use GCKUIButtonStateRepeatSingle with GCKUIMultistateButton.
 * @since 3.0
 */
GCK_EXTERN GCK_DEPRECATED("Use GCKUIButtonStateRepeatSingle with GCKUIMultistateButton.")
const UIControlState GCKUIControlStateRepeatSingle;

/**
 * @var GCKUIButtonStateRepeatSingle
 * GCKUIMultistateButton state for the repeat mode button. Corresponds to
 * @ref GCKMediaRepeatModeSingle.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStateRepeatSingle;

/**
 * @var GCKUIControlStateShuffle
 * Custom <a href="https://goo.gl/tZWsqZ"><b>UIControlState</b></a> for the repeat mode button.
 * Corresponds to @ref GCKMediaRepeatModeAllAndShuffle.
 *
 * @deprecated Use GCKUIButtonStateShuffle with GCKUIMultistateButton.
 * @since 3.0
 */
GCK_EXTERN GCK_DEPRECATED("Use GCKUIButtonStateShuffle with GCKUIMultistateButton.")
const UIControlState GCKUIControlStateShuffle;

/**
 * @var GCKUIButtonStateShuffle
 * GCKUIMultistateButton state for the repeat mode button. Corresponds to
 * @ref GCKMediaRepeatModeAllAndShuffle.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStateShuffle;

/**
 * @var GCKUIControlStatePlay
 * Custom <a href="https://goo.gl/tZWsqZ"><b>UIControlState</b></a> for the play/pause toggle
 * button. Indicates media is playing.
 *
 * @deprecated Use GCKUIButtonStatePlay with GCKUIMultistateButton.
 * @since 3.0
 */
GCK_EXTERN GCK_DEPRECATED("Use GCKUIButtonStatePlay with GCKUIMultistateButton.")
const UIControlState GCKUIControlStatePlay;

/**
 * @var GCKUIButtonStatePlay
 * GCKUIMultistateButton state for the play/pause toggle button. Indicates media is playing.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStatePlay;

/**
 * @var GCKUIControlStatePause
 * Custom <a href="https://goo.gl/tZWsqZ"><b>UIControlState</b></a> for the play/pause toggle
 * button. Indicates media is paused.
 *
 * @deprecated Use GCKUIButtonStatePause with GCKUIMultistateButton.
 * @since 3.0
 */
GCK_EXTERN GCK_DEPRECATED("Use GCKUIButtonStatePause with GCKUIMultistateButton.")
const UIControlState GCKUIControlStatePause;

/**
 * @var GCKUIButtonStatePause
 * GCKUIMultistateButton state for the play/pause toggle button. Indicates media is paused.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStatePause;

/**
 * @var GCKUIButtonStatePlayLive
 * Custom GCKUIMultistateButton state for the play/pause toggle button. Indicates media is playing
 * and is live.
 *
 * @since 4.0
 */
GCK_EXTERN const NSUInteger GCKUIButtonStatePlayLive;

/**
 * A block for formatting an arbitrary object as an
 * <a href="https://goo.gl/5dXzU6"><b>NSString</b></a>.
 *
 * @since 3.0
 */
typedef NSString *_Nonnull (^GCKUIValueFormatter)(const id value);

@protocol GCKUIMediaControllerDelegate;
@class GCKUIPlaybackRateController;
@class GCKUIPlayPauseToggleController;
@class GCKUIStreamPositionController;

/**
 * A controller for UI views that are used to control or display the status of media playback on
 * a Cast receiver. The calling application registers its media-related UI controls with the
 * controller by setting the appropriate properties. The controller then responds to touch events
 * on the controls by issuing the appropriate media commands to the receiver, and updates the
 * controls based on status information and media metadata received from the receiver. The
 * controller automatically enables and disables the UI controls as appropriate for the current
 * session and media player state. It additionally disables all of the controls while a request is
 * in progress.
 *
 * See GCKUIMediaControllerDelegate for the delegate protocol.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKUIMediaController : NSObject

/**
 * The delegate for receiving notificatiosn from the GCKUIMediaController.
 */
@property(nonatomic, weak, nullable) id<GCKUIMediaControllerDelegate> delegate;

/**
 * The session that is associated with this controller.
 */
@property(nonatomic, strong, readonly, nullable) GCKSession *session;

/**
 * Whether there is media currently loaded (or loading) on the receiver. If no Cast session is
 * active, this will be <code>NO</code>.
 */
@property(nonatomic, assign, readonly) BOOL mediaLoaded;

/**
 * Whether there is a current item in the queue.
 */
@property(nonatomic, assign, readonly) BOOL hasCurrentQueueItem;

/**
 * Whether there is an item being preloaded in the queue.
 */
@property(nonatomic, assign, readonly) BOOL hasLoadingQueueItem;

/**
 * The latest known media player state. If no Cast session is active, this will be player state
 * just before the last session ended. If there was no prior session, this will be
 * @ref GCKMediaPlayerStateUnknown.
 */
@property(nonatomic, assign, readonly) GCKMediaPlayerState lastKnownPlayerState;

/**
 * The latest known media stream position. If no Cast session is active, this will be the stream
 * position of the media just before the last session ended. If there was no prior session, this
 * will be @ref kGCKInvalidTimeInterval.
 */
@property(nonatomic, assign, readonly) NSTimeInterval lastKnownStreamPosition;

/**
 * A "play" button. When the button is tapped, playback of the currently loaded media is started or
 * resumed on the receiver. The button will be disabled if playback is already in progress, or if
 * there is no media currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *playButton;

/**
 * A "pause" button. When the button is tapped, playback of the currently loaded media is paused on
 * the receiver. The button will be disabled if the currently loaded media does not support pausing,
 * or if playback is not currently in progress, or if there is no media currently loaded, or if
 * there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *pauseButton;

/**
 * A "play/pause" toggle button. The caller should set appropriate icons for the button's
 * @ref GCKUIButtonStatePlay, @ref GCKUIButtonStatePlayLive, and @ref GCKUIButtonStatePause button
 * states, namely, a "pause" icon for the play state, a "stop" icon for the play-live state, and a
 * "play" icon for the pause state. The button state is automatically updated to reflect the current
 * playback state on the receiver. When the button is tapped, playback of the currently loaded media
 * is paused or resumed on the receiver. The button will be disabled if the currently loaded media
 * does not support pausing, or if playback is not currently in progress or paused, or if there is
 * no media currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) GCKUIMultistateButton *playPauseToggleButton;

/**
 * A "play/pause" toggle controller. Used as a stand-in for a custom, application-supplied
 * play/pause toggle UI. See GCKUIPlayPauseToggleController for details.
 *
 * @since 3.4
 */
@property(nonatomic, strong, nullable)
    GCKUIPlayPauseToggleController *playPauseToggleController;

/**
 * A "stop" button. When the button is tapped, playback of the currently loaded media is stopped on
 * the receiver. The button will be disabled if there is no media currently loaded, or if there is
 * no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *stopButton;

/**
 * A button for seeking 30 seconds forward in the currently playing media item. The button will be
 * disabled if there is no media
 * currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *forward30SecondsButton;

/**
 * A button for seeking 30 seconds back in the currently playing media item. The button will be
 * disabled if there is no media currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *rewind30SecondsButton;

/**
 * A button for pausing queue playback once the current item finishes playing.
 */
@property(nonatomic, weak, nullable) UIButton *pauseQueueButton;

/**
 * A "next" button. When the button is tapped, playback moves to the next media item in the queue.
 * The button will be disabled if the operation is not supported, or if there is no media currently
 * loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *nextButton;

/**
 * A "previous" button. When the button is tapped, playback moves to the previous media item in the
 * queue. The button will be disabled if the operation is not supported, or if there is no media
 * currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *previousButton;

/**
 * A button for cycling through the available queue repeat modes. (See @ref GCKMediaRepeatMode.) The
 * caller should set appropriate icons for the button's @ref GCKUIButtonStateRepeatOff,
 * @ref GCKUIButtonStateRepeatSingle, @ref GCKUIButtonStateRepeatAll, and
 * @ref GCKUIButtonStateShuffle button states. The button state is automatically updated to reflect
 * the current queue repeat mode on the receiver. Tapping on the button cycles to the next repeat
 * mode, in the order:
 *
 * @ref GCKMediaRepeatModeOff &rarr; @ref GCKMediaRepeatModeAll &rarr;
 * @ref GCKMediaRepeatModeSingle &rarr; @ref GCKMediaRepeatModeAllAndShuffle
 *
 * The button will be disabled if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) GCKUIMultistateButton *repeatModeButton;

/**
 * A slider for displaying and changing the current stream position. When the slider's value is
 * changed by the user, the stream position of the currently loaded media is updated on the
 * receiver. While playback of media is in progress on the receiver, the slider's value is updated
 * in realtime to reflect the current stream position. The slider will be disabled if the currently
 * loaded media does not support seeking, or if there is no media currently loaded, or if there is
 * no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UISlider *streamPositionSlider;

/**
 * A view for displaying the current stream progress. While playback of media is in progress on the
 * receiver, the views's value is updated in realtime to reflect the current stream position. The
 * view will be disabled if the currently loaded media is a live stream, or if there is no media
 * currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIProgressView *streamProgressView;

/**
 * A label for displaying the current stream position, in minutes and seconds. If there is no media
 * currently loaded, or if there is no Cast session currently active, the label displays a localized
 * form of "--:--".
 */
@property(nonatomic, weak, nullable) UILabel *streamPositionLabel;

/**
 * A label for displaying the current stream duration, in minutes and seconds. If the currently
 * loaded media does not have a duration (for example, if it is a live stream), or if there is no
 * media currently loaded, or if there is no Cast session currently active, the label displays a
 * localized form of "--:--".
 */
@property(nonatomic, weak, nullable) UILabel *streamDurationLabel;

/**
 * A label for displaying the remaining stream time (the duration minus the position), in minutes
 * and seconds. If the currently loaded media does not have a duration (for example, if it is a live
 * stream), or if there is no media currently loaded, or if there is no Cast session currently
 * active, the label displays a localized form of "--:--".
 */
@property(nonatomic, weak, nullable) UILabel *streamTimeRemainingLabel;

/**
 * A stream posdition controller. Used as a stand-in for a custom, application-supplied
 * stream position and/or seek UI. See GCKUIStreamPositionController for details.
 *
 * @since 3.4
 */
@property(nonatomic, strong, nullable)
    GCKUIStreamPositionController *streamPositionController;

/**
 * A stream playback rate controller. See GCKUIPlaybackRateController for details.
 *
 * @since 4.0
 */
@property(nonatomic, strong, nullable)
    GCKUIPlaybackRateController *playbackRateController;

/**
 * Whether remaining stream time will be displayed as a negative value, for example, "-1:23:45". By
 * default this property is set to <code>YES</code>.
 */
@property(nonatomic, assign) BOOL displayTimeRemainingAsNegativeValue;

/**
 * Whether stream position controls (including the stream position slider, the stream position
 * label, the stream duration label, and the stream progress view) should be hidden for live
 * content. The default value is <code>NO</code>.
 *
 * @since 4.0
 */
@property(nonatomic, assign) BOOL hideStreamPositionControlsForLiveContent;

/**
 * A button for selecting audio tracks and/or closed captions or subtitles. When the button is
 * tapped, the media tracks selection UI is displayed to the user. The button will be disabled if
 * the currently loaded media does not have any selectable media tracks, or if there is no media
 * currently loaded, or if there is no Cast session currently active.
 */
@property(nonatomic, weak, nullable) UIButton *tracksButton;

/**
 * A label for displaying a subtitle for the currently loaded media. If there is no subtitle field
 * explicitly set in the metadata, the label will display the most appropriate metadata field based
 * on the media type, for example the studio name for a movie or the artist name for a music track.
 */
@property(nonatomic, weak, nullable) UILabel *smartSubtitleLabel;

/**
 * An activity indicator view for indicating that the media is in a loading state.
 */
@property(nonatomic, weak, nullable) UIActivityIndicatorView *mediaLoadingIndicator;

/**
 * A label for displaying the amount of time left until the ad can be skipped.
 *
 * @since 4.3
 */
@property(nonatomic, weak, nullable) UILabel *skipAdLabel;

/**
 * A button for skipping the current ad.
 *
 * @since 4.3
 */
@property(nonatomic, weak, nullable) UIButton *skipAdButton;

/**
 * Initializes an instance.
 */
- (instancetype)init;

/**
 * Binds a <a href="https://goo.gl/POkr7n"><b>UILabel</b></a> to a metadata key. The view will
 * display the current value of the corresponding metadata field.
 *
 * See GCKMediaMetadata for a list of predefined metadata keys.
 *
 * @param label The <a href="https://goo.gl/POkr7n"><b>UILabel</b></a> that will display the value.
 * @param key The metadata key.
 */
- (void)bindLabel:(UILabel *)label toMetadataKey:(NSString *)key;

/**
 * Binds a <a href="https://goo.gl/POkr7n"><b>UILabel</b></a> to a metadata key. The view will
 * display the current value of the corresponding metadata field.
 *
 * See GCKMediaMetadata for a list of predefined metadata keys.
 *
 * @param label The <a href="https://goo.gl/POkr7n"><b>UILabel</b></a> that will display the value.
 * @param key The metadata key.
 * @param formatter A block that will produce the desired string representation of the value.
 */
- (void)bindLabel:(UILabel *)label
    toMetadataKey:(NSString *)key
    withFormatter:(GCKUIValueFormatter)formatter;

/**
 * Binds a <a href="https://goo.gl/ncWBFi"><b>UITextView</b></a> to a metadata key. The view will
 * display the current value of the corresponding metadata field.
 *
 * See GCKMediaMetadata for a list of predefined metadata keys.
 *
 * @param textView The <a href="https://goo.gl/ncWBFi"><b>UITextView</b></a> that will display the
 * value.
 * @param key The metadata key.
 */
- (void)bindTextView:(UITextView *)textView toMetadataKey:(NSString *)key;

/**
 * Binds a <a href="https://goo.gl/ncWBFi"><b>UITextView</b></a> to a metadata key. The view will
 * display the current value of the corresponding metadata field.
 *
 * See GCKMediaMetadata for a list of predefined metadata keys.
 *
 * @param textView The <a href="https://goo.gl/ncWBFi"><b>UITextView</b></a> that will display the
 * value.
 * @param key The metadata key.
 * @param formatter A block that will produce the desired string representation of the value.
 */
- (void)bindTextView:(UITextView *)textView
       toMetadataKey:(NSString *)key
       withFormatter:(GCKUIValueFormatter)formatter;

/**
 * Binds a <a href="https://goo.gl/8Eb8FS"><b>UIImageView</b></a> to a GCKUIImageHints instance.
 * The currently installed GCKUIImagePicker will be used to select an image from the metadata for
 * the view.
 *
 * @param imageView The <a href="https://goo.gl/8Eb8FS"><b>UIImageView</b></a> that will display the
 * selected image.
 * @param imageHints The image hints.
 */
- (void)bindImageView:(UIImageView *)imageView toImageHints:(GCKUIImageHints *)imageHints;

/**
 * Unbinds the specified view.
 *
 * @param view The view to unbind.
 */
- (void)unbindView:(UIView *)view;

/**
 * Unbinds all bound views.
 */
- (void)unbindAllViews;

/**
 * Changes the repeat mode for the queue to the next mode in the cycle:
 *
 * @ref GCKMediaRepeatModeOff &rarr; @ref GCKMediaRepeatModeAll &rarr;
 * @ref GCKMediaRepeatModeSingle &rarr; @ref GCKMediaRepeatModeAllAndShuffle
 *
 * @return The new repeat mode.
 */
- (GCKMediaRepeatMode)cycleRepeatMode;

/**
 * A convenience method for displaying the media track selection UI.
 */
- (void)selectTracks;

/**
 * Sends and monitors the skip ad request.
 *
 * @since 4.3
 */
- (void)skipAd;

@end

/**
 * The GCKUIMediaController delegate protocol.
 *
 * @since 3.0
 */
@protocol GCKUIMediaControllerDelegate <NSObject>

@optional

/**
 * Called when the remote media player state has changed.
 *
 * @param mediaController The GCKUIMediaController instance.
 * @param playerState The new player state.
 * @param streamPosition The last known stream position at the time of the player state change.
 */
- (void)mediaController:(GCKUIMediaController *)mediaController
    didUpdatePlayerState:(GCKMediaPlayerState)playerState
      lastStreamPosition:(NSTimeInterval)streamPosition;

/**
 * Called when preloading has started for an upcoming media queue item.
 *
 * @param mediaController The GCKUIMediaController instance.
 * @param itemID The ID of the item that is being preloaded, or @ref kGCKMediaQueueInvalidItemID
 * if none.
 */
- (void)mediaController:(GCKUIMediaController *)mediaController
    didBeginPreloadForItemID:(NSUInteger)itemID;

/**
 * Called when new media status has been received from the receiver, and after the
 * GCKUIMediaController has finished processing the updated status.
 *
 * @param mediaController The GCKUIMediaController instance.
 * @param mediaStatus The new media status.
 */
- (void)mediaController:(GCKUIMediaController *)mediaController
    didUpdateMediaStatus:(GCKMediaStatus *)mediaStatus;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
