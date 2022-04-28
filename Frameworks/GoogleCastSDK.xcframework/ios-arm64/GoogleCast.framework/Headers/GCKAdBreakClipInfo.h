// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaRequestItem.h>
#import <GoogleCast/GCKVastAdsRequest.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The value for the @ref whenSkippable field if an ad is not skippable.
 *
 * @since 4.3
 */
GCK_EXTERN const int kAdBreakClipNotSkippable;

// This is left here for backwards compatibility reasons.
GCK_EXPORT
GCK_DEPRECATED("Deprecated. Use GCKVASTAdsRequest instead.")
@interface GCKAdBreakClipVastAdsRequest : GCKVASTAdsRequest
@end

/**
 * A class representing an ad break clip.
 *
 * @since 3.3
 */
GCK_EXPORT
@interface GCKAdBreakClipInfo : NSObject <NSCopying, NSSecureCoding>

/** A string that uniquely identifies this ad break clip. */
@property(nonatomic, readonly) NSString *adBreakClipID;

/** The clip's duration. */
@property(nonatomic, readonly) NSTimeInterval duration;

/** The clip's title. */
@property(nonatomic, readonly, nullable) NSString *title;

/** The click-through URL for this clip. */
@property(nonatomic, readonly, nullable) NSURL *clickThroughURL;

/** URL for the content that represents this clip (typically an image). */
@property(nonatomic, readonly, nullable) NSURL *contentURL;

/** MIME type of the content referenced by @ref contentURL. */
@property(nonatomic, readonly, nullable) NSString *mimeType;

/**
 * The content's ID.
 * @since 4.1
 */
@property(nonatomic, readonly, nullable) NSString *contentID;

/**
 * The poster URL for this clip.
 * @since 4.1
 */
@property(nonatomic, readonly, nullable) NSURL *posterURL;

/**
 * The length of time into the clip when it can be skipped in seconds.
 * @since 4.3
 */
@property(nonatomic, readonly) NSTimeInterval whenSkippable;

/**
 * The HLS segment format for this clip.
 * @since 4.1
 */
@property(nonatomic, readonly) GCKHLSSegmentFormat hlsSegmentFormat;

/**
 * The VAST ad request configuration if any. See more here:
 * <a href="https://www.iab.com/guidelines/digital-video-ad-serving-template-vast-4-0/">
 * Digital Video Ad Serving Template 4.0</a>.
 * If this is non-nil, all other fields will be ignored.
 *
 * @since 4.1
 */
@property(nonatomic, readonly, nullable) GCKVASTAdsRequest *vastAdsRequest;

/** Custom application-specific data associated with the clip. */
@property(nonatomic, strong, readonly, nullable) id customData;

- (instancetype)init NS_UNAVAILABLE;

@end  // GCKAdBreakClipInfo

/**
 * A builder object for constructing new or derived GCKAdBreakClipInfo instances. The builder may
 * be used to derive a GCKAdBreakClipInfo from an existing one:
 *
 * @code
 * GCKAdBreakClipInfoBuilder *builder =
 *     [[GCKAdBreakClipInfoBuilder alloc] initWithAdBreakClipInfo:originalAdBreakClipInfo];
 * builder.adBreakClipID = ...; // Change the ad break clip ID.
 * builder.duration = 100; // Change the ad break's duration.
 * GCKAdBreakClipInfo *derivedAdBreakClipInfo = [builder build];
 * @endcode
 *
 * It can also be used to construct a new GCKAdBreakClipInfo from scratch:
 *
 * @code
 * GCKAdBreakClipInfoBuilder *builder =
 *     [[GCKAdBreakClipInfoBuilder alloc] initWithAdBreakClipID:...];
 * builder.title = ...;
 * builder.contentURL = ...;
 * builder.contentID = ...;
 * // Set all other desired propreties...
 * GCKAdBreakClipInfo *newAdBreakClipInfo = [builder build];
 * @endcode
 *
 * @since 4.3.4
 */
GCK_EXPORT
@interface GCKAdBreakClipInfoBuilder : NSObject

/** A string that uniquely identifies this ad break clip. */
@property(nonatomic, copy) NSString *adBreakClipID;

/** The clip's duration. */
@property(nonatomic) NSTimeInterval duration;

/** The clip's title. */
@property(nonatomic, copy, nullable) NSString *title;

/** The click-through URL for this clip. */
@property(nonatomic, copy, nullable) NSURL *clickThroughURL;

/** URL for the content that represents this clip (typically an image). */
@property(nonatomic, copy, nullable) NSURL *contentURL;

/** MIME type of the content referenced by @ref contentURL. */
@property(nonatomic, copy, nullable) NSString *mimeType;

/**
 * The content's ID.
 */
@property(nonatomic, copy, nullable) NSString *contentID;

/**
 * The poster URL for this clip.
 */
@property(nonatomic, copy, nullable) NSURL *posterURL;

/**
 * The length of time into the clip when it can be skipped in seconds.
 */
@property(nonatomic) NSTimeInterval whenSkippable;

/**
 * The HLS segment format for this clip.
 */
@property(nonatomic) GCKHLSSegmentFormat hlsSegmentFormat;

/**
 * The VAST ad request configuration if any. See more here:
 * <a href="https://www.iab.com/guidelines/digital-video-ad-serving-template-vast-4-0/">
 * Digital Video Ad Serving Template 4.0</a>.
 */
@property(nonatomic, nullable) GCKVASTAdsRequest *vastAdsRequest;

/** Custom application-specific data associated with the clip. */
@property(nonatomic, nullable) id customData;

/**
 * Constructs a new GCKAdBreakClipInfoBuilder with all of the fields of the adBreakClipInfo object.
 *
 * @param adBreakClipInfo The ad break clip info to get the fields from.
 */
- (instancetype)initWithAdBreakClipInfo:(GCKAdBreakClipInfo *)adBreakClipInfo;

/**
 * Constructs a new GCKAdBreakClipInfoBuilder with the ad break clip ID and all other attributes
 * initialized to default values.
 *
 * @param adBreakClipID The clip ID of the ad break clip info.
 */
- (instancetype)initWithAdBreakClipID:(NSString *)adBreakClipID NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Builds a GCKAdBreakClipInfo using the builder's current attributes.
 *
 * @return The new GCKAdBreakClipInfo instance.
 */
- (GCKAdBreakClipInfo *)build;

@end  // GCKAdBreakClipInfoBuilder

NS_ASSUME_NONNULL_END
