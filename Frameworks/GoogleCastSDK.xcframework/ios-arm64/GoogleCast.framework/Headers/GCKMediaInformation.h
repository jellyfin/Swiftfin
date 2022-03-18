// Copyright 2013 Google Inc.

#import <Foundation/Foundation.h>
#import <GoogleCast/GCKAdBreakClipInfo.h>
#import <GoogleCast/GCKAdBreakInfo.h>
#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKHLSSegmentFormat.h>
#import <GoogleCast/GCKHLSVideoSegmentFormat.h>

/**
 * @file GCKMediaInformation.h
 * GCKMediaStreamType enum.
 */

@class GCKMediaMetadata;
@class GCKMediaTextTrackStyle;
@class GCKMediaTrack;

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKMediaStreamType
 * Enum defining the media stream type.
 */
typedef NS_ENUM(NSInteger, GCKMediaStreamType) {
  /** A stream type of "none". */
  GCKMediaStreamTypeNone = 0,
  /** A buffered stream type. */
  GCKMediaStreamTypeBuffered = 1,
  /** A live stream type. */
  GCKMediaStreamTypeLive = 2,
  /** An unknown stream type. */
  GCKMediaStreamTypeUnknown = 99,
};

/**
 * A class that aggregates information about a media item.
 */
GCK_EXPORT
@interface GCKMediaInformation : NSObject <NSCopying, NSSecureCoding>

/**
 * The content ID for this stream.
 */
@property(nonatomic, copy, readonly, nullable) NSString *contentID;

/**
 * The URL of the content to be played.
 *
 * @since 4.3.4
 */
@property(nonatomic, copy, readonly, nullable) NSURL *contentURL;

/**
 * The stream type.
 */
@property(nonatomic, readonly) GCKMediaStreamType streamType;

/**
 * The content (MIME) type.
 */
@property(nonatomic, copy, readonly) NSString *contentType;

/**
 * The media item metadata.
 */
@property(nonatomic, readonly, nullable) GCKMediaMetadata *metadata;

/**
 * The list of ad breaks in this content.
 */
@property(nonatomic, copy, readonly, nullable) NSArray<GCKAdBreakInfo *> *adBreaks;

/**
 * The list of ad break clips in this content.
 *
 * @since 3.3
 */
@property(nonatomic, copy, readonly, nullable) NSArray<GCKAdBreakClipInfo *> *adBreakClips;

/**
 * The length of the stream, in seconds, or <code>INFINITY</code> if it is a live stream.
 */
@property(nonatomic, readonly) NSTimeInterval streamDuration;

/**
 * The media tracks for this stream.
 */
@property(nonatomic, copy, readonly, nullable) NSArray<GCKMediaTrack *> *mediaTracks;

/**
 * The text track style for this stream.
 */
@property(nonatomic, copy, readonly, nullable) GCKMediaTextTrackStyle *textTrackStyle;

/**
 * The deep link for the media as used by Google Assistant, if any.
 *
 * @since 4.0
 */
@property(nonatomic, copy, readonly, nullable) NSString *entity;

/**
 * The VMAP request configuration if any. See more here:
 * <a href="https://www.iab.com/guidelines/digital-video-ad-serving-template-vast-4-0/">
 * Digital Video Ad Serving Template 4.0</a>.
 * If this is non-nil, all other ads related fields will be ignored.
 *
 * @since 4.3.4
 */
@property(nonatomic, readonly, nullable) GCKVASTAdsRequest *VMAP;

/**
 * The epoch time, in seconds, of a live stream's start time.
 * For live streams that have a known start time, e.g. a live TV show or sport game, it would be the
 * epoch time that the event started. Otherwise, it will be start time of the live seekable range
 * when the streaming started.
 *
 * @since 4.4.1
 */
@property(nonatomic, readonly) NSTimeInterval startAbsoluteTime;

/**
 * The format of the HLS audio segment.
 *
 * @since 4.6.0
 */
@property(nonatomic, readonly) GCKHLSSegmentFormat hlsSegmentFormat;

/**
 * The format of the HLS video segment.
 *
 * @since 4.6.0
 */
@property(nonatomic, readonly) GCKHLSVideoSegmentFormat hlsVideoSegmentFormat;

/**
 * The custom data, if any.
 */
@property(nonatomic, readonly, nullable) id customData;

