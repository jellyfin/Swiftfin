// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaCommon.h>

#import <Foundation/Foundation.h>

/**
 * @file GCKMediaQueueItem.h
 */

@class GCKMediaInformation;
@class GCKMediaQueueItemBuilder;

/**
 * A media queue item ID.
 *
 * @since 4.1
 */
typedef NSUInteger GCKMediaQueueItemID;

NS_ASSUME_NONNULL_BEGIN

/**
 * @var kGCKMediaQueueInvalidItemID
 * An invalid queue item ID.
 */
GCK_EXTERN const GCKMediaQueueItemID kGCKMediaQueueInvalidItemID;

/**
 * A class representing a media queue item. Instances of this object are immutable.
 *
 * This class is used in two-way communication between a sender application and a receiver
 * application. The sender constructs them to load or insert a list of media items on the receiver
 * application. The @ref GCKMediaStatus from the receiver also contains the list of items
 * represented as instances of this class.
 *
 * Once loaded, the receiver will assign a unique item ID to each GCKMediaQueueItem, even if the
 * same media gets loaded multiple times.
 */
GCK_EXPORT
@interface GCKMediaQueueItem : NSObject <NSCopying>

/** The media information associated with this item. */
@property(nonatomic, strong, readonly) GCKMediaInformation *mediaInformation;

/** The item ID, or @ref kGCKMediaQueueInvalidItemID if one has not yet been assigned. */
@property(nonatomic, assign, readonly) GCKMediaQueueItemID itemID;

/**
 * Whether the item should automatically start playback when it becomes the current item in the
 * queue. If <code>NO</code>, the queue will pause when it reaches this item. The default value is
 * <code>YES</code>.
 * When using this item to load a media queue in @ref GCKMediaLoadRequestData, this property in the
 * first item only takes effect if @c autoplay in @ref GCKMediaLoadRequestData is nil.
 */
@property(nonatomic, assign, readonly) BOOL autoplay;

/**
 * The start time of the item, in seconds. The default value is @ref kGCKInvalidTimeInterval,
 * indicating that no start time has been set.
 */
@property(nonatomic, assign, readonly) NSTimeInterval startTime;

/**
 * The playback duration for the item, in seconds, or <code>INFINITY</code> if the stream's actual
 * duration should be used.
 */
@property(nonatomic, assign, readonly) NSTimeInterval playbackDuration;

/**
 * How long before the previous item ends, in seconds, before the receiver should start
 * preloading this item. The default value is @ref kGCKInvalidTimeInterval, indicating that no
 * preload time has been set.
 */
@property(nonatomic, assign, readonly) NSTimeInterval preloadTime;

/** The active track IDs for this item. */
@property(nonatomic, strong, readonly) NSArray<NSNumber *> *activeTrackIDs;

/** The custom data associated with this item, if any. */
@property(nonatomic, strong, readonly) id customData;

/**
 * Constructs a new GCKMediaQueueItem with the given attributes. See the documentation of the
 * corresponding properties for more information.
 *
 * @param mediaInformation The media information for the item.
 * @param autoplay The autoplay state for this item.
 * @param startTime The start time of the item, in seconds. May be
 * @ref kGCKInvalidTimeInterval if this item refers to a live stream or if the default start time
 * should be used.
 * @param preloadTime The preload time for the item, in seconds. May be @ref kGCKInvalidTimeInterval
 * to indicate no preload time.
 * @param activeTrackIDs The active track IDs for the item. May be <code>nil</code>.
 * @param customData Any custom data to associate with the item. May be <code>nil</code>.
 */
- (instancetype)initWithMediaInformation:(GCKMediaInformation *)mediaInformation
                                autoplay:(BOOL)autoplay
                               startTime:(NSTimeInterval)startTime
                             preloadTime:(NSTimeInterval)preloadTime
                          activeTrackIDs:(nullable NSArray<NSNumber *> *)activeTrackIDs
                              customData:(nullable id)customData;

/**
 * Designated initializer. Constructs a new GCKMediaQueueItem with the given attributes. See the
 * documentation of the corresponding properties for more information.
 *
 * @param mediaInformation The media information for the item.
 * @param autoplay The autoplay state for this item.
 * @param startTime The start time of the item, in seconds. May be @ref kGCKInvalidTimeInterval if
 * this item refers to a live stream or if the default start time should be used.
 * @param playbackDuration The playback duration of the item, in seconds. May be
 * @ref kGCKInvalidTimeInterval to indicate no preload time.
 * @param preloadTime The preload time for the item, in seconds.
 * @param activeTrackIDs The active track IDs for the item. May be <code>nil</code>.
 * @param customData Any custom data to associate with the item. May be <code>nil</code>.
 */
