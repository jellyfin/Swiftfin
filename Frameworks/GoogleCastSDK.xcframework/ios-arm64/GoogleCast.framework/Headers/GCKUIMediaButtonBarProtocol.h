// Copyright 2016 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

/**
 * @file GCKUIMediaButtonBarProtocol.h
 */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Media control button types.
 *
 * @since 3.1
 */
typedef NS_ENUM(NSInteger, GCKUIMediaButtonType) {
  /**
   * No button, results in empty space at a button position.
   */
  GCKUIMediaButtonTypeNone,
  /**
   * A default button that toggles between play and pause states.
   */
  GCKUIMediaButtonTypePlayPauseToggle,
  /**
   * A default "next" button. When tapped, playback moves to the next media item in the queue. It
   * becomes disabled if there is no next media item in the queue.
   */
  GCKUIMediaButtonTypeSkipNext,
  /**
   * A default "previous" button. When tapped, playback moves to the previous media item in the
   * queue. It becomes disabled if there is no previous media item in the queue.
   */
  GCKUIMediaButtonTypeSkipPrevious,
  /**
   * A default "rewind 30 seconds" button. When tapped, playback skips 30 seconds back in the
   * currently playing media item.
   */
  GCKUIMediaButtonTypeRewind30Seconds,
  /**
   * A default "forward 30 seconds" button. When tapped, playback skips 30 seconds forward in the
   * currently playing media item.
   */
  GCKUIMediaButtonTypeForward30Seconds,
  /**
   * A default "mute toggle" button. When tapped, the receiver's mute state is toggled.
   */
  GCKUIMediaButtonTypeMuteToggle,
  /**
   * A default "closed captions" button. When the button is tapped, the media tracks selection UI is
   * displayed to the user.
   */
  GCKUIMediaButtonTypeClosedCaptions,
  /**
   * A default "stop" button. Whe the button is tapped, playback of the current media item is
   * terminated on the receiver.
   */
  GCKUIMediaButtonTypeStop,

  /**
   * A button created and managed by the client.
   */
  GCKUIMediaButtonTypeCustom,
};

/**
 * The GCKUIMediaButtonBarProtocol delegate protocol.
 *
 * @since 3.1
 */
@protocol GCKUIMediaButtonBarProtocol <NSObject>

/**
 * The maximum number of buttons that can be customized by the receiver.
 * @return Number of buttons.
 */
- (NSUInteger)buttonCount;

/**
* Sets the button type for the button at position <code>index</code>.
*
* @param buttonType The type of the button. If the type is
* @ref GCKUIMediaButtonTypeCustom, a
*     <a href="https://goo.gl/VK61wU"><b>UIButton</b></a> instance should be
*     passed for the same index using @ref setCustomButton:atIndex:. Otherwise a default
*     button is created and presented in that position.
* @param index The position in which the button should be presented. 0 is the left-most position.
* Indices should be smaller than the value returned by @ref buttonCount.
*/
- (void)setButtonType:(GCKUIMediaButtonType)buttonType atIndex:(NSUInteger)index;

/**
 * Returns the current type of button at a given position.
 *
 * @param index The button's position, where 0 is the left-most position.
 * @return The type of the button at the selected position.
 */
- (GCKUIMediaButtonType)buttonTypeAtIndex:(NSUInteger)index;

/**
 * Sets the instance of <a href="https://goo.gl/VK61wU"><b>UIButton</b></a> that should be presented
 * at a given button position.
 *
 * @param customButton The button instance to be presented in the control bar.
 * @param index The position in which the button should be presented. 0 is the left-most position.
 * Indices should be smaller than the value returned by @ref buttonCount.
 */
- (void)setCustomButton:(nullable UIButton *)customButton atIndex:(NSUInteger)index;

/**
 * Returns a reference to the custom button at a given position.
 *
 * @param index The button's position, where 0 is the right-most position.
 * @return A reference to the button at the selected position, or <code>nil</code> if there is no
 * custom button at that position, or the position is invalid.
 */
- (nullable UIButton *)customButtonAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END

/* @endcond */