/**
 * Deprecated. Use GCKMediaInformationBuilder to initialize GCKMediaInformation objects.
 *
 * @param contentID The content ID.
 * @param streamType The stream type.
 * @param contentType The content (MIME) type.
 * @param metadata The media item metadata.
 * @param adBreaks The list of ad breaks in this content.
 * @param adBreakClips The list of ad break clips in this content.
 * @param streamDuration The stream duration.
 * @param mediaTracks The media tracks, if any, otherwise <code>nil</code>.
 * @param textTrackStyle The text track style, if any, otherwise <code>nil</code>.
 * @param customData The custom application-specific data. Must either be an object that can be
 * serialized to JSON using <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or
 * <code>nil</code>.
 *
 * @since 4.3
 */
- (instancetype)initWithContentID:(NSString *)contentID
                       streamType:(GCKMediaStreamType)streamType
                      contentType:(NSString *)contentType
                         metadata:(nullable GCKMediaMetadata *)metadata
                         adBreaks:(nullable NSArray<GCKAdBreakInfo *> *)adBreaks
                     adBreakClips:(nullable NSArray<GCKAdBreakClipInfo *> *)adBreakClips
                   streamDuration:(NSTimeInterval)streamDuration
                      mediaTracks:(nullable NSArray<GCKMediaTrack *> *)mediaTracks
                   textTrackStyle:(nullable GCKMediaTextTrackStyle *)textTrackStyle
                       customData:(nullable id)customData
    GCK_DEPRECATED("Use GCKMediaInformationBuilder to initialize GCKMediaInformation objects.");

/**
 * Deprecated. Use GCKMediaInformationBuilder to initialize GCKMediaInformation objects.
 *
 * @param contentID The content ID.
 * @param streamType The stream type.
 * @param contentType The content (MIME) type.
 * @param metadata The media item metadata.
 * @param streamDuration The stream duration.
 * @param mediaTracks The media tracks, if any, otherwise <code>nil</code>.
 * @param textTrackStyle The text track style, if any, otherwise <code>nil</code>.
 * @param customData The custom application-specific data. Must either be an object that can be
 * serialized to JSON using <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or
 * <code>nil</code>.
 */
- (instancetype)initWithContentID:(NSString *)contentID
                       streamType:(GCKMediaStreamType)streamType
                      contentType:(NSString *)contentType
                         metadata:(nullable GCKMediaMetadata *)metadata
                   streamDuration:(NSTimeInterval)streamDuration
                      mediaTracks:(nullable NSArray<GCKMediaTrack *> *)mediaTracks
                   textTrackStyle:(nullable GCKMediaTextTrackStyle *)textTrackStyle
                       customData:(nullable id)customData
    GCK_DEPRECATED("Use GCKMediaInformationBuilder to initialize GCKMediaInformation objects.");

/**
 * Searches for a media track with the given track ID.
 *
 * @param trackID The media track ID.
 * @return The matching GCKMediaTrack object, or <code>nil</code> if there is no media track
 * with the given ID.
 */
- (nullable GCKMediaTrack *)mediaTrackWithID:(NSInteger)trackID;

@end

/**
 * A builder object for constructing new or derived GCKMediaInformation instances. The builder may
 * be used to derive a GCKMediaInformation from an existing one:
 *
 * @code
 * GCKMediaInformationBuilder *builder =
 *     [[GCKMediaInformationBuilder alloc] initWithMediaInformation:originalMediaInfo];
 * builder.contentID = ...; // Change the content ID.
 * builder.streamDuration = 100; // Change the stream duration.
 * GCKMediaInformation *derivedMediaInfo = [builder build];
 * @endcode
 *
 * It can also be used to construct a new GCKMediaInformation from scratch:
 *
 * @code
 * GCKMediaInformationBuilder *builder =
 *     [[GCKMediaInformationBuilder alloc] initWithContentURL:...];
 * builder.contentType = ...;
 * builder.streamType = ...;
 * builder.metadata = ...;
 * // Set all other desired propreties...
 * GCKMediaInformation *newMediaInfo = [builder build];
 * @endcode
 *
 * @since 4.0
 */
GCK_EXPORT
@interface GCKMediaInformationBuilder : NSObject

/**
 * The content ID for this stream.
 * @deprecated Use contentURL and entity instead.
 */
@property(nonatomic, copy, nullable) NSString *contentID;

