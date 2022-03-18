// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@class GCKDevice;

NS_ASSUME_NONNULL_BEGIN

GCK_EXTERN NSString *const kGCKKeyHasDiscoveredDevices;

typedef NS_ENUM(NSInteger, GCKDiscoveryState) {
  GCKDiscoveryStateStopped = 0,
  GCKDiscoveryStateRunning = 1
};

@protocol GCKDiscoveryManagerListener;

/**
 * A class that manages the device discovery process. GCKDiscoveryManager manages a collection of
 * GCKDeviceProvider subclass instances, each of which is responsible for discovering devices of
 * a specific type. It also maintains a lexicographically ordered list of the currently discovered
 * devices.
 *
 * The framework automatically starts the discovery process when the application moves to the
 * foreground and suspends it when the application moves to the background. It is generally not
 * necessary for the application to call GCKDiscoveryManager::startDiscovery and
 * GCKDiscoveryManager::stopDiscovery, except as an optimization measure to reduce network traffic
 * and CPU utilization in areas of the application that do not use Cast functionality.
 *
 * If the application is using the framework's Cast dialog, either by way of GCKUICastButton or
 * by presenting it directly, then that dialog will use GCKDiscoveryManager to populate its list
 * of available devices. If however the application is providing its own device selection/control
 * dialog UI, then it should use the GCKDiscoveryManager and its associated listener protocol,
 * GCKDiscoveryManagerListener, to populate and update its list of available devices.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKDiscoveryManager : NSObject

/**
 * The current discovery state.
 */
@property(nonatomic, assign, readonly) GCKDiscoveryState discoveryState;

/**
 * A flag indicating whether any devices have been discovered by any of the discovery providers
 * managed by this object.
 */
@property(nonatomic, assign, readonly) BOOL hasDiscoveredDevices;

/**
 * A flag indicating whether discovery should employ a "passive" scan. Passive scans are less
 * resource-intensive but do not provide results that are as fresh as active scans.
 */
@property(nonatomic, assign) BOOL passiveScan;

/**
 * A flag indicating whether discovery is active or not.
 *
 * @since 3.4
 */
@property(nonatomic, assign, readonly) BOOL discoveryActive;

/**
 * The number of devices that are currently discovered.
 */
@property(nonatomic, assign, readonly) NSUInteger deviceCount;

/**
 * Default initializer is not available.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Adds a listener that will receive discovery notifications.
 *
 * The added listener is weakly held, and should be retained to avoid unexpected deallocation.
 *
 * @param listener The listener to add.
 */
- (void)addListener:(id<GCKDiscoveryManagerListener>)listener;

/**
 * Removes a previously registered listener.
 *
 * @param listener The listener to remove.
 */
- (void)removeListener:(id<GCKDiscoveryManagerListener>)listener;

/**
 * Starts the discovery process.
 */
- (void)startDiscovery;

/**
 * Stops the discovery process.
 */
- (void)stopDiscovery;

/**
 * Tests whether discovery is currently active for the given device category.
 */
- (BOOL)isDiscoveryActiveForDeviceCategory:(NSString *)deviceCategory;

/**
 * Returns the device at the given index in the manager's list of discovered devices.
 */
- (GCKDevice *)deviceAtIndex:(NSUInteger)index;

/**
 * Returns the device with the given unique ID in the manager's list of discovered devices.
 *
 * @param uniqueID The device's unique ID.
 * @return The matching GCKDevice object, or <code>nil</code> if a matching device was not found.
 */
- (nullable GCKDevice *)deviceWithUniqueID:(NSString *)uniqueID;

/**
 * Waits for a device with the given unique ID to be discovered, and invokes a completion block. If
 * a matching device is already in the discovered device list, the completion block will be invoked
 * immediately (but after this method returns). Only one find operation can be active at a time;
 * starting a new find operation while another one is in progress will cancel the current one.
 *
 * @param uniqueID The unique ID of the device.
 * @param timeout The maximum amount of time to wait for the device to be discovered.
 * @param completion The completion block to invoke when either the device is found or the timeout
 * is reached. The device (if found) or <code>nil</code> (if not found) will be passed to the
 * completion block.
 *
 * @since 4.0
 */
- (void)findDeviceWithUniqueID:(NSString *)uniqueID
                       timeout:(NSTimeInterval)timeout
                    completion:(void (^)(GCKDevice *))completion;

/**
 * Cancels any in-progress find operation started by findDeviceWithUniqueID:timeout:completion:.
 *
 * @since 4.0
 */
- (void)cancelFindOperation;

@end

/**
 * The GCKDiscoveryManager listener protocol.
 *
 * @since 3.0
 */
@protocol GCKDiscoveryManagerListener <NSObject>

@optional

/**
 * Called when discovery has started for the given device category.
 */
- (void)didStartDiscoveryForDeviceCategory:(NSString *)deviceCategory;

/**
 * Called when the list of discovered devices is about to be updated in some way.
 */
- (void)willUpdateDeviceList;

/**
 * Called when the list of discovered devices has been updated in some way.
 */
- (void)didUpdateDeviceList;

/**
 * Called when a newly-discovered device has been inserted into the list of devices.
 *
 * @param device The device that was inserted.
 * @param index The list index at which the device was inserted.
 */
- (void)didInsertDevice:(GCKDevice *)device atIndex:(NSUInteger)index;

/**
 * Called when a previously-discovered device has been updated.
 *
 * @param device The device that was updated.
 * @param index The list index of the device.
 */
- (void)didUpdateDevice:(GCKDevice *)device atIndex:(NSUInteger)index;

/**
 * Called when a previously-discovered device has been updated and/or reordered within the list.
 *
 * @param device The device that was updated.
 * @param index The previous list index of the device.
 * @param newIndex The current list index of the device.
 */
- (void)didUpdateDevice:(GCKDevice *)device
                atIndex:(NSUInteger)index
         andMoveToIndex:(NSUInteger)newIndex;

/**
 * Called when a previously-discovered device has gone offline and has been removed from the list of
 * devices.
 *
 * @param index The list index of the device that was removed.
 */
- (void)didRemoveDeviceAtIndex:(NSUInteger)index;

/**
 * Called when a previously-discovered device has gone offline and has been
 * removed from the list of devices. This is an alternative to @ref
 * didRemoveDeviceAtIndex:. If both are implemented, both will be called.
 *
 * @param device The device that was removed.
 * @param index The list index of the device that was removed.
 *
 * @since 4.1
 */
- (void)didRemoveDevice:(GCKDevice *)device atIndex:(NSUInteger)index;

/**
 * Called when there are some previously-discovered devices in the list before the discovery process
 * starts. These devices are still valid and not expired since being discovered by the last
 * discovery process. The full list of previously-discovery devices can be obtained by using @ref
 * deviceCount: and @ref deviceAtIndex:.
 *
 * @since 4.4.1
 */
- (void)didHaveDiscoveredDeviceWhenStartingDiscovery;

@end

NS_ASSUME_NONNULL_END
