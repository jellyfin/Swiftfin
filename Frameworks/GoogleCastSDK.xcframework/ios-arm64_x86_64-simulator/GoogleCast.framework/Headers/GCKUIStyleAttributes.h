// Copyright 2016 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class for controlling the style (colors, fonts, icons) of the default views of the framework.
 *
 * @since 3.3
 */
GCK_EXPORT
@interface GCKUIStyleAttributes : NSObject

/**
 * An image that will be used in "closed captions" buttons in the framework's default views.
 */
@property(nonatomic) UIImage *closedCaptionsImage;
/**
 * An image that will be used in "forward 30 seconds" buttons in the frameworks default views.
 */
@property(nonatomic) UIImage *forward30SecondsImage;
/**
 * An image that will be used in "rewind 30 seconds" buttons in the framework's default views.
 */
@property(nonatomic) UIImage *rewind30SecondsImage;
/**
 * An image that will be used to indicate that a slider is a volume slider in the framework's
 * default views.
 */
@property(nonatomic) UIImage *volumeImage;
/**
 * An image that will be used in the "mute toggle" button in the framework's default views.
 * This is the image that will be displayed while the receiver is muted.
 */
@property(nonatomic) UIImage *muteOffImage;
/**
 * An image that will be used in the "mute toggle" button in the framework's default views. This is
 * the image that will be displayed while the receiver is not muted.
 */
@property(nonatomic) UIImage *muteOnImage;
/**
 * An image that will be used in the "play/pause toggle" button in the framework's default views.
 * This is the image that will be displayed while the receiver is playing.
 */
@property(nonatomic) UIImage *pauseImage;
/**
 * An image that will be used in the "play/pause toggle" button in the framework's default views.
 * This is the image that will be displayed while the receiver is paused.
 */
@property(nonatomic) UIImage *playImage;
/**
 * An image that will be used in "forward 30 seconds" buttons in the framework's default views.
 */
@property(nonatomic) UIImage *skipNextImage;
/**
 * An image that will be used in "forward 30 seconds" buttons in the framework's default views.
 */
@property(nonatomic) UIImage *skipPreviousImage;
/**
 * An image that will be used in the track selector, to select the audio track chooser view.
 */
@property(nonatomic) UIImage *audioTrackImage;
/**
 * An image that will be used in the track selector, to select the subtitle track chooser view.
 */
@property(nonatomic) UIImage *subtitlesTrackImage;
/**
 * An image that will be used in "stop" buttons in the framework's default views.
 */
@property(nonatomic) UIImage *stopImage;
/**
 * The UIFont to be used in labels of buttons in the framework's default views.
 */
@property(nonatomic) UIFont *buttonTextFont;
/**
 * The color to be used in labels of buttons in the framework's default views.
 *
 * @since 3.4
 */
@property(nonatomic) UIColor *buttonTextColor;
/**
 * The shadow color to be used in labels of buttons in the framework's default views.
 */
@property(nonatomic) UIColor *buttonTextShadowColor;
/**
 * The offset for the shadow for labels of buttons in the framework's default views.
 */
@property(nonatomic, assign) CGSize buttonTextShadowOffset;
/**
 * The UIFont to be used in labels of type "body" in the framework's default views.
 */
@property(nonatomic) UIFont *bodyTextFont;
/**
 * The UIFont to be used in labels of type "heading" in the framework's default views.
 */
@property(nonatomic) UIFont *headingTextFont;
/**
 * The font to be used in labels of type "caption" in the framework's default views.
 */
@property(nonatomic) UIFont *captionTextFont;
/**
 * The color to be used in labels of type "body" in the framework's default views.
 */
@property(nonatomic) UIColor *bodyTextColor;
/**
 * The shadow color to be used in labels of type "body" in the framework's default views.
 */
@property(nonatomic) UIColor *bodyTextShadowColor;
/**
 * The color to be used in labels of type "heading" in the framework's default views.
 */
@property(nonatomic) UIColor *headingTextColor;
/**
 * The shadow color to be used in labels of type "heading" in the framework's default views.
 */
@property(nonatomic) UIColor *headingTextShadowColor;
/**
 * The color to be used in labels of type "caption" in the framework's default views.
 */
@property(nonatomic) UIColor *captionTextColor;
/**
 * The shadow color to be used in labels of type "caption" in the framework's default views.
 */
@property(nonatomic) UIColor *captionTextShadowColor;
/**
 * The background color to be used on the framework's default views.
 */
@property(nonatomic) UIColor *backgroundColor;
/**
 * The color to use as tint color on all buttons and icons on the framework's default views.
 */
@property(nonatomic) UIColor *iconTintColor;
/**
 * The offset for the shadow for labels of type "body" in the framework's default views.
 */
@property(nonatomic, assign) CGSize bodyTextShadowOffset;
/**
 * The offset for the shadow for labels of type "caption" in the framework's default views.
 */
@property(nonatomic, assign) CGSize captionTextShadowOffset;
/**
 * The offset for the shadow for labels of type "heading" in the framework's default views.
 */
@property(nonatomic, assign) CGSize headingTextShadowOffset;

/**
 * The color used for the unseekable progress tracks on the slider views.
 *
 * @since 4.4.1
 */
@property(nonatomic) UIColor *sliderUnseekableProgressColor;

/**
 * The color used for the seekable progress track, and thumb on the slider views.
 *
 * @since 4.4.1
 */
@property(nonatomic) UIColor *sliderProgressColor;

/**
 * The color used for the seekable and unplayed progress track on the slider views.
 *
 * @since 4.4.1
 */
@property(nonatomic) UIColor *sliderSecondaryProgressColor;

/**
 * The background color of the tooltip label of the slider thumb.
 *
 * @since 4.4.1
 */
