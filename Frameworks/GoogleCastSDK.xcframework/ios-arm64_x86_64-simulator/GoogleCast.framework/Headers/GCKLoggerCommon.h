// Copyright 2016 Google Inc.

/**
 * @file GCKLoggerCommon.h
 * GCKLoggerLevel enum.
 */

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

/**
 * @enum GCKLoggerLevel
 * Logging levels.
 *
 * @since 3.1
 */
typedef NS_ENUM(NSInteger, GCKLoggerLevel) {
  /** No logging level (for backward compatibility). */
  GCKLoggerLevelNone = 0,
  /** Verbose messages. */
  GCKLoggerLevelVerbose = 1,
  /** Debug messages. */
  GCKLoggerLevelDebug = 2,
  /** Informational messages. */
  GCKLoggerLevelInfo = 3,
  /** Warning messages. */
  GCKLoggerLevelWarning = 4,
  /** Error messages. */
  GCKLoggerLevelError = 5,
  /** Assertion failure messages. */
  GCKLoggerLevelAssert = 6
};