- (instancetype)initWithMediaInformation:(GCKMediaInformation *)mediaInformation
                                autoplay:(BOOL)autoplay
                               startTime:(NSTimeInterval)startTime
                        playbackDuration:(NSTimeInterval)playbackDuration
                             preloadTime:(NSTimeInterval)preloadTime
                          activeTrackIDs:(nullable NSArray<NSNumber *> *)activeTrackIDs
                              customData:(nullable id)customData
    /*NS_DESIGNATED_INITIALIZER*/;

/**
 * Clears (unassigns) the item ID. Should be called in order to reuse an existing instance, for
 * example, to add it back to a queue.
 */
- (void)clearItemID;

/**
 * Returns a copy of this GCKMediaQueueItem that has been modified by the given block.
 *
 * @param block A block that receives a GCKMediaQueueItemBuilder which can be used to modify
 * attributes of the copy. It is not necessary to call the builder's GCKMediaQueueItemBuilder::build
 * method within the block, as this method will do that automatically when the block completes.
 * @return A modified copy of this item.
 */
- (instancetype)mediaQueueItemModifiedWithBlock:(void (^)(GCKMediaQueueItemBuilder *builder))block;

@end

/**
 * A builder object for constructing new or derived GCKMediaQueueItem instances. The builder may be
 * used to derive a GCKMediaQueueItem from an existing one:
 *
 * @code
 * GCKMediaQueueItemBuilder *builder =
 *     [[GCKMediaQueueItemBuilder alloc] initWithMediaQueueItem:originalItem];
 * builder.startTime = 10; // Change the start time.
 * builder.autoplay = NO; // Change the autoplay flag.
 * GCKMediaQueueItem *derivedItem = [builder build];
 * @endcode
 *
 * It can also be used to construct a new GCKMediaQueueItem from scratch:
 *
 * @code
 * GCKMediaQueueItemBuilder *builder = [[GCKMediaQueueItemBuilder alloc] init];
 * builder.mediaInformation = ...;
 * builder.autoplay = ...;
 * // Set all other desired propreties...
 * GCKMediaQueueItem *newItem = [builder build];
 * @endcode
 */
GCK_EXPORT
@interface GCKMediaQueueItemBuilder : NSObject

/** The media information associated with this item. */
@property(nonatomic, copy, nullable) GCKMediaInformation *mediaInformation;

/**
 * Whether the item should automatically start playback when it becomes the current item in the
 * queue. If <code>NO</code>, the queue will pause when it reaches this item. The default value is
 * <code>YES</code>.
 */
@property(nonatomic, assign) BOOL autoplay;

/**
 * The start time of the item, in seconds. The default value is @ref kGCKInvalidTimeInterval,
 * indicating that a start time does not apply (for example, for a live stream) or that the default
 * start time should be used.
 */
@property(nonatomic, assign) NSTimeInterval startTime;

/**
 * The playback duration for the item, in seconds, or <code>INFINITY</code> if the stream's actual
 * duration should be used.
 */
@property(nonatomic, assign) NSTimeInterval playbackDuration;

/**
 * How long before the previous item ends, in seconds, before the receiver should start preloading
 * this item. The default value is @ref kGCKInvalidTimeInterval, indicating no preload time.
 */
@property(nonatomic, assign) NSTimeInterval preloadTime;

/** The active track IDs for this item. */
@property(nonatomic, copy, nullable) NSArray<NSNumber *> *activeTrackIDs;

/** The custom data associated with this item, if any. */
@property(nonatomic, copy, nullable) id customData;

/**
 * Constructs a new GCKMediaQueueItemBuilder with attributes initialized to default values.
 */
- (instancetype)init;

/**
 * Constructs a new GCKMediaQueueItemBuilder with attributes copied from the given
 * GCKMediaQueueItem, including the item ID.
 *
 * @param item The item to copy.
 */
- (instancetype)initWithMediaQueueItem:(nullable GCKMediaQueueItem *)item;

/**
 * Builds a GCKMediaQueueItem using the builder's current attributes.
 */
- (GCKMediaQueueItem *)build;

@end

NS_ASSUME_NONNULL_END
