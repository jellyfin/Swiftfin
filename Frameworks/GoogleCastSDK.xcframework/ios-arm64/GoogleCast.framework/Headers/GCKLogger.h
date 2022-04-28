// Copyright 2013 Google Inc.

#import <GoogleCast/GCKLoggerCommon.h>

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@protocol GCKLoggerDelegate;
@class GCKLoggerFilter;

NS_ASSUME_NONNULL_BEGIN

/**
 * A singleton object used for logging by the framework. If a delegate is assigned, the formatted
 * log messages are passed to the delegate. Otherwise, the messages are written using
 * <a href="https://goo.gl/EwUYP8"><b>NSLog()</b></a> in debug builds and are discarded otherwise.
 *
 * See GCKLoggerDelegate for the delegate protocol.
 */
GCK_EXPORT
@interface GCKLogger : NSObject

/** The delegate to pass log messages to. */
@property(nonatomic, weak, nullable) id<GCKLoggerDelegate> delegate;

/**
 * The filter to apply to log messages.
 *
 * @since 3.0
 */
@property(nonatomic, strong, nullable) GCKLoggerFilter *filter;

/**
 * Flag for enabling or disabling logging. On by default.
 *
 * @since 3.0
 */
@property(nonatomic, assign) BOOL loggingEnabled;

/**
 * Flag for enabling or disabling file logging. Off by default. If enabled, log messages are
 * written to a set of rotating files in the app's cache directory. The number and maximum size
 * of these files can be configured via other properties of this class.
 *
 * @since 3.1
 */
@property(nonatomic, assign) BOOL fileLoggingEnabled;

/**
 * Flag for enabling or disabling logging directly to the console (via NSLog). Off by default.
 *
 * @since 4.1
 */
@property(nonatomic, assign) BOOL consoleLoggingEnabled;

/**
 * The maximum size of a log file, in bytes. The minimum is 32 KiB. If the value is 0, the default
 * maximum size of 2 MiB will be used.
 *
 * @since 3.1
 */
@property(nonatomic, assign) NSUInteger maxLogFileSize;

/**
 * The maximum number of log files. The minimum is 2.
 *
 * @since 3.1
 */
@property(nonatomic, assign) NSUInteger maxLogFileCount;

/**
 * The minimum logging level that will be logged.
 *
 * @since 3.0
 * @deprecated Specify minimum logging level in GCKLoggerFilter.
 */
@property(nonatomic, assign) GCKLoggerLevel minimumLevel DEPRECATED_ATTRIBUTE;

/**
 * Returns the GCKLogger singleton instance.
 */
+ (GCKLogger *)sharedInstance;

@end

/**
 * The GCKLogger delegate protocol.
 */
GCK_EXPORT
@protocol GCKLoggerDelegate <NSObject>

@optional

/**
 * Called by the framework to log a message.
 *
 * @param message The log message.
 * @param function The calling function or method.
 * @param level The logging level.
 * @param location The source code location of the log statement.
 *
 * @since 4.0
 */
- (void)logMessage:(NSString *)message
           atLevel:(GCKLoggerLevel)level
      fromFunction:(NSString *)function
          location:(NSString *)location;

/**
 * Called by the framework to log a message.
 *
 * @param function The calling function, normally obtained from <code>__func__</code>.
 * @param message The log message.
 *
 * @deprecated Use GCKLoggerDelegate::logMessage:atLevel:fromFunction:location: instead.
 */
- (void)logMessage:(NSString *)message fromFunction:(NSString *)function
    GCK_DEPRECATED("Use -[GCKLoggerDelegate logMessage:atLevel:fromFunction:location:]");

@end

NS_ASSUME_NONNULL_END

/**
 * @macro GCKLog
 * @deprecated Equivalent to NSLog().
 */
#define GCKLog NSLog
