// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKDevice.h>
#import <GoogleCast/GCKSession.h>
#import <GoogleCast/GCKSessionOptions.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An abstract base class for performing device discovery and session construction. Support for
 * additional device types can be added by extending this class. See the
 * @ref GCKDeviceProvider(Protected) category for a list of helper methods intended for use by
 * subclasses. New device providers are registered with the framework using @ref
 * GCKCastContext::registerDeviceProvider:.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKDeviceProvider : NSObject

/**
 * A string that uniquely identifies the type of device that will be discovered by this provider.
 */
@property(nonatomic, copy, readonly) NSString *deviceCategory;

/**
 * Whether the scan should be a passive scan. A passive scan sends discovery queries less
 * frequently, so it is more efficient, but the results will not be as fresh. It's appropriate to
 * do a passive scan when the user is not actively selecting a Cast target. Not all implementations
 * will honor this property.
 */
@property(nonatomic, assign) BOOL passiveScan;

/** The array of discovered devices. */
@property(nonatomic, copy, readonly) NSArray<GCKDevice *> *devices;

/**
 * Designated initializer. Constructs a new GCKDeviceProvider for devices of the specified type.
 *
 * @param deviceCategory A string that uniquely identifies the type of device that is managed by
 * by this provider.
 */
- (instancetype)initWithDeviceCategory:(NSString *)deviceCategory NS_DESIGNATED_INITIALIZER;

/**
 * Starts a new discovery scan. This is (commonly) an asynchronous operation. If any of the
 * devices discovered by the previous scan are no longer valid, the provider should unpublish them
 * at this time. Must be overridden by subclasses.
 *
 * The provider <b>must</b> notify the discovery manager once the scan has been started (and any
 * stale devices have been unpublished) by calling @ref GCKDeviceProvider::notifyDidStartDiscovery.
 * If a particular implementation of this method has no asynchronous work to do when starting a
 * scan, it can call the notification method directly before returning.
 */
- (void)startDiscovery;

/**
 * Stops the discovery scan. Must be overridden by subclasses.
 */
- (void)stopDiscovery;

/**
 * Constructs a new session for the given device and optionally an existing session ID.
 * Must be overridden by subclasses.
 *
 * @param device The device to connect to.
 * @param sessionID The ID of the session to resume; or <code>nil</code> to start a new session.
 * @param sessionOptions The session options, if any; otherwise <code>nil</code>.
 *
 * @since 4.0
 */
- (GCKSession *)createSessionForDevice:(GCKDevice *)device
                             sessionID:(nullable NSString *)sessionID
                        sessionOptions:(nullable GCKSessionOptions *)sessionOptions;

/**
 * Constructs a new session for the given device and optionally an existing session ID.
 *
 * @param device The device to connect to.
 * @param sessionID The ID of the session to resume; or <code>nil</code> to start a new session.
 *
 * @deprecated Subclasses should call createSessionForDevice:sessionID:sessionOptions instead.
 */
- (GCKSession *)createSessionForDevice:(GCKDevice *)device
                             sessionID:(nullable NSString *)sessionID
    GCK_DEPRECATED("Use createSessionForDevice:sessionID:sessionOptions:");

@end

NS_ASSUME_NONNULL_END
