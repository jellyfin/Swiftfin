// Copyright 2015 Google Inc.

/** @cond ENABLE_FEATURE_GUI */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class GCKMediaInformation;
@protocol GCKUIMediaTrackSelectionViewControllerDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * A view controller that displays a list of the available text and audio tracks for a given media
 * item.
 *
 * See GCKUIMediaTrackSelectionViewControllerDelegate for the delegate protocol.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKUIMediaTrackSelectionViewController : UITabBarController

/**
 * The delegate that receives selection notifications from the controller.
 */
@property(nonatomic, weak, nullable)
    id<GCKUIMediaTrackSelectionViewControllerDelegate> selectionDelegate;

/**
 * The media information from which the list of available media tracks will be obtained.
 */
@property(nonatomic, strong, nullable) GCKMediaInformation *mediaInfo;

/**
 * The list of currently selected media track IDs.
 */
@property(nonatomic, copy, nullable) NSArray<NSNumber *> *selectedTrackIDs;

@end

/**
 * The GCKUIDeviceConnectionViewController delegate protocol.
 *
 * @since 3.0
 */
@protocol GCKUIMediaTrackSelectionViewControllerDelegate <NSObject>

/**
 * Called when the user has made a media track selection. The list may contain at most one
 * audio track ID and one text track ID. The absence of an audio track ID indicates that the
 * default audio track is selected, and the absence of a text track ID indicates that no text
 * track is selected.
 */
- (void)didSelectMediaTracks:(NSArray<NSNumber *> *)mediaTrackIDs;

@end

NS_ASSUME_NONNULL_END

/** @endcond */
