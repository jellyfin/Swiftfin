#import <GoogleCast/GCKDevice.h>

#import <Foundation/Foundation.h>

#import <GoogleCast/GCKDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A device object that can be part of a multizone group.
 *
 * @since 4.3.5
 */
GCK_EXPORT
@interface GCKDynamicDevice : NSObject <NSCopying, NSSecureCoding>

/** The unique device ID. */
@property(nonatomic, copy, readonly) NSString *deviceID;

/** The friendly name of the device. */
@property(nonatomic, copy, readonly, nullable) NSString *friendlyName;

/** The device capabilities. */
@property(nonatomic, assign, readonly) GCKDeviceCapabilities capabilities;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Returns <code>YES</code> if the device supports the given capabilities.
 *
 * @param deviceCapabilities A bitwise-OR of one or more of the @ref GCKDeviceCapability constants.
 */
- (BOOL)hasCapabilities:(GCKDeviceCapabilities)deviceCapabilities;

@end  // GCKDynamicDevice

NS_ASSUME_NONNULL_END
