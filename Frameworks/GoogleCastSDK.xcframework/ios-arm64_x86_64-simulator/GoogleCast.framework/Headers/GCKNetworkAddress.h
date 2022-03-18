// Copyright (c) 2018 Google Inc. All rights reserved.

#import <Foundation/Foundation.h>
#import <GoogleCast/GCKDefines.h>

/**
 * @enum GCKNetworkAddressType
 *
 * Network address types.
 *
 * @ingroup Networking
 */
typedef NS_ENUM(NSInteger, GCKNetworkAddressType) {
  /** Unknown address type. */
  GCKNetworkAddressTypeUnknown = 0,
  /** IPv4 address. */
  GCKNetworkAddressTypeIPv4 = 1,
  /** IPv6 address. */
  GCKNetworkAddressTypeIPv6 = 2,
  /** IPC (UNIX domain) address. */
  GCKNetworkAddressTypeIPC = 3,
};

NS_ASSUME_NONNULL_BEGIN

/**
 * An object that represents a network IP address. This object is immutable.
 *
 * @ingroup Networking
 *
 * @since 4.2
 */
GCK_EXPORT
@interface GCKNetworkAddress : NSObject <NSCopying, NSCoding>

/** The address type. */
@property(nonatomic, assign, readonly) GCKNetworkAddressType type;
/** The IP address. */
@property(nonatomic, copy, readonly, nullable) NSString *ipAddress;
/**
 * The network address as an NSData containing the appropriate address structure
 * (e.g., struct in_addr or struct in6_addr). For the address type IPC, this field is a UTF8
 * encoding.
 */
@property(nonatomic, copy, readonly, nullable) NSData *addressData;

/** Using the default initializer is not allowed. */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Constructs a GCKNetworkAddress with the given address type and IP address.
 *
 * @param type The address type.
 * @param ipAddress The IP address, in textual form. May be <code>nil</code> to indicate the
 *     wildcard ("any") address.
 */
- (instancetype)initWithType:(GCKNetworkAddressType)type ipAddress:(nullable NSString *)ipAddress;

/**
 * Constructs a GCKNetworkAddress with the given address type and raw address.
 *
 * @param type The address type.
 * @param addressData An NSData object containing the appropriate address structure (e.g.,
 *     struct in_addr or struct in6_addr). For the GCKNNetworkAddressTypeIPC, the data is expected
 * to be a UTF8 encoding.
 */
- (instancetype)initWithType:(GCKNetworkAddressType)type addressData:(nullable NSData *)addressData;

/**
 * Constructs a wildcard address of the given type.
 */
+ (GCKNetworkAddress *)wildcardAddressOfType:(GCKNetworkAddressType)type;

/**
 * Constructs a loopback address of the given type.
 */
+ (GCKNetworkAddress *)loopbackAddressOfType:(GCKNetworkAddressType)type;

/**
 * Constructs an IPv4 broadcast address.
 */
+ (GCKNetworkAddress *)IPv4BroadcastAddress;

/**
 * Constructs an IPv4 address.
 */
+ (GCKNetworkAddress *)addressWithIPv4Address:(NSString *)ipAddress;

/**
 * Constructs an IPv6 address.
 */
+ (GCKNetworkAddress *)addressWithIPv6Address:(NSString *)ipAddress;

/**
 * Constructs an IPC address.
 */
+ (GCKNetworkAddress *)addressWithIPCPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
