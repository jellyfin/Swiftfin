// Copyright 2015 Google Inc.

#import <GoogleCast/GCKCommon.h>
#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@class GCKCastOptions;
@class GCKCredentialsData;
@class GCKDiscoveryManager;
@class GCKDeviceProvider;
@class GCKError;
@class GCKMediaRequestItem;
@class GCKSessionManager;

/**
 * @file GCKCastContext.h
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * The <code>userInfo</code> key for the new Cast state in a Cast state change notification.
 *
 * @memberof GCKCastContext
 */
GCK_EXTERN NSString *const kGCKNotificationKeyCastState;

/**
 * The name of the notification that will be published when the Cast state changes.
 *
 * @memberof GCKCastContext
 */
GCK_EXTERN NSString *const kGCKCastStateDidChangeNotification;

/**
 * A class containing global objects and state for the framework. The context must be initialized
 * early in the application's lifecycle via a call to @ref setSharedInstanceWithOptions:.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKCastContext : NSObject

/**
 * The current casting state for the application. Changes to this property can be monitored with
 * KVO or by listening for @ref kGCKCastStateDidChangeNotification notifications.
 */
@property(nonatomic, assign, readonly) GCKCastState castState;

/**
 * The discovery manager. This object handles the discovery of receiver devices.
 */
@property(nonatomic, strong, readonly) GCKDiscoveryManager *discoveryManager;

/**
 * The session manager. This object manages the interaction with receiver devices.
 */
@property(nonatomic, strong, readonly) GCKSessionManager *sessionManager;

/**
 * Sets the shared instance, supplying a Cast options object. If the shared instance is already
 * initialized, an exception will be thrown.
 *
 * @param options The Cast options.
 */
+ (void)setSharedInstanceWithOptions:(GCKCastOptions *)options;

/**
 * Sets the shared instance, supplying a Cast options object. The call will fail if the context is
 * already initialized. This method must be called on the main thread.
 *
 * @param options The Cast options.
 * @param error A pointer at which to store the error in case of a failure.
 * @return <code>YES</code> on success, <code>NO</code> on failure.
 * @since 4.0
 */
+ (BOOL)setSharedInstanceWithOptions:(GCKCastOptions *)options
                               error:(GCKError *_Nullable *_Nullable)error;

/**
 * Returns the singleton instance. If a shared instance has not yet been initialized, an exception
 * will be thrown.
 */
+ (instancetype)sharedInstance;

/**
 * Tests if the singleton instance has been initialized yet.
 *
 * @since 3.5.4
 */
+ (BOOL)isSharedInstanceInitialized;

/**
 * Registers a device provider, which adds support for a new type of (non-Cast) device.
 *
 * @param deviceProvider An instance of a GCKDeviceProvider subclass for managing the devices.
 */
- (void)registerDeviceProvider:(GCKDeviceProvider *)deviceProvider;

/**
 * Unregisters the device provider for a given device category.
 *
 * @param category A string that uniquely identifies the type of device.
 */
- (void)unregisterDeviceProviderForCategory:(NSString *)category;

/**
 * Sets the credentials data of the current user. You should call this API with the current user
 * information before starting a cast session and whenever user account is changed.
 *
 * The credentials data will be embedded in the launch request. If it is to launch an
 * Android TV app, the app can use the credentials data to determine if the app supports
 * this specific user. If not, the cast app will be launched instead.
 *
 * If an Android TV app is launched, the credential data will be passed to the app, within
 * the launch intent. The app can use this data to personalize the user experience.
 *
 * @param credentialsData An instance of @c GCKCredentialsData. May be <code>nil</code>.
 */
- (void)setLaunchCredentialsData:(GCKCredentialsData *_Nullable)credentialsData;

@end

NS_ASSUME_NONNULL_END
