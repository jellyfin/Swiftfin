// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKCommon.h>
#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GCKUICastButtonDelegate;

/**
 * A subclass of <a href="https://goo.gl/VK61wU"><b>UIButton</b></a> that implements a "Cast"
 * button.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKUICastButton : UIButton

/**
 * A flag that indicates whether a touch event on this button will trigger the display of the
 * Cast dialog that is provided by the framework. By default this property is set to
 * <code>YES</code>. If an application wishes to handle touch events itself, it should set the
 * property to <code>NO</code> and register an appropriate target and action for the touch event.
 * This property cannot be set to NO if @c delegate is set to non-nil value.
 *
 * @deprecated Use GCKUICastButtonDelegate methods to respond to user actions on the cast button.
 */
@property(nonatomic, assign) BOOL triggersDefaultCastDialog GCK_DEPRECATED(
    "Use the GCKUICastButtonDelegate methods to respond to the actions on the cast button.");

/**
 * Set the delegate to respond to the user actions performed on the @c GCKUICastButton. Delegate
 * should not be set to non-nil value if the deprecated property @c triggersDefaultCastDialog
 * is set to NO.
 *
 * @since 4.6.0
 */
@property(nonatomic, weak) id<GCKUICastButtonDelegate> delegate;

/**
 * Constructs a new GCKUICastButton using the given decoder.
 */
- (instancetype)initWithCoder:(NSCoder *)decoder;

/**
 * Constructs a new GCKUICastButton with the given frame.
 */
- (instancetype)initWithFrame:(CGRect)frame;

/**
 * Sets the icons for the active, inactive, and animated states of the button. The supplied images
 * should all be single-color with a transparent background. The color of the images is not
 * significant, as the button's tint color (<code>tintColor</code> property) determines the color
 * that they are rendered in.
 */
- (void)setInactiveIcon:(UIImage *)inactiveIcon
             activeIcon:(UIImage *)activeIcon
         animationIcons:(NSArray<UIImage *> *)animationIcons;

/**
 * Sets the accessibility label for the cast states of the button.
 * This is the recommended way to set accessibility label for the button.
 * Label set by setAccessibilityLabel: is applied to all cast states.
 */
- (void)setAccessibilityLabel:(NSString *)label
                 forCastState:(GCKCastState)state;

@end

/**
 * Use the methods of this protocol to present custom dialog in response to user action.
 *
 * @since 4.6.0
 */
@protocol GCKUICastButtonDelegate <NSObject>

@optional

/**
 * Tells the delegate that the cast button is tapped by the user for the first time on iOS14 or
 * above and cast devices discovery has not started in the current or previous app sessions.
 * Implement this method to present the custom dialog. If not implmemented, the default dialog is
 * presented.
 *
 * @param castButton Instance of @c GCKUICastButton tapped.
 */
- (void)castButtonDidTapToPresentLocalNetworkAccessPermissionDialog:(GCKUICastButton *)castButton;

/**
 * Tells the delegate that the cast button is tapped by the user after the discovery has been
 * initiated in current or previous app session. Implement this method to present the custom dialog
 * as per the cast state. Observe GCKCastContext::castState to update the dialog dynamically as per
 * changes in the cast state. If not implmemented, the default dialog is presented.
 *
 * @param castButton Instance of @c GCKUICastButton tapped.
 * @param castState Cast state when the cast button is tapped.
 */
- (void)castButtonDidTap:(GCKUICastButton *)castButton
    toPresentDialogForCastState:(GCKCastState)castState;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
