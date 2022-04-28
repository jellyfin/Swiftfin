// Copyright 2013 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@class GCKImage;
@class GCKSenderApplicationInfo;

NS_ASSUME_NONNULL_BEGIN

/**
 * Information about a receiver application.
 */
GCK_EXPORT
@interface GCKApplicationMetadata : NSObject <NSCopying>

/** The application's unique ID. */
@property(nonatomic, copy, readonly) NSString *applicationID;

/** The application's name, in a format that is appropriate for display. */
@property(nonatomic, copy, readonly) NSString *applicationName;

/** Any icon images for the application, as an array of GCKImage objects. */
@property(nonatomic, copy, readonly, nullable)
    NSArray<GCKImage *> *images GCK_DEPRECATED("Use iconURL.");

/**
 * The icon URL for the application.
 *
 * @since 4.3.5
 */
@property(nonatomic, copy, readonly, nullable) NSURL *iconURL;

/** The set of protocol namespaces supported by this application. */
@property(nonatomic, copy, readonly, nullable) NSArray<NSString *> *namespaces;

/**
 * Information about the sender application that is the counterpart to the receiver application,
 * if any.
 */
@property(nonatomic, copy, readonly, nullable) GCKSenderApplicationInfo *senderApplicationInfo;

/**
 * The identifier (app ID) of the sender application that is the counterpart to the receiver
 * application, if any.
 */
- (nullable NSString *)senderAppIdentifier;

/**
 * The launch URL (URL scheme) for the sender application that is the counterpart to the receiver
 * application, if any.
 */
- (nullable NSURL *)senderAppLaunchURL;

@end

NS_ASSUME_NONNULL_END
