// Copyright 2013 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

/** @file GCKError.h
 * Framework errors.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKErrorCode
 * Framework error codes.
 */
typedef NS_ENUM(NSInteger, GCKErrorCode) {
  /**
   * Error Code indicating no error.
   */
  GCKErrorCodeNoError = 0,

  /**
   * Error code indicating a network I/O error.
   */
  GCKErrorCodeNetworkError = 1,

  /**
   * Error code indicating that an operation has timed out.
   */
  GCKErrorCodeTimeout = 2,

  /**
   * Error code indicating an authentication error.
   */
  GCKErrorCodeDeviceAuthenticationFailure = 3,

  /**
   * Error code indicating that an invalid request was made.
   */
  GCKErrorCodeInvalidRequest = 4,

  /**
   * Error code indicating that an in-progress request has been cancelled, most likely because
   * another action has preempted it.
   */
  GCKErrorCodeCancelled = 5,

  /**
   * Error code indicating that a request has been replaced by another request of the same type.
   */
  GCKErrorCodeReplaced = 6,

  /**
   * Error code indicating that the request was disallowed and could not be completed.
   */
  GCKErrorCodeNotAllowed = 7,

  /**
   * Error code indicating that a request could not be made because the same type of request is
   * still in process.
   */
  GCKErrorCodeDuplicateRequest = 8,

  /**
   * Error code indicating that the request is not allowed in the current state.
   */
  GCKErrorCodeInvalidState = 9,

  /**
   * Error code indicating that data could not be sent because the send buffer is full.
   */
  GCKErrorCodeSendBufferFull = 10,

  /**
   * Error indicating that the request could not be sent because the message exceeds the maximum
   * allowed message size.
   */
  GCKErrorCodeMessageTooBig = 11,

  /**
   * Error indicating that a channel operation could not be completed because the channel is not
   * currently connected.
   */
  GCKErrorCodeChannelNotConnected = 12,

  /**
   * Error indicating that the user is not authorized to use a Cast device.
   */
  GCKErrorCodeDeviceAuthorizationFailure = 13,

  /**
   * Error indicating that a device request could not be completed because there is no connection
   * currently established to the device.
   */
  GCKErrorCodeDeviceNotConnected = 14,

  /**
   * Error indicating that there is a mismatch between the protocol versions being used on the
   * sender and the receiver for a given namespace implementation.
   */
  GCKErrorCodeProtocolVersionMismatch = 15,

  /**
   * Error indicating that the maximum number of users is already connected to the receiver.
   */
  GCKErrorCodeMaxUsersConnected = 16,

  /**
   * Error indicating that the network is not reachable.
   */
  GCKErrorCodeNetworkNotReachable = 17,

  /**
   * Error indicating a protocol error (invalid data received).
   */
  GCKErrorCodeProtocolError = 18,

  /**
   * Error indicating that an attempt was made to initialize an already initialized singleton.
   */
  GCKErrorCodeAlreadyInitialized = 19,

  /**
   * Error code indicating that a requested application could not be found.
   */
  GCKErrorCodeApplicationNotFound = 20,

  /**
   * Error code indicating that a requested application is not currently running.
   */
  GCKErrorCodeApplicationNotRunning = 21,

  /**
   * Error code indicating that the application session ID was not valid.
   */
  GCKErrorCodeInvalidApplicationSessionID = 22,

  /**
   * Error code indicating a TLS error. The underlying error is one of the
   * error codes as documented here:
   * https://developer.apple.com/library/mac/documentation/Security/Reference/secureTransportRef/
   */
  GCKErrorCodeSecureTransportError = 23,

  /**
   * Error indicating that a connect attempt was made on a socket that is already connected.
   */
  GCKErrorCodeSocketAlreadyConnected = 24,

  /**
   * Error indicating that an invalid network or socket address or address type was supplied to
   * a method or initializer.
   */
  GCKErrorCodeSocketInvalidAddress = 25,

  /**
   * Error indicating that an invalid parameter was supplied to a method or initializer.
   */
  GCKErrorCodeSocketInvalidParameter = 26,

  /**
   * Error indicating that the response received was invalid.
   */
  GCKErrorCodeInvalidResponse = 27,

  /**
   * Error indicating that the session update went through, but all devices could not be moved.
   */
  GCKErrorCodeFailedSessionUpdate = 28,

  /**
   * Error indicating that a device request could not be completed because the current session is
   * not active.
   *
   * @since 4.4.5
   */
  GCKErrorCodeSessionIsNotActive = 29,

  /**
   * Error code indicating that a media load failed on the receiver side.
   */
  GCKErrorCodeMediaLoadFailed = 30,

  /**
   * Error code indicating that a media media command failed because of the media player state.
   */
  GCKErrorCodeInvalidMediaPlayerState = 31,

  /**
   * Error indicating that no media session is currently available.
   */
  GCKErrorCodeNoMediaSession = 32,

  /**
   * Error code indicating that the current session is not a cast session.
   */
  GCKErrorCodeNotCastSession = 33,

  /**
   * Error code indicating that a generic media error happens.
   */
  GCKErrorCodeMediaError = 34,

  /**
   * Error code indicating that device authentication failed due to error received.
   */
  GCKErrorCodeAuthenticationErrorReceived = 40,

  /**
   * Error code indicating that device authentication failed because a malformed client certificate
   * is received.
   */
  GCKErrorCodeMalformedClientCertificate = 41,

  /**
   * Error code indicating that device authentication failed because certificate received from
   * Chromecast is not expected format.
   */
  GCKErrorCodeNotX509Certificate = 42,

  /**
   * Error code indicating that device authentication failed because the device certificate is not
   * trusted.
   */
  GCKErrorCodeDeviceCertificateNotTrusted = 43,

  /**
   * Error code indicating that device authentication failed because the SSL certificate is not
   * trusted.
   */
  GCKErrorCodeSSLCertificateNotTrusted = 44,

  /**
   * Error code indicating that device authentication failed because the response from device is
   * malformed.
   */
  GCKErrorCodeMalformedAuthenticationResponse = 45,

  /**
   * Error code indicating that device authentication failed because the device capability shows
   * unsupported.
   */
  GCKErrorCodeDeviceCapabilityNotSupported = 46,

  /**
   * Error code indicating that device authentication failed because CRL from device is invalid.
   */
  GCKErrorCodeCRLInvalid = 47,

  /**
   * Error code indicating that device authentication failed because device certificate is revoked
   * by CRL.
   */
  GCKErrorCodeCRLCheckFailed = 48,

  /**
   * Error code indicating that the broadcast message failed to encrypt.
   */
  GCKErrorCodeBroadcastMessageEncryptionFailed = 50,

  /**
   * Error code indicating that the key exchange response is invalid.
   */
  GCKErrorCodeBroadcastKeyExchangeInvalidResponse = 51,

  /**
   * Error code indicating that the key exchange response shows an invalid input error.
   */
  GCKErrorCodeBroadcastKeyExchangeInvalidInput = 52,

  /**
   * Error code indicating that the key exchange response doesn't contain a wrapped sender key.
   */
  GCKErrorCodeBroadcastKeyExchangeEmptyResponse = 53,

  /**
   * Error code indicating that the key exchange request has timed out.
   */
  GCKErrorCodeBroadcastKeyExchangeRequestTimeout = 54,

  /**
   * Error code indicating that no device that is capable for key exchange can be found.
   */
  GCKErrorCodeBroadcastKeyExchangeFailedToFindDevice = 55,

  /**
   * Error code indicating that it failed to connect to the device that is capable for key exchange.
   */
  GCKErrorCodeBroadcastKeyExchangeFailedToConnect = 56,

  /**
   * Error code indicating that the broadcast message is dropped because of cache limit.
   */
  GCKErrorCodeBroadcastMessageDropped = 57,

  /**
   * Error code indicating that the broadcast message is not sent out due to socket error.
   */
  GCKErrorCodeBroadcastSocketError = 58,

  /**
   * Error code indicating that the broadcast encryption key is failed to be generated.
   */
  GCKErrorCodeBroadcastFailedToGenerateEncryptionKey = 59,

  /**
   * Error code indicating that the listening failed.
   */
  GCKErrorCodeGuestModeListenFailed = 60,

  /**
   * Error code indicating that an unspecified Remote Display error has occurred. Additional details
   * may be available in the value associated with the key kGCKErrorExtraInfoKey in the user info.
   */
  GCKErrorCodeRemoteDisplayError = 80,

  /**
   * Error code indicating that the target device does not support Remote Display.
   */
  GCKErrorCodeRemoteDisplayDeviceNotSupported = 81,

  /**
   * Error code indicating that the target device does not support a paraticular Remote Display
   * feature.
   */
  GCKErrorCodeRemoteDisplayFeatureNotSupported = 82,

  /**
   * Error code indicating that the provided Remote Display configuration has been rejected by the
   * receiver device.
   */
  GCKErrorCodeRemoteDisplayConfigurationRejectedByReceiver = 83,

  /**
   * Error indicating that an OpenGL error has occurred. Additional details may be available in the
   * value associated with the key kGCKErrorExtraInfoKey in the user info.
   */
  GCKErrorCodeRemoteDisplayOpenGLError = 84,

  /**
   * Error indicating that a Metal error has occurred. Additional details may be available in the
   * value associated with the key kGCKErrorExtraInfoKey in the user info.
   */
  GCKErrorCodeRemoteDisplayMetalError = 85,

  /**
   * Error indicating that an audio conversion error has occurred. Additional details may be
   * available in the value associated with the key kGCKErrorExtraInfoKey in the user info.
   */
  GCKErrorCodeRemoteDisplayAudioConversionError = 86,

  /**
   * Error code indicating that the application moved to the background.
   */
  GCKErrorCodeAppDidEnterBackground = 91,

  /**
   * Error code indicating that the connection to the receiver was closed.
   */
  GCKErrorCodeDisconnected = 92,

  /**
   * Error code indicating that the feature or action is unsupported either on this iOS device or
   * the receiver.
   */
  GCKErrorCodeUnsupportedFeature = 93,

  /**
   * Error code indicating that an unknown, unexpected error has occurred.
   */
  GCKErrorCodeUnknown = 99,

  /**
   * Error code indicating that the authentication message received was not properly formatted and
   * encountered an error while parsing.
   *
   * @since 4.4.5
   */
  GCKErrorCodeDeviceAuthenticationMessageParseFailure = 100,

  /**
   * Error code indicating that the authentication message received had the <code>challenge</code>
   * property set to a non-null value.
   *
   * @since 4.4.5
   */
  GCKErrorCodeDeviceAuthenticationMessageChallengeReceivedFailure = 101,

  /**
   * Error code indicating that the authentication message request timed out.
   *
   * @since 4.4.5
   */
  GCKErrorCodeDeviceAuthenticationTimeoutFailure = 102,

  /**
   * Error code indicating that an  Application launch request was cancelled.
   *
   * @since 4.6.0
   */
  GCKErrorCodeLaunchRequestCancelled = 103
};

