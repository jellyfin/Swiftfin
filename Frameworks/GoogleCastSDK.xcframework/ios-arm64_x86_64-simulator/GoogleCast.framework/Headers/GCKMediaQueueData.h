#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaCommon.h>

#import <Foundation/Foundation.h>

@class GCKImage;
@class GCKMediaQueueItem;
@class GCKMediaMetadata;
@class GCKMediaQueueContainerMetadata;

/**
 * @file GCKMediaQueueData.h
 * GCKMediaQueueType enum.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKMediaQueueType
 * Enum defining the media queue metadata types.
 *
 * @since 4.4.1
 */
typedef NS_ENUM(NSInteger, GCKMediaQueueType) {
  GCKMediaQueueTypeGeneric = 0,
  /** A media type representing an album. */
  GCKMediaQueueTypeAlbum = 1,
  /** A media type representing an audio playlist. */
  GCKMediaQueueTypePlaylist = 2,
  /** A media type representing an audio book. */
  GCKMediaQueueTypeAudioBook = 3,
  /** A media type representing a radio station. */
  GCKMediaQueueTypeRadioStation = 4,
  /** A media type representing a podcast series. */
  GCKMediaQueueTypePodcastSeries = 5,
  /** A media type representing a TV series. */
  GCKMediaQueueTypeTVSeries = 6,
  /** A media type representing a video playlist. */
  GCKMediaQueueTypeVideoPlayList = 7,
  /** A media type representing a live TV. */
  GCKMediaQueueTypeLiveTV = 8,
  /** A media type representing a movie. */
  GCKMediaQueueTypeMovie = 9,
};

/**
 * A class that holds the information of the playing queue or media container.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaQueueData : NSObject <NSCopying, NSSecureCoding>

/**
 * The queue type.
 */
@property(nonatomic, readonly) GCKMediaQueueType queueType;

/**
 * The queue id.
 */
@property(nonatomic, copy, readonly, nullable) NSString *queueID;

/**
 * The display name for queue.
 */
@property(nonatomic, copy, readonly, nullable) NSString *name;

/**
 * The deep link for the media as used by Google Assistant, if any.
 */
@property(nonatomic, copy, readonly, nullable) NSString *entity;

/**
 * The repeat mode of queue.
 */
@property(nonatomic, readonly) GCKMediaRepeatMode repeatMode;

/**
 * The container metadata.
 */
@property(nonatomic, copy, readonly, nullable) GCKMediaQueueContainerMetadata *containerMetadata;

/**
 * The index of the item to start playing with. Only for load request.
 */
@property(nonatomic, readonly) NSUInteger startIndex;

/**
 * The playback start time, in seconds. Only for load request.
 */
@property(nonatomic, readonly) NSTimeInterval startTime;

/**
 * The queueItems. Only for load requests.
 */
@property(nonatomic, copy, readonly, nullable) NSArray<GCKMediaQueueItem *> *items;

- (instancetype)init NS_UNAVAILABLE;

@end  // GCKMediaQueueData

/**
 * A builder object for constructing new or derived @c GCKMediaQueueData instances. The builder may
 * be used to derive @c GCKMediaQueueData from an existing one.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaQueueDataBuilder : NSObject

/**
 * The queue type.
 */
@property(nonatomic) GCKMediaQueueType queueType;

/**
 * The queue id.
 */
@property(nonatomic, copy, nullable) NSString *queueID;

/**
 * The display name for queue.
 */
@property(nonatomic, copy, nullable) NSString *name;

/**
 * The deep link for the media as used by Google Assistant, if any.
 */
@property(nonatomic, copy, nullable) NSString *entity;

/**
 * The repeat mode of queue.
 */
@property(nonatomic) GCKMediaRepeatMode repeatMode;

/**
 * The container metadata.
 */
@property(nonatomic, copy, nullable) GCKMediaQueueContainerMetadata *containerMetadata;

/**
 * The index of the item to start playing with. Only for load request.
 */
@property(nonatomic) NSUInteger startIndex;

/**
 * The playback start time, in seconds. Only for load request.
 * If not set, the receiver will set the start time depending on the stream type.
 * For non-live streams: loaded from 0.
 * For live streams: loaded from the most recent position.
 */
@property(nonatomic) NSTimeInterval startTime;

/**
 * The queueItems. Only for load requests.
 */
@property(nonatomic, copy, nullable) NSArray<GCKMediaQueueItem *> *items;

/**
 * Constructs a new @c GCKMediaQueueData with the given required attributes, and all other
 * attributes initialized to default values.
 */
- (instancetype)initWithQueueType:(GCKMediaQueueType)queueType;

/**
 * Constructs a new @c GCKMediaQueueData with the given @c GCKMediaQueueData instance.
 */
- (instancetype)initWithQueueData:(GCKMediaQueueData *)queueData;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Builds a @c GCKMediaQueueData using the builder's current attributes.
 *
 * @return The new @c GCKMediaQueueData instance.
 */
- (GCKMediaQueueData *)build;

@end  // GCKMediaQueueDataBuilder

NS_ASSUME_NONNULL_END
