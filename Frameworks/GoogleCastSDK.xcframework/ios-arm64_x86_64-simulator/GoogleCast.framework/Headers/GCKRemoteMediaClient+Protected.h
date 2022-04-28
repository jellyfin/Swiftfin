// Copyright 2015 Google Inc.

#import <GoogleCast/GCKRemoteMediaClient.h>

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * Methods to be called by GCKRemoteMediaClient subclasses only.
 *
 * @since 3.3
 */
@interface GCKRemoteMediaClient (Protected)

/**
 * To be called by subclasses whenever a media session begins, namely, right after new media has
 * been successfully loaded on the remote player.
 */
- (void)notifyDidStartMediaSession;

/**
 * To be called by subclasses whenever the mediaStatus object of the client changes.
 */
- (void)notifyDidUpdateMediaStatus;

/**
 * To be called by subclasses whenever the media queue managed by the client changes.
 */
- (void)notifyDidUpdateQueue;

/**
 * To be called by subclasses whenever the @ref GCKMediaStatus::preloadedItemID of the client's
 * GCKMediaStatus changes.
 */
- (void)notifyDidUpdatePreloadStatus;

/**
 * To be called by subclasses whenever the metadata changes.
 */
- (void)notifyDidUpdateMetadata;

/**
 * To be called by subclasses whenever the list of media queue item IDs is received.
 *
 * @param itemIDs The list of queue item IDs.
 *
 * @since 4.1
 */
- (void)notifyDidReceiveQueueItemIDs:(NSArray<NSNumber *> *)itemIDs;

/**
 * To be called by subclasses whenever a contiguous sequence of queue items has been inserted
 * into the queue.
 *
 * @param itemIDs The list of queue item IDs identifying the items that were inserted.
 * @param beforeItemID The ID of the queue item in front of which the new items were inserted, or
 * kGCKInvalidQueueItemID if the items were appended to the end of the queue.
 *
 * @since 4.1
 */
- (void)notifyDidInsertQueueItemsWithIDs:(NSArray<NSNumber *> *)itemIDs
                        beforeItemWithID:(GCKMediaQueueItemID)beforeItemID;

/**
 * To be called by subclasses whenever existing queue items have been updated in the queue.
 *
 * @param itemIDs The list of queue item IDs identifying the items that were updated.
 *
 * @since 4.1
 */
- (void)notifyDidUpdateQueueItemsWithIDs:(NSArray<NSNumber *> *)itemIDs;

/**
 * To be called by subclasses whenever a contiguous sequence of queue items has been removed
 * from the queue.
 *
 * @param itemIDs The list of queue item IDs identifying the items that were removed.
 *
 * @since 4.1
 */
- (void)notifyDidRemoveQueueItemsWithIDs:(NSArray<NSNumber *> *)itemIDs;

/**
 * To be called by a subclass whenever queue items have been received.
 *
 * @param items The list of queue items.
 *
 * @since 4.1
 */
- (void)notifyDidReceiveQueueItems:(NSArray<GCKMediaQueueItem *> *)items;

@end

NS_ASSUME_NONNULL_END
