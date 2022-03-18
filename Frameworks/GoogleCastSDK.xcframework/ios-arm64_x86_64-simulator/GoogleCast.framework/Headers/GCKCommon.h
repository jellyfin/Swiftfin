// Copyright 2014 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

/**
 * @file GCKCommon.h
 * GCKCastState, GCKConnectionState, GCKConnectionSuspendReason, GCKActiveInputStatus, and
 * GCKStandbyStatus enums.
 */

/**
 * @var kGCKFrameworkVersion
 * A string constant containing the version number of the GoogleCast framework.
 */
GCK_EXTERN NSString *const kGCKFrameworkVersion;

/**
 * @var kGCKInvalidRequestID
 * An invalid request ID; if a method returns this request ID, it means that the request could
 * not be made.
 */
GCK_EXTERN const NSInteger kGCKInvalidRequestID;

/**
 * @var kGCKThreadException
 * An exception type indicating that an API was called from an invalid thread.
 */
GCK_EXTERN NSString *const kGCKThreadException;

/**
 * @enum GCKConnectionState
 * Enum defining Cast connection states.
 */
typedef NS_ENUM(NSInteger, GCKConnectionState) {
  /** Disconnected from the device or application. */
  GCKConnectionStateDisconnected = 0,
  /** Connecting to the device or application. */
  GCKConnectionStateConnecting = 1,
  /** Connected to the device or application. */
  GCKConnectionStateConnected = 2,
  /** Disconnecting from the device. */
  GCKConnectionStateDisconnecting = 3
};

/**
 * @enum GCKConnectionSuspendReason
 * Enum defining the reasons for a connection becoming suspended.
 */
typedef NS_ENUM(NSInteger, GCKConnectionSuspendReason) {
  GCKConnectionSuspendReasonUnknown = -1,
  GCKConnectionSuspendReasonNone = 0,
  /** The connection was suspended because the application is going into the background. */
  GCKConnectionSuspendReasonAppBackgrounded = 1,
  /** The connection was suspended because of a network I/O or protocol error. */
  GCKConnectionSuspendReasonNetworkError = 2,
  /** The connection was suspended because the network is not reachable. */
  GCKConnectionSuspendReasonNetworkNotReachable = 3,
  /** The connection was suspended because app was terminated while connected. */
  GCKConnectionSuspendReasonAppTerminated = 4,
};

/**
 * @enum GCKActiveInputStatus
 * An enum describing the active input status states. This status indicates whether a receiver
 * device is currently the active input on its connected TV or AVR.
 */
typedef NS_ENUM(NSInteger, GCKActiveInputStatus) {
  /** The active input status is unknown. */
  GCKActiveInputStatusUnknown = -1,
  /** The input is inactive. */
  GCKActiveInputStatusInactive = 0,
  /** The input is active. */
  GCKActiveInputStatusActive = 1,
};

/**
 * @enum GCKStandbyStatus
 * An enum describing the standby status states. This status indicates whether a receiver device's
 * connected TV or AVR is currently in "standby" mode.
 */
typedef NS_ENUM(NSInteger, GCKStandbyStatus) {
  /** The standby status is unknown.  */
  GCKStandbyStatusUnknown = -1,
  /** The device is not in standby mode.  */
  GCKStandbyStatusInactive = 0,
  /** The device is in standby mode.  */
  GCKStandbyStatusActive = 1,
};

/**
 * @enum GCKCastState
 *
 * An enum describing the possible casting states for the sender application.
 */
typedef NS_ENUM(NSUInteger, GCKCastState) {
  /** No Cast session is established, and no Cast devices are available. */
  GCKCastStateNoDevicesAvailable = 0,
  /** No Cast session is establishd, and Cast devices are available. */
  GCKCastStateNotConnected = 1,
  /** A Cast session is being established. */
  GCKCastStateConnecting = 2,
  /** A Cast session is established. */
  GCKCastStateConnected = 3,
};