@property(nonatomic) UIColor *sliderTooltipBackgroundColor;

/**
 * The color used for the marker of live indicator.
 *
 * @since 4.4.1
 */
@property(nonatomic) UIColor *liveIndicatorColor;

/**
 * The UIViewContentMode of the ad image on the expanded view controller wrapped in a NSNumber.
 *
 * @since 4.4.1
 */
@property(nonatomic) NSNumber *adImageContentMode;

/**
 * The UIViewContentMode of the background image on the expanded view controller wrapped in a
 * NSNumber.
 *
 * @since 4.4.1
 */
@property(nonatomic) NSNumber *backgroundImageContentMode;

/**
 * The color used to draw the circular ad marker on the seek bar in the played segment of the
 * slider. Default is Yellow.
 *
 * @since 4.6.0
 */
@property(nonatomic) UIColor *playedAdMarkerFillColor;

/**
 * The color used to draw the circular ad marker on the seek bar in the un-played segment of the
 * slider. Default is Yellow.
 *
 * @since 4.6.0
 */
@property(nonatomic) UIColor *unplayedAdMarkerFillColor;

@end

/**
 * The style attributes for the view group representing the navigation bar of device controller.
 * Can be accessed as castViews.deviceController.connectionController.navigation.
 *
 * @since 4.3.5
 */
GCK_EXPORT
@interface GCKUIStyleAttributesConnectionNavigation : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the toolbar of device controller.
 * Can be accessed as castViews.deviceController.connectionController.toolbar.
 *
 * @since 4.3.5
 */
GCK_EXPORT
@interface GCKUIStyleAttributesConnectionToolbar : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the initial instructions overlay.
 * Can be accessed as castViews.instructions.
 */
GCK_EXPORT
@interface GCKUIStyleAttributesInstructions : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the guest-mode pairing dialog.
 * Can be accessed as castViews.deviceControl.guestModePairingDialog
 */
GCK_EXPORT
@interface GCKUIStyleAttributesGuestModePairingDialog : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the media track selector.
 * Can be accessed as castViews.mediaControl.trackSelector
 */
GCK_EXPORT
@interface GCKUIStyleAttributesTrackSelector : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the mini controller.
 * Can be accessed as castViews.mediaControl.miniController
 */
GCK_EXPORT
@interface GCKUIStyleAttributesMiniController : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the expanded controller.
 * Can be accessed as castViews.mediaControl.expandedController
 */
GCK_EXPORT
@interface GCKUIStyleAttributesExpandedController : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the device chooser.
 * Can be accessed as castViews.deviceControl.deviceChooser
 */
GCK_EXPORT
@interface GCKUIStyleAttributesDeviceChooser : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing the connection controller.
 * Can be accessed as castViews.deviceControl.connectionController
 */
GCK_EXPORT
@interface GCKUIStyleAttributesConnectionController : GCKUIStyleAttributes

/**
 * The style attributes for the navigation bar of the device connection controller.
 *
 * @since 4.3.5
 */
@property(readonly, nonatomic) GCKUIStyleAttributesConnectionNavigation *navigation;

/**
 * The style attributes for the toolbar of the device connection controller.
 *
 * @since 4.3.5
 */
@property(readonly, nonatomic) GCKUIStyleAttributesConnectionToolbar *toolbar;

@end

/**
 * The style attributes for the view group representing no devices available controller.
 * Can be accessed as castViews.deviceControl.noDevicesAvailableController
 *
 * @since 4.6.0
 */
GCK_EXPORT
@interface GCKUIStyleAttributesNoDevicesAvailableController : GCKUIStyleAttributes
@end

/**
 * The style attributes for the view group representing all the media control views.
 * Can be accessed as castViews.mediaControl
 */
GCK_EXPORT
@interface GCKUIStyleAttributesMediaControl : GCKUIStyleAttributes

/** The style attributes for the expanded controller. */
@property(readonly, nonatomic) GCKUIStyleAttributesExpandedController *expandedController;

/** The style attributes for the mini controller. */
@property(readonly, nonatomic) GCKUIStyleAttributesMiniController *miniController;

/** The style attributes for the media track selector. */
@property(readonly, nonatomic) GCKUIStyleAttributesTrackSelector *trackSelector;

@end

/**
 * The style attributes for the view group representing all the device control views.
 * Can be accessed as castViews.deviceControl
 */
GCK_EXPORT
@interface GCKUIStyleAttributesDeviceControl : GCKUIStyleAttributes

/** The style attributes for the device chooser. */
@property(readonly, nonatomic) GCKUIStyleAttributesDeviceChooser *deviceChooser;

/** The style attributes for the device connection controller. */
@property(readonly, nonatomic)
    GCKUIStyleAttributesConnectionController *connectionController;

/**
 * The style attributes for the no devices available controller.
 *
 * @since 4.6.0
 */
@property(readonly, nonatomic)
    GCKUIStyleAttributesNoDevicesAvailableController *noDevicesAvailableController;

/** The style attributes for the Guest Mode pairing dialog. */
@property(readonly, nonatomic)
    GCKUIStyleAttributesGuestModePairingDialog *guestModePairingDialog;

@end

/**
 * The style attributes for the root view group.
 * Can be accessed as castViews
 */
GCK_EXPORT
@interface GCKUIStyleAttributesCastViews : GCKUIStyleAttributes

/** The style attributes for device control UI elements. */
@property(readonly, nonatomic) GCKUIStyleAttributesDeviceControl *deviceControl;

/** The style attributes for media control UI elements. */
@property(readonly, nonatomic) GCKUIStyleAttributesMediaControl *mediaControl;

/** The style attributes for instructional UI elements. */
@property(readonly, nonatomic) GCKUIStyleAttributesInstructions *instructions;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
