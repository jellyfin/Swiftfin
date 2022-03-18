// Copyright 2015 Google Inc.

#import <GoogleCast/GCKSessionTraits.h>

#import <GoogleCast/GCKCommon.h>
#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKDevice.h>
#import <GoogleCast/GCKMediaMetadata.h>
#import <GoogleCast/GCKRemoteMediaClient.h>
#import <GoogleCast/GCKSessionOptions.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An abstract base class representing a session with a receiver device. Subclasses must implement
 * the @ref start and @ref endWithAction: methods, and must call the appropriate notifier methods
 * (for example, @ref notifyDidStartWithSessionID:) to indicate corresponding changes in the session
 * state. Subclasses may also implement @ref setDeviceVolume:, @ref setDeviceMuted: and
 * @ref remoteMediaClient if the device supports such operations.
 *
 * A session is created and controlled using the session methods in GCKSessionManager, which uses
 * the appropriate GCKDeviceProvider to create the session, and then delegates session requests to
 * that GCKSession object.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKSession : NSObject

/** The device that this session is associated with. */
@property(nonatomic, strong, readonly) GCKDevice *device;

/** The current session ID, if any. */
@property(nonatomic, copy, readonly, nullable) NSString *sessionID;

/**
 * The session options, if any.
 *
 * @since 4.0
 */
@property(nonatomic, strong, readonly, nullable) GCKSessionOptions *sessionOptions;

/** The current session connection state. */
@property(nonatomic, assign, readonly) GCKConnectionState connectionState;

/**
 * A flag indicating whether the session is currently suspended.
 *
 * @deprecated GCKSession no longer supports being in suspended state. If needed, move this
 * functionality to a subclass.
 */
@property(nonatomic, assign, readonly) BOOL suspended GCK_DEPRECATED(
    "GCKSession no longer supports being in a suspended state. If needed, move this functionality "
    "to a subclass.");
;

/** The current device status text. */
@property(nonatomic, copy, readonly, nullable) NSString *deviceStatusText;

/** The session traits. */
@property(nonatomic, copy, readonly, nullable) GCKSessionTraits *traits;

/** The current device volume, in the range [0.0, 1.0]. */
@property(nonatomic, assign, readonly) float currentDeviceVolume;

/** The current device mute state. */
@property(nonatomic, assign, readonly) BOOL currentDeviceMuted;

/**
 * The GCKRemoteMediaClient object that can be used to control media playback in this session. It is
 * <code>nil</code> before the session has started, or if the session does not support the
 * GCKRemoteMediaClient API. Subclasses which provide a GCKRemoteMediaClient interface must override
 * the getter method.
 */
@property(nonatomic, strong, readonly, nullable) GCKRemoteMediaClient *remoteMediaClient;

/**
 * The current media metadata, if any. Will be <code>nil</code> if the session does not support the
 * media namespace or if no media is currently loaded on the receiver.
 */
@property(nonatomic, strong, readonly, nullable) GCKMediaMetadata *mediaMetadata;

/**
 * Initializes a new session object for the given device, with default options.
 *
 * @param device The device.
 * @param traits The session traits.
 * @param sessionID The session ID of an existing session, if this object will be used to resume a
 * session; otherwise <code>nil</code> if it will be used to start a new session.
 */
- (instancetype)initWithDevice:(GCKDevice *)device
                        traits:(nullable GCKSessionTraits *)traits
                     sessionID:(nullable NSString *)sessionID;

/**
 * Initializes a new session object for the given device.
 *
 * @param device The device.
 * @param traits The session traits.
 * @param sessionID The session ID of an existing session, if this object will be used to resume a
 * session; otherwise <code>nil</code> if it will be used to start a new session.
 * @param sessionOptions The session options, if any; otherwise <code>nil</code>.
 *
 * @since 4.0
 */
- (instancetype)initWithDevice:(GCKDevice *)device
                        traits:(nullable GCKSessionTraits *)traits
                     sessionID:(nullable NSString *)sessionID
                sessionOptions:(nullable GCKSessionOptions *)sessionOptions;

/**
 * Sets the device's volume. This is an asynchronous operation. The default implementation is a
 * no-op that fails the request with a GCKErrorCodeUnsupportedFeature error.
 *
 * @param volume The new volume.
 * @return A GCKRequest object for tracking the request.
 * @since 3.4; in previous framework versions, this method returned <code>void</code>.
 */
- (GCKRequest *)setDeviceVolume:(float)volume;

/**
 * Sets the device's mute state. This is an asynchronous operation. The default implementation is a
 * no-op that fails the request with a GCKErrorCodeUnsupportedFeature error.
 *
 * @param muted The new mute state.
 * @return A GCKRequest object for tracking the request.
 * @since 3.4; in previous framework versions, this method returned <code>void</code>.
 */
- (GCKRequest *)setDeviceMuted:(BOOL)muted;

@end

NS_ASSUME_NONNULL_END
