#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class GCKMediaInformation;
@class GCKMediaQueueData;

/**
 * Media load request data. This class is used by load media commands in @c GCKRemoteMediaClient for
 * specifying how a receiver application should load media.
 *
 * To load a single item, the item to load should be specified in @c mediaInformation.
 * To load a non-cloud queue, the queue information should be specified in @c queueData. Optionally,
 * the information for the first item to play can be specified in @c mediaInformation.
 * If the queue is a cloud queue, @c items in @queueData can be @c nil or empty, but @c entity needs
 * to be specified, so that the receiver app can fetch the queue from the cloud using @c entity.
 * If neither @c mediaInformation nor @c queueData is specified, load requests will fail without
 * sending to receiver applications.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaLoadRequestData : NSObject <NSCopying, NSSecureCoding>

/**
 * The media item to load.
 */
@property(nonatomic, copy, readonly, nullable) GCKMediaInformation *mediaInformation;

/**
 * The metadata of media item or queue.
 */
@property(nonatomic, copy, readonly, nullable) GCKMediaQueueData *queueData;

/**
 * The flag that indicates whether playback starts immediately after loaded. The default value is
 * <code>@(YES)</code>.
 *
 * When loading a queue by specifying the queue items in @c queueData, this value overrides the @c
 * autoplay of the first @ref GCKMediaQueueItem to be loaded in @c queueData. Only when this field
 * is @c nil, the @c autoplay property of individual @ref GCKMediaQueueItem in @c queueData will
 * take effect.
 *
 * When loading a single item by specifying the @c mediaInformation, this field specifies whether
 * the playback should start upon load. If @c nil, playback will not start immediately.
 */
@property(nonatomic, copy, readonly, nullable) NSNumber *autoplay;

/**
 * The initial playback position.
 * The default value is @ref kGCKInvalidTimeInterval, which indicates a default playback position.
 * If playing Video-On-Demand streams, it starts from 0; if playing live streams, it starts from
 * live edge.
 */
@property(nonatomic, assign, readonly) NSTimeInterval startTime;

/**
 * The playback rate. The default value is <code>1</code>.
 */
@property(nonatomic, assign, readonly) float playbackRate;

/**
 * An array of integers specifying the active tracks. The default value is <code>nil</code>.
 */
@property(nonatomic, strong, readonly, nullable) NSArray<NSNumber *> *activeTrackIDs;

/**
 * Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 */
@property(nonatomic, strong, readonly, nullable) id customData;

/**
 * The user credentials for the media item being loaded.
 */
@property(nonatomic, copy, readonly, nullable) NSString *credentials;

/**
 * The type of user credentials specified in #GCKMediaLoadRequestData::credentials.
 */
@property(nonatomic, copy, readonly, nullable) NSString *credentialsType;

/**
 * The alternate Android TV credentials for the media item being loaded.
 *
 * If set, these credentials will override the value set in #GCKMediaLoadRequestData::credentials if
 * the receiver is an Android TV app. On the receiver side, these credentials can be accessed from
 * @link MediaLoadRequestData#getCredentials @endlink.
 *
 * @since 4.7.0
 */
@property(nonatomic, copy, readonly, nullable) NSString *atvCredentials;

/**
 * The type of Android TV credentials specified in #GCKMediaLoadRequestData::atvCredentials.
 *
 * If set, this credentials type will override the value set in
 * #GCKMediaLoadRequestData::credentialsType if the receiver is an Android TV app. On the receiver
 * side, these credentials can be accessed from @link MediaLoadRequestData#getCredentialsType
 * @endlink.
 *
 * @since 4.7.0
 */
@property(nonatomic, copy, readonly, nullable) NSString *atvCredentialsType;

@end

/**
 * A builder object for constructing new or derived @c GCKMediaLoadRequestData instances. The
 * builder may be used to derive @c GCKMediaLoadRequestData from an existing one.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaLoadRequestDataBuilder : NSObject

/**
 * The media item to load.
 */
@property(nonatomic, copy, nullable) GCKMediaInformation *mediaInformation;

/**
 * The metadata of media item or queue.
 */
@property(nonatomic, copy, nullable) GCKMediaQueueData *queueData;

/**
 * The flag to indicate whether playback should start immediately. The default value is
 * <code>@(YES)</code>. If this is @c nil, the @autoplay property of @ref GCKMediaQueueItem in @c
 * queueData will take effect. If queueData is @c nil either, playback will not start immediately.
 */
@property(nonatomic, copy, nullable) NSNumber *autoplay;

/**
 * The initial position to start playback.
 * The default value is @ref kGCKInvalidTimeInterval, which indicates a default playback position.
 * If playing Video-On-Demand streams, it starts from 0; if playing live streams, it starts from
 * live edge.
 */
@property(nonatomic, assign) NSTimeInterval startTime;

/**
 * The playback rate. The default value is <code>1</code>.
 */
@property(nonatomic, assign) float playbackRate;

/**
 * An array of integers specifying the active tracks. The default value is <code>nil</code>.
 */
@property(nonatomic, strong, nullable) NSArray<NSNumber *> *activeTrackIDs;

/**
 * Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 */
@property(nonatomic, strong, nullable) id customData;

/**
 * The user credentials for the media item being loaded.
 */
@property(nonatomic, copy, nullable) NSString *credentials;

/**
 * The type of user credentials specified in #GCKMediaLoadRequestData::credentials.
 */
@property(nonatomic, copy, nullable) NSString *credentialsType;

/**
 * The alternate Android TV credentials for the media item being loaded.
 *
 * If set, these credentials will override the value set in #GCKMediaLoadRequestData::credentials if
 * the receiver is an Android TV app. On the receiver side, these credentials can be accessed from
 * @link MediaLoadRequestData#getCredentials @endlink.
 *
 * @since 4.7.0
 */
@property(nonatomic, copy, nullable) NSString *atvCredentials;

/**
 * The type of Android TV credentials specified in #GCKMediaLoadRequestData::atvCredentials.
 *
 * If set, this credentials type will override the value set in
 * #GCKMediaLoadRequestData::credentialsType if the receiver is an Android TV app. On the receiver
 * side, these credentials can be accessed from @link MediaLoadRequestData#getCredentialsType
 * @endlink.
 *
 * @since 4.7.0
 */
@property(nonatomic, copy, nullable) NSString *atvCredentialsType;

/**
 * Initializes a @c GCKMediaLoadRequestData with default values for all properties.
 */
- (instancetype)init;

/**
 * Initializes a @c GCKMediaLoadRequestData with a given @c GCKMediaLoadRequestData object.
 */
- (instancetype)initWithMediaLoadRequestData:(GCKMediaLoadRequestData *)requestData;

/**
 * Builds a @c GCKMediaLoadRequestData using the builder's current attributes.
 *
 * @return The new @c GCKMediaLoadRequestData instance.
 */
- (GCKMediaLoadRequestData *)build;

@end

NS_ASSUME_NONNULL_END
