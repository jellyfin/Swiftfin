// Copyright 2015 Google Inc.

#import <GoogleCast/GCKSession.h>
#import <GoogleCast/GCKSessionOptions.h>

#import <Foundation/Foundation.h>

@class GCKApplicationMetadata;
@class GCKCastChannel;
@class GCKCastOptions;
@class GCKDevice;
@class GCKDynamicDevice;
@class GCKMultizoneDevice;
@class GCKMultizoneStatus;
@class GCKRequest;
@class GCKSessionEndpoint;
@protocol GCKCastDeviceStatusListener;

NS_ASSUME_NONNULL_BEGIN

/**
 * A class that manages a Cast session with a receiver device.
 *
 * Sessions are created and managed automatically by the GCKSessionManager. The application should
 * not directly call the session lifecycle methods such as @ref start or @ref endWithAction:.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKCastSession : GCKSession

/**
 * The device's current "active input" status.
 */
@property(nonatomic, assign, readonly) GCKActiveInputStatus activeInputStatus;

/**
 * The device's current "standby" status.
 */
@property(nonatomic, assign, readonly) GCKStandbyStatus standbyStatus;

/**
 * The metadata for the receiver application that is currently running on the receiver device, if
 * any; otherwise <code>nil</code>.
 */
@property(nonatomic, copy, readonly, nullable) GCKApplicationMetadata *applicationMetadata;

/**
 * Constructs a new Cast session with the given Cast options.
 *
 * @param device The receiver device.
 * @param sessionID The session ID, if resuming; otherwise <code>nil</code>.
 * @param sessionOptions The session options, if any; otherwise <code>nil</code>.
 * @param castOptions The Cast options.
 *
 * @since 4.0
 */
- (instancetype)initWithDevice:(GCKDevice *)device
                     sessionID:(nullable NSString *)sessionID
                sessionOptions:(nullable GCKSessionOptions *)sessionOptions
                   castOptions:(GCKCastOptions *)castOptions;

/**
 * Registers a channel with the session.
 *
 * If the session is connected and the receiver application supports the channel's namespace, the
 * channel will be automatically connected. If the session is not connected, the channel will remain
 * in a disconnected state until the session is started.
 *
 * @param channel The channel to register.
 * @return <code>YES</code> if the channel was registered successfully, <code>NO</code> otherwise.
 */
- (BOOL)addChannel:(GCKCastChannel *)channel;

/**
 * Removes a previously registered channel from the session.
 *
 * @param channel The channel to unregister.
 * @return <code>YES</code> if the channel was unregistered successfully, <code>NO</code> otherwise.
 */
- (BOOL)removeChannel:(GCKCastChannel *)channel;

/**
 * Adds a GCKCastDeviceStatusListener to this object's list of listeners.
 *
 * The added listener is weakly held, and should be retained to avoid unexpected deallocation.
 *
 * @param listener The listener to add.
 */
- (void)addDeviceStatusListener:(id<GCKCastDeviceStatusListener>)listener;

/**
 * Removes a GCKCastDeviceStatusListener from this object's list of listeners.
 *
 * @param listener The listener to remove.
 */
- (void)removeDeviceStatusListener:(id<GCKCastDeviceStatusListener>)listener;

/**
 * Sets the individual device's volume in a multizone group. This is an asynchronous operation.
 *
 * @param volume The new volume, in the range [0.0, 1.0].
 * @param device The multizone device.
 * @return A GCKRequest object for tracking the request.
 */
- (GCKRequest *)setDeviceVolume:(float)volume forMultizoneDevice:(GCKMultizoneDevice *)device;

/**
 * Sets the individual device's muted state in a multizone group. This is an asynchronous operation.
 *
 * @param muted The new muted state.
 * @param device The multizone device.
 * @return A GCKRequest object for tracking the request.
 */
- (GCKRequest *)setDeviceMuted:(BOOL)muted forMultizoneDevice:(GCKMultizoneDevice *)device;

/**
 * Request multizone status from a multizone group. This is an asynchronous operation. When the
 * multizone status is received, the
 * GCKCastDeviceStatusListener::castSession:didReceiveMultizoneStatus: delegate method will be
 * messaged.
 *
 * @return A GCKRequest object for tracking the request.
 */
- (GCKRequest *)requestMultizoneStatus;

@end  // GCKCastSession

/**
 * A listener protocol for receiving Cast device status change notifications.
 *
 * @since 3.0
 */
@protocol GCKCastDeviceStatusListener <NSObject>

@optional

/**
 * Called when the Cast device's active input status has changed.
 *
 * @param castSession The Cast session.
 * @param activeInputStatus The new active input status.
 */
- (void)castSession:(GCKCastSession *)castSession
    didReceiveActiveInputStatus:(GCKActiveInputStatus)activeInputStatus;

/**
 * Called when the Cast device's standby status has changed.
 *
 * @param castSession The Cast session.
 * @param standbyStatus The new standby status.
 */
- (void)castSession:(GCKCastSession *)castSession
    didReceiveStandbyStatus:(GCKStandbyStatus)standbyStatus;

/**
 * Called when the Cast device's multizone status has changed.
 *
 * @param castSession The Cast session.
 * @param multizoneStatus The new multizone status.
 */
- (void)castSession:(GCKCastSession *)castSession
    didReceiveMultizoneStatus:(GCKMultizoneStatus *)multizoneStatus;

/**
 * Called whenever a multizone device is added.
 *
 * @param castSession The Cast session.
 * @param device The newly-added multizone device.
 */
- (void)castSession:(GCKCastSession *)castSession
    didAddMultizoneDevice:(GCKMultizoneDevice *)device;

/**
 * Called whenever a multizone device is updated.
 *
 * @param castSession The Cast session.
 * @param device The updated multizone device.
 */
- (void)castSession:(GCKCastSession *)castSession
    didUpdateMultizoneDevice:(GCKMultizoneDevice *)device;

/**
 * Called whenever a multizone device is removed.
 *
 * @param castSession The Cast session.
 * @param deviceID The deviceID of the removed multizone device.
 */
- (void)castSession:(GCKCastSession *)castSession
    didRemoveMultizoneDeviceWithID:(NSString *)deviceID;

@end  // GCKCastDeviceStatusListener

NS_ASSUME_NONNULL_END
