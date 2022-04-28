// Copyright 2016 Google Inc.

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKLoggerCommon.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class for filtering log messages that are produced using GCKLogger.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKLoggerFilter : NSObject

/**
 * A flag indicating whether the filter is exclusive (<code>YES</code>) or inclusive
 * (<code>NO</code>). By default filters are inclusive, that is, they accept all log messages that
 * match the filter.
 *
 * @deprecated No longer implemented; value is ignored.
 */
@property(nonatomic, assign) BOOL exclusive GCK_DEPRECATED("Not supported");

/**
 * The minimum logging level that will be logged from this filter.
 *
 * @since 3.2
 */
@property(nonatomic, assign) GCKLoggerLevel minimumLevel;

/**
 * Constructs a new GCKLoggerFilter with empty criteria.
 */
- (instancetype)init;

/**
 * Sets the minimum logging level that will be passed by the filter for the set of matching classes.
 * Glob patterns are supported for the class names.
 *
 * @param minimumLevel The minimum logging level for these classes. May be GCKLoggerLevelVerbose.
 * to include all levels.
 * @param classNames A list of class names.
 *
 * @since 3.3
 */
- (void)setLoggingLevel:(GCKLoggerLevel)minimumLevel forClasses:(NSArray<NSString *> *)classNames;

/**
 * Sets the minimum logging level that will be passed by the filter for the set of matching function
 * names. Glob patterns are supported.
 *
 * @param minimumLevel The minimum logging level for these functions. May be GCKLoggerLevelVerbose
 * to include all levels.
 * @param functionNames A list of function names.
 *
 * @since 3.3
 */
- (void)setLoggingLevel:(GCKLoggerLevel)minimumLevel
           forFunctions:(NSArray<NSString *> *)functionNames;

/**
 * Adds a list of class names to be matched by the filter. A class name can be a simple name or the
 * name of an extension, for example, <code>@@"MyClass"</code> or
 * <code>@@"MyClass(MyExtension)"</code>. If an extension is not included in the name, all
 * extensions of the class will be included implicitly. Glob patterns are supported.
 *
 * @deprecated Use @ref setLoggingLevel:forClasses: instead.
 */
- (void)addClassNames:(NSArray<NSString *> *)classNames
    GCK_DEPRECATED("Use setLoggingLevel:forClasses: instead");

/**
 * Adds a list of class names to be matched by the filter, specifying a minimum logging level. A
 * class name can be a simple name or the name of an extension, for example,
 * <code>@@"MyClass"</code> or <code>@@"MyClass(MyExtension)"</code>. If an extension is
 * not included in the name, all extensions of the class will be included implicitly. Glob patterns
 * are supported.
 *
 * @deprecated Use @ref setLoggingLevel:forClasses: instead.
 *
 * @param classNames The class names.
 * @param minimumLogLevel The minimum level to log; may be GCKLoggerLevelVerbose to log all levels.
 *
 * @since 3.2
 */
- (void)addClassNames:(NSArray<NSString *> *)classNames
      minimumLogLevel:(GCKLoggerLevel)minimumLogLevel
    GCK_DEPRECATED("Use setLoggingLevel:forClasses: instead");

/**
 * Adds a list of non-member function names to be matched by the filter. Glob patterns are
 * supported.
 *
 * @deprecated Use @ref setLoggingLevel:forFunctions: instead.
 */
- (void)addFunctionNames:(NSArray<NSString *> *)functionNames
    GCK_DEPRECATED("Use setLoggingLevel:forFunctions: instead");

/**
 * Adds a list of non-member function names to be matched by the filter, specifying a minimum
 * logging level. Glob patterns are supported.
 *
 * @deprecated Use @ref setLoggingLevel:forFunctions: instead.
 *
 * @param functionNames The function names.
 * @param minimumLogLevel The minimum level to log; may be GCKLoggerLevelVerbose to log all levels.
 *
 * @since 3.2
 */
- (void)addFunctionNames:(NSArray<NSString *> *)functionNames
         minimumLogLevel:(GCKLoggerLevel)minimumLogLevel
    GCK_DEPRECATED("Use setLoggingLevel:forFunctions: instead");

/**
 * Adds a list of regular expression patterns for matching the text of the log messages.
 */
- (void)addMessagePatterns:(NSArray<NSString *> *)messagePatterns;

/**
 * Adds a list of regular expression patterns for matching the text of the log messages with
 * optional case-insensitivity.
 *
 * @deprecated Use @ref addMessagePatterns: with inline (?-i) or (?i) instead.
 *
 */
- (void)addMessagePatterns:(NSArray<NSString *> *)messagePatterns
           caseInsensitive:(BOOL)caseInsensitive
  GCK_DEPRECATED("Use addMessagePatterns: with inline (?-i) or (?i) instead");

/**
 * Resets the filter; removing all match criteria.
 */
- (void)reset;

@end

NS_ASSUME_NONNULL_END