/**
 * The key for the customData JSON object associated with the error in the userInfo dictionary.
 */
GCK_EXTERN NSString *const kGCKErrorCustomDataKey;

/**
 * The key for an API-specific detailed error code.
 *
 * @since 4.4.3
 */
GCK_EXTERN NSString *const kGCKErrorDetailedCodeKey;

/**
 * The key for extra error information, such as an API-specific error description.
 */
GCK_EXTERN NSString *const kGCKErrorExtraInfoKey;

/**
 * The key for an API-specific error reason.
 *
 * @since 4.4.3
 */
GCK_EXTERN NSString *const kGCKErrorReasonKey;

/**
 * The error domain for GCKErrorCode.
 */
GCK_EXTERN NSString *const kGCKErrorDomain;

/**
 * A subclass of <a href="https://goo.gl/WJbrdL"><b>NSError</b></a> for framework errors.
 */
GCK_EXPORT
@interface GCKError : NSError

/** Constructs a GCKError with the given error code. */
+ (GCKError *)errorWithCode:(GCKErrorCode)code;

/** Constructs a GCKError with the given error code and optional custom data. */
+ (GCKError *)errorWithCode:(GCKErrorCode)code customData:(nullable id)customData;

/** Returns the human-readable description for a given error code. */
+ (NSString *)enumDescriptionForCode:(GCKErrorCode)code;

@end

NS_ASSUME_NONNULL_END
