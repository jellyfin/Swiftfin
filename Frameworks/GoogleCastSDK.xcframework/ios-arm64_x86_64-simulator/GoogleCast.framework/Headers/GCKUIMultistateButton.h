// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A subclass of <a href="https://goo.gl/VK61wU"><b>UIButton</b></a> that supports multiple states.
 * Assign an image to each state with the GCKUIMultistateButton::setImage:forButtonState: method.
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKUIMultistateButton : UIButton

/**
 * The button's application state.
 */
@property(nonatomic, assign) NSUInteger buttonState;

/**
 * Sets the image to display for a given button state.
 *
 * @param image The image.
 * @param buttonState The button state.
 */
- (void)setImage:(UIImage *)image forButtonState:(NSUInteger)buttonState;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
