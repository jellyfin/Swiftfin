// Copyright 2016 Google Inc.

#import <Foundation/Foundation.h>

#import <GoogleCast/GCKDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The receiver application ID for the Default Media Receiver.
 *
 * @memberof GCKDiscoveryCriteria
 */
GCK_EXTERN NSString *const kGCKDefaultMediaReceiverApplicationID;

/**
 * Device discovery filter criteria.
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKDiscoveryCriteria : NSObject<NSCopying, NSSecureCoding>

/** A list of supported receiver application IDs to test for. */
@property(nonatomic, strong, readonly, nullable) NSOrderedSet<NSString *> *applicationIDs;

/** Whether the discovery criteria includes any application IDs. */
@property(nonatomic, assign, readonly) BOOL hasApplicationIDs;

/** A list of supported namespaces to test for. */
@property(nonatomic, strong, readonly, nullable) NSSet<NSString *> *namespaces;

/** Whether the discovery criteria includes any namespaces. */
@property(nonatomic, assign, readonly) BOOL hasNamespaces;

/** The discovery criteria as a set of mDNS subtypes. */
@property(nonatomic, strong, readonly) NSSet<NSString *> *allSubtypes;

/**
 * Initializes a new GCKDiscoveryCriteria with a receiver application ID.
 *
 * @param applicationID The receiver application ID.
 */
- (instancetype)initWithApplicationID:(NSString *)applicationID;

/**
 * Initializes a new GCKDiscoveryCriteria with the given attributes.
 *
 * @param namespaces A set of namespaces.
 */
- (instancetype)initWithNamespaces:(NSSet<NSString *> *)namespaces;

@end

NS_ASSUME_NONNULL_END
