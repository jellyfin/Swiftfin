// Copyright 2017 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * An object representing options that can be passed to a Cast-enabled application via a deep-link
 * URL. The source app encodes the Cast-specific options (including the unique ID of the
 * device to cast to, and optionally the session ID of a specific Cast session to join) in a query
 * parameter of the application URL using #asURLQueryItem, and then opens the URL using
 * UIApplication's <code>-[openURL:options:completionHandler:]</code> method. The target app
 * extracts the  Cast-specific options from the URL it receives in its UIApplicationDelegate's
 * <code>-[application:openURL:options:]</code> method by calling
 * GCKOpenURLOptions::openURLOptionsFromURL:.
 * It then starts or joins a Cast session by passing these options to
 * GCKSessionManager::startSessionWithOpenURLOptions:sessionOptions:.
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKOpenURLOptions : NSObject<NSCopying, NSSecureCoding>

/**
 * The unique ID of the device to connect to. Required.
 */
@property(nonatomic, copy, nullable) NSString *deviceUniqueID;

/**
 * The friendly name of the device to connect to. Optional. This value is not used by the GoogleCast
 * framework, but may be of interest to the receiving application.
 */
@property(nonatomic, copy, nullable) NSString *deviceFriendlyName;

/**
 * The session ID of the Cast session to join. Optional. A value of <code>nil</code> indicates that
 * any currently active session should be joined, or if there is none, that a new one should be
 * created.
 */
@property(nonatomic, copy, nullable) NSString *sessionID;

/**
 * Extracts the Cast-specific options from the specified URL.
 *
 * @return The extracted options, or <code>nil</code> if the URL did not contain any Cast-specific
 * options.
 */
+ (nullable GCKOpenURLOptions *)openURLOptionsFromURL:(NSURL *)url;

/**
 * Converts the options into a URL query item.
 *
 * @return The options as an NSURLQueryItem.
 */
- (NSURLQueryItem *)asURLQueryItem;

@end

NS_ASSUME_NONNULL_END
