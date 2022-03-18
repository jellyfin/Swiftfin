#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaCommon.h>

#import <Foundation/Foundation.h>

@class GCKImage;
@class GCKMediaMetadata;

/**
 * @file GCKMediaQueueContainerMetadata.h
 * GCKMediaQueueContainerType enum.
 */

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKMediaQueueContainerType
 * Enum defining the media queue metadata types.
 *
 * @since 4.4.1
 */
typedef NS_ENUM(NSInteger, GCKMediaQueueContainerType) {
  /**  A media type representing generic media content. */
  GCKMediaQueueContainerTypeGeneric = 0,
  /** A media type representing an audio book. */
  GCKMediaQueueContainerTypeAudioBook = 1,
};

/**
 * Additional metadata for the media queue container.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaQueueContainerMetadata : NSObject <NSCopying, NSSecureCoding>

/**
 * The type of metadata.
 */
@property(nonatomic, readonly) GCKMediaQueueContainerType containerType;

/**
 * The container title. It can be audiobook title, Live TV Channel name, album name or playlist
 * name, etc.
 */
@property(nonatomic, copy, readonly, nullable) NSString *title;

/**
 * The metadata of each sections that a media stream contains.
 */
@property(nonatomic, copy, readonly) NSArray<GCKMediaMetadata *> *sections;

/**
 * The total playback time for the container.
 */
@property(nonatomic, readonly) NSTimeInterval containerDuration;

/**
 * Images associated with the queue. By default the first image is used when displaying queue
 * information. Used for audio book image, a TV Channel logo, album cover, etc.
 */
@property(nonatomic, copy, readonly) NSArray<GCKImage *> *containerImages;

/**
 * The author names. Used for audio book.
 */
@property(nonatomic, copy, readonly) NSArray<NSString *> *authors;

/**
 * The audiobook narrator names. Used for audio book.
 */
@property(nonatomic, copy, readonly) NSArray<NSString *> *narrators;

/**
 * The book publisher. Used for audio book.
 */
@property(nonatomic, copy, readonly) NSString *publisher;

/**
 * The book release date in ISO-8601 format. Used for audio book.
 *
 * @since 4.4.1
 */
@property(nonatomic, copy, readonly) NSString *releaseDate;

- (instancetype)init NS_UNAVAILABLE;

@end  // GCKMediaQueueContainerMetadata

/**
 * A builder object for constructing new or derived @c GCKMediaQueueContainerMetadata instances. The
 * builder may be used to derive @c GCKMediaQueueContainerMetadata from an existing one.
 *
 * @since 4.4.1
 */
GCK_EXPORT
@interface GCKMediaQueueContainerMetadataBuilder : NSObject

/**
 * The type of metadata.
 */
@property(nonatomic) GCKMediaQueueContainerType containerType;

/**
 * The container title. It can be audiobook title, Live TV Channel name, album name or playlist
 * name, etc.
 */
@property(nonatomic, copy, nullable) NSString *title;

/**
 * The metadata of each sections that a media stream contains.
 */
@property(nonatomic, copy) NSArray<GCKMediaMetadata *> *sections;

/**
 * The total playback time for the container.
 */
@property(nonatomic) NSTimeInterval containerDuration;

/**
 * Images associated with the queue. By default the first image is used when displaying queue
 * information. Used for audio book image, a TV Channel logo, album cover, etc.
 */
@property(nonatomic, copy) NSArray<GCKImage *> *containerImages;

/**
 * The author names. Used for audio book.
 */
@property(nonatomic, copy) NSArray<NSString *> *authors;

/**
 * The audiobook narrator names. Used for audio book.
 */
@property(nonatomic, copy) NSArray<NSString *> *narrators;

/**
 * The book publisher. Used for audio book.
 */
@property(nonatomic, copy) NSString *publisher;

/**
 * The book release date in ISO-8601 format. Used for audio book.
 */
@property(nonatomic, copy) NSString *releaseDate;

/**
 * Constructs a new @c GCKMediaQueueContainerMetadata with the given required attributes, and all
 * other attributes initialized to default values.
 */
- (instancetype)initWithContainerType:(GCKMediaQueueContainerType)containerType;

/**
 * Constructs a new @c GCKMediaQueueContainerMetadata with the given @c
 * GCKMediaQueueContainerMetadata instance.
 */
- (instancetype)initWithContainerMetadata:(GCKMediaQueueContainerMetadata *)containerMetadata;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Builds a @c GCKMediaQueueContainerMetadata using the builder's current attributes.
 *
 * @return The new @c GCKMediaQueueContainerMetadata instance.
 */
- (GCKMediaQueueContainerMetadata *)build;

@end

NS_ASSUME_NONNULL_END
