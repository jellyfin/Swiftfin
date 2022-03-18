// Copyright 2015 Google Inc.

#import <GoogleCast/GCKSession.h>

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

/**
 * @file GCKSession+Protected.h
 * GCKSessionEndAction and GCKSessionState enums.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKSessionEndAction
 * Enum defining the action to take when ending a Cast session.
 * @since 4.0
 */
typedef NS_ENUM(NSInteger, GCKSessionEndAction) {
  /** Explicitly leaves the session on the receiver. */
  GCKSessionEndActionLeave = 1,
  /** Disconnects from the session without explicitity leaving it. */
  GCKSessionEndActionDisconnect = 2,
  /** Stops the currently Casting application on the receiver and then ends the session. */
  GCKSessionEndActionStopCasting = 3
};

/**
 * Methods to be overridden and called by GCKSession subclasses only.
 *
 * @since 3.0
 */
@interface GCKSession (Protected)

/**
 * Starts the session. This is an asynchronous operation. Must be overridden by subclasses.
 */
- (void)start;

/**
 * Ends the session with the specified action.  This is an asynchronous operation. Must be
 * overridden by subclasses.
 *
 * @param action The action to take when ending the session; see GCKSessionEndAction for more
 * details.
 */
- (void)endWithAction:(GCKSessionEndAction)action;

/**
 * Called by subclasses to notify the framework that the session has been started.
 *
 * @param sessionID The session's unique ID.
 */
- (void)notifyDidStartWithSessionID:(NSString *)sessionID;

/**
 * Called by subclasses to notify the framework that the session has failed to start.
 *
 * @param error The error that occurred.
 */
- (void)notifyDidFailToStartWithError:(NSError *)error;

/**
 * Called by subclasses to notify the framework that the session has ended.
 *
 * @param error The error that caused the session to end, if any. Should be <code>nil</code> if the
 * session was ended intentionally.
 * @param willTryToResume Whether the session will try to resume itself automatically.
 */
- (void)notifyDidEndWithError:(nullable NSError *)error willTryToResume:(BOOL)willTryToResume;

/**
 * Called by subclasses to notify the framework that updated device volume and mute state has been
 * received from the device.
 *
 * @param volume The device's current volume. Must be in the range [0, 1.0];
 * @param muted The device's current mute state.
 */
- (void)notifyDidReceiveDeviceVolume:(float)volume muted:(BOOL)muted;

/**
 * Called by subclasses to notify the framework that updated status has been received from the
 * device.
 *
 * @param statusText The new status.
 */
- (void)notifyDidReceiveDeviceStatus:(nullable NSString *)statusText;

/**
 * Deprecated, do not use - implemented as a no-op.
 *
 * @deprecated Do not call.
 */
- (void)notifyDidSuspendWithReason:(GCKConnectionSuspendReason)reason GCK_DEPRECATED("Do not call");

/**
 * Deprecated, do not use - implemented as a no-op.
 *
 * @deprecated Do not call.
 */
- (void)notifyDidResume GCK_DEPRECATED("Do not call");

@end

NS_ASSUME_NONNULL_END
