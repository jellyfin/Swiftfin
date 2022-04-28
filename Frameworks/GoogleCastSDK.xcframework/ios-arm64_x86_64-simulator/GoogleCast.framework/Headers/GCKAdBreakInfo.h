// Copyright 2013 Google Inc.

#import <GoogleCast/GCKAdBreakClipInfo.h>
#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class representing an ad break.
 *
 * @since 3.1
 */
GCK_EXPORT
@interface GCKAdBreakInfo : NSObject <NSCopying, NSSecureCoding>

/**
 * A string that uniquely identifies this ad break.
 *
 * @since 3.3
 */
@property(nonatomic, strong, readonly) NSString *adBreakID;

/**
 * The playback position, in seconds, at which this ad will start playing.
 *
 * @since 3.1
 */
@property(nonatomic, assign, readonly) NSTimeInterval playbackPosition;

/**
 * A list of identifier strings for the ad break clips contained by this ad break.
 *
 * @since 3.3
 */
@property(nonatomic, strong, readonly, nullable) NSArray<NSString *> *adBreakClipIDs;

/**
 * Whether the ad break has already been watched or not.
 *
 * @since 3.3
 */
@property(nonatomic, assign, readonly) BOOL watched;

/**
 * Whether the ad break is embedded.
 *
 * @since 4.1
 */
@property(nonatomic, assign, readonly) BOOL embedded;

/**
 * Whether the ad break is expanded.
 *
 * @since 4.7.0
 */
@property(nonatomic, assign, readonly) BOOL expanded;

/**
 * This is here for backwards compatibility reasons, but will return nil.
 */
- (instancetype)initWithPlaybackPosition:(NSTimeInterval)playbackPosition
    GCK_DEPRECATED("Use the GCKAdBreakInfoBuilder to initialize GCKAdBreakInfos.");

- (instancetype)init NS_UNAVAILABLE;

@end  // GCKAdBreakInfo

/**
 * A builder object for constructing new or derived GCKAdBreakInfo instances. The builder may
 * be used to derive a GCKAdBreakInfo from an existing one:
 *
 * @code
 * GCKAdBreakInfoBuilder *builder =
 *     [[GCKAdBreakInfoBuilder alloc] initWithAdBreakInfo:originalAdBreakInfo];
 * builder.adBreakID = ...; // Change the ad break clip ID.
 * builder.playbackPosition = 100; // Change the ad break's duration.
 * GCKAdBreakInfo *derivedAdBreakInfo = [builder build];
 * @endcode
 *
 * It can also be used to construct a new GCKAdBreakInfo from scratch:
 *
 * @code
 * GCKAdBreakInfoBuilder *builder =
 *     [[GCKAdBreakInfoBuilder alloc] initWithAdBreakID:...];
 * builder.title = ...;
 * builder.contentURL = ...;
 * builder.contentID = ...;
 * // Set all other desired propreties...
 * GCKAdBreakInfo *newAdBreakInfo = [builder build];
 * @endcode
 *
 * @since 4.3.4
 */
GCK_EXPORT
@interface GCKAdBreakInfoBuilder : NSObject

/**
 * A string that uniquely identifies this ad break.
 */
@property(nonatomic, copy) NSString *adBreakID;

/**
 * The playback position, in seconds, at which this ad will start playing.
 */
@property(nonatomic, assign) NSTimeInterval playbackPosition;

/**
 * A list of identifier strings for the ad break clips contained by this ad break.
 */
@property(nonatomic, copy, nullable) NSArray<NSString *> *adBreakClipIDs;

/**
 * Whether the ad break has already been watched or not.
 */
@property(nonatomic, assign) BOOL watched;

/**
 * Whether the ad break is embedded.
 */
@property(nonatomic, assign) BOOL embedded;

/**
 * Whether the ad break is expanded.
 */
@property(nonatomic, assign) BOOL expanded;

/*
 * Constructor for GCKAdBreakInfoBuilder using an existing adBreakInfo object.
 *
 * @param adBreakInfo The Ad Break Info object to copy fields from.
 */
- (instancetype)initWithAdBreakInfo:(GCKAdBreakInfo *)adBreakInfo;

/*
 * Constructor for GCKAdBreakInfoBuilder other fields will be set to default values.
 *
 * @param adBreakID The adBreakID of the ad break to be built.
 * @param adBreakClipIDs The list of ad break clip IDs in this ad break.
 */
- (instancetype)initWithAdBreakID:(NSString *)adBreakID
                   adBreakClipIds:(nullable NSArray<NSString *> *)adBreakClipIDs
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

- (GCKAdBreakInfo *)build;

@end  // GCKAdBreakInfoBuilder

NS_ASSUME_NONNULL_END
