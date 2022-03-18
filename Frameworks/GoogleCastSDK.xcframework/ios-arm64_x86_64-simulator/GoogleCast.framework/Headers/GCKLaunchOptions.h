// Copyright 2014 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Receiver application launch options. Changes to this object must be made before passing it to the
 * GCKCastContext.
 */
GCK_EXPORT
@interface GCKLaunchOptions : NSObject <NSCopying, NSSecureCoding>

/** The sender's language code as per RFC 5646. The default is the sender device's language. */
@property(nonatomic, copy, nullable) NSString *languageCode;

/**
 * A flag indicating whether the receiver application should be relaunched if it is already
 * running. The default is <code>NO</code>.
 */
@property(nonatomic, assign) BOOL relaunchIfRunning;

/**
 * A flag indicating whether the sender application supports casting to an Android TV application.
 * Default value is <code>NO</code>.
 *
 * @since 4.4.7
 */
@property(nonatomic, assign) BOOL androidReceiverCompatible;

/** Initializes the object with default values. */
- (instancetype)init;

/**
 * Initializes the object with the sender device's language code and the specified relaunch
 * behavior.
 */
- (instancetype)initWithRelaunchIfRunning:(BOOL)relaunchIfRunning;

/**
 * Initializes the object with the specified language code and relaunch behavior.
 *
 * @param languageCode The language code as per RFC 5646.
 * @param relaunchIfRunning A flag indicating whether the receiver application should be relaunched
 * if it is already running.
 */
- (instancetype)initWithLanguageCode:(nullable NSString *)languageCode
                   relaunchIfRunning:(BOOL)relaunchIfRunning;

/**
 * Initializes the object with the sender device's language code, the specified relaunch
 * behavior and if the sender application supports Android TV application.
 *
 * @since 4.4.7
 */
- (instancetype)initWithRelaunchIfRunning:(BOOL)relaunchIfRunning
                androidReceiverCompatible:(BOOL)androidReceiverCompatible;

/**
 * Designated initializer. Initializes the object with the specified language code,
 * relaunch behavior and support for Android TV application.
 *
 * @param relaunchIfRunning A flag indicating whether the receiver application should be relaunched
 * @param languageCode The language code as per RFC 5646.
 * @param androidReceiverCompatible A flag indicating whether the sender application supports
 * Android application on the receiver side.
 *
 * @since 4.4.7
 */
- (instancetype)initWithRelaunchIfRunning:(BOOL)relaunchIfRunning
                             languageCode:(nullable NSString *)languageCode
                androidReceiverCompatible:(BOOL)androidReceiverCompatible;

@end

NS_ASSUME_NONNULL_END