/**
 * The URL of the content to be played.
 *
 * @since 4.3.4
 */
@property(nonatomic, copy, nullable) NSURL *contentURL;

/**
 * The stream type. Defaults to GCKMediaStreamTypeBuffered.
 */
@property(nonatomic, assign) GCKMediaStreamType streamType;

/**
 * The content (MIME) type.
 */
@property(nonatomic, copy, nullable) NSString *contentType;

/**
 * The media item metadata.
 */
@property(nonatomic, nullable) GCKMediaMetadata *metadata;

/**
 * The list of ad breaks in this content.
 */
@property(nonatomic, copy, nullable) NSArray<GCKAdBreakInfo *> *adBreaks;

/**
 * The list of ad break clips in this content.
 */
@property(nonatomic, copy, nullable) NSArray<GCKAdBreakClipInfo *> *adBreakClips;

/**
 * The length of the stream, in seconds, or <code>INFINITY</code> if it is a live stream. Defaults
 * to 0.
 */
@property(nonatomic, assign) NSTimeInterval streamDuration;

/**
 * The media tracks for this stream.
 */
@property(nonatomic, copy, nullable) NSArray<GCKMediaTrack *> *mediaTracks;

/**
 * The text track style for this stream.
 */
@property(nonatomic, copy, nullable) GCKMediaTextTrackStyle *textTrackStyle;

/**
 * The deep link for the media as used by Google Assistant, if any.
 */
@property(nonatomic, copy, nullable) NSString *entity;

/**
 * The VMAP request configuration if any. See more here:
 * <a href="https://www.iab.com/guidelines/digital-video-ad-serving-template-vast-4-0/">
 * Digital Video Ad Serving Template 4.0</a>.
 * If this is non-nil, all other ads related fields will be ignored.
 *
 * @since 4.3.4
 */
@property(nonatomic, nullable) GCKVASTAdsRequest *VMAP;

/**
 * The start time of the stream, in seconds in epoch time, or <code>kGCKInvalidTimeInterval</code>
 * if it is not available. Defaults to <code>kGCKInvalidTimeInterval</code>.
 *
 * @since 4.4.1
 */
@property(nonatomic) NSTimeInterval startAbsoluteTime;

/**
 * The format of the HLS audio segment.
 *
 * @since 4.6.0
 */
@property(nonatomic) GCKHLSSegmentFormat hlsSegmentFormat;

/**
 * The format of the HLS video segment.
 *
 * @since 4.6.0
 */
@property(nonatomic) GCKHLSVideoSegmentFormat hlsVideoSegmentFormat;

/**
 * The custom data, if any.
 */
@property(nonatomic, nullable) id customData;

/**
 * Constructs a new GCKMediaInformationBuilder with the given required attributes, and all other
 * attributes initialized to default values.
 * @param contentURL The URL of the content to be played.
 *
 * @since 4.3.4
 */
- (instancetype)initWithContentURL:(NSURL *)contentURL;

/**
 * Constructs a new GCKMediaInformationBuilder with the given required attributes, and all other
 * attributes initialized to default values.
 */
- (instancetype)initWithEntity:(NSString *)entity;

/**
 * Constructs a new GCKMediaInformationBuilder with attributes copied from the given
 * GCKMediaInformation instance.
 *
 * @param mediaInfo The instance to copy.
 */
- (instancetype)initWithMediaInformation:(GCKMediaInformation *)mediaInfo;

/**
 * Constructs a new GCKMediaInformationBuilder with the given required attributes, and all other
 * attributes initialized to default values.
 * @deprecated Use initWithContentURL: or initWithEntity: instead.
 */
- (instancetype)initWithContentID:(NSString *)contentID
    GCK_DEPRECATED("Use initWithContentURL: or initWithEntity:");

/**
 * Constructs a new GCKMediaInformationBuilder with the given required attributes, and all other
 * attributes initialized to default values.
 * @deprecated Use initWithContentURL: or initWithEntity: instead.
 */
- (instancetype)initWithContentID:(NSString *)contentID
                           entity:(NSString *)entity
    GCK_DEPRECATED("Use initWithContentURL: or initWithEntity:");

/**
 * Builds a GCKMediaInformation using the builder's current attributes.
 *
 * @return The new GCKMediaInformation instance.
 */
- (GCKMediaInformation *)build;

@end

NS_ASSUME_NONNULL_END
