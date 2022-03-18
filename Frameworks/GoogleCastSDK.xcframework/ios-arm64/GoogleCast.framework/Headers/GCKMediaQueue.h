#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaQueueItem.h>

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol GCKMediaQueueDelegate;
@class GCKRemoteMediaClient;
/**
 * A data model representation of a media queue of arbitrary length. This class can be used as the
 * basis for an implementation of a UITableViewDataSource for driving a media queue UI.
 *
 * GCKMediaQueue listens for GCKSessionManager events and automatically attaches itself to the
 * GCKRemoteMediaClient when a Cast session is started. It listens for queue change notifications
 * from the GCKRemoteMediaClient and updates its internal data model accordingly. Likewise, it uses
 * the GCKRemoteMediaClient to fetch queue information on demand.
 *
 * The model maintains a list of queue item IDs for the entire queue; it automatically fetches this
 * list whenever it attaches to a Cast session. It also maintains an LRU cache (of configurable
 * size) of GCKMediaQueueItems, keyed by the queue item ID.
 *
 * The method GCKMediaQueue::itemAtIndex: is used to fetch a queue item at a given index. If the
 * GCKMediaQueueItem is not currently in the cache, an asynchronous request is made to fetch that
 * item from the receiver, and the delegate is eventually notified when the requested items are
 * received.
 *
 * If multiple calls to this method are made in a very short amount of time, the requested item IDs
 * are batched internally to reduce the number of network requests made. Because there is an upper
 * limit to how many queue items can be fetched from the receiver at a time, GCKMediaQueue keeps a
 * rolling window of the last N item IDs to be fetched. Therefore if a very large number of items
 * is requested in a short amount of time, only the last N items will actually be fetched. This
 * behavior allows for the efficient management of a very long queue in the app's UI which may be
 * quickly and/or frequently scrolled through by a user.
 *
 * GCKMediaQueue does not provide any methods for directly modifying the queue, because any such
 * change involves an asynchronous network request to the receiver (via methods on
 * GCKRemoteMediaClient), which can potentially fail with an error. GCKMediaQueue must ensure a
 * consistent representation of the queue as it exists on the receiver, so making local changes to
 * the data model which are not yet committed on the receiver could result in incorrect UI
 * behavior.
 *
 * See GCKMediaQueueDelegate for the delegate protocol.
 *
 * @since 4.3.4
 */
GCK_EXPORT
@interface GCKMediaQueue : NSObject

/** The number of items currently in the queue. */
@property(nonatomic, assign, readonly) NSUInteger itemCount;
/** The cache size. */
@property(nonatomic, assign, readonly) NSUInteger cacheSize;
/** The number of queue items that are currently in the cache. */
@property(nonatomic, assign, readonly) NSUInteger cachedItemCount;

- (instancetype)init NS_UNAVAILABLE;

/** Initializes a new GCKMediaQueue with the default cache size and default max fetch count. */
- (instancetype)initWithRemoteMediaClient:(GCKRemoteMediaClient *)remoteMediaClient;

/**
 * Initializes a new GCKMediaQueue with the given cache size and default max fetch count.
 *
 * @param cacheSize The cache size. Must be nonzero.
 */
- (instancetype)initWithRemoteMediaClient:(GCKRemoteMediaClient *)remoteMediaClient
                                cacheSize:(NSUInteger)cacheSize;

/**
 * Initializes a new GCKMediaQueue with the given cache size and given max fetch count.
 *
 * @param cacheSize The cache size. Must be nonzero.
 * @param maxFetchCount The maxiumum fetch count with minimum being 1.
 */

- (instancetype)initWithRemoteMediaClient:(GCKRemoteMediaClient *)remoteMediaClient
                                cacheSize:(NSUInteger)cacheSize
                            maxFetchCount:(NSUInteger)maxFetchCount NS_DESIGNATED_INITIALIZER;

/**
 * Adds a delegate to this object's list of delegates.
 *
 * @param delegate The delegate to add. The delegate will be retained until @ref removeDelegate: is
 *     called.
 */
- (void)addDelegate:(id<GCKMediaQueueDelegate>)delegate;

/**
 * Removes a delegate from this object's list of delegates.
 *
 * @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<GCKMediaQueueDelegate>)delegate;

/**
 * Returns the media queue item at the given index in the queue, or arranges to have the item
 * fetched from the receiver if it is not currently in the cache.
 *
 * @param index The index of the item to fetch.
 * @return The item at the given index, or <code>nil</code> if the item is not currently in the
 * cache, but will be fetched asynchronously.
 */
- (nullable GCKMediaQueueItem *)itemAtIndex:(NSUInteger)index;

/**
 * Returns the media queue item at the given index in the queue, or optionally arranges to have the
 * item fetched from the receiver if it is not currently in the cache.
 *
 * @param index The index of the item to fetch.
 * @param fetch Whether the item should be fetched from the receiver if it is not currently in the
 * cache.
 * @return The item at the given index, or <code>nil</code> if the item is not currently in the
 * cache.
 */
- (nullable GCKMediaQueueItem *)itemAtIndex:(NSUInteger)index fetchIfNeeded:(BOOL)fetch;

/**
 * Returns the item ID of the item at the given index in the queue.
 *
 * @return The item ID at the given index, or kGCKMediaQueueInvalidItemID if the index is invalid.
 */
- (GCKMediaQueueItemID)itemIDAtIndex:(NSUInteger)index;

/**
 * Looks up the index of a queue item in the queue.
 *
 * @param itemID The queue item ID.
 * @return The index (that is, the cardinal position) of the item within the queue, or NSNotFound
 * if there is no such item in the queue.
 */
- (NSInteger)indexOfItemWithID:(GCKMediaQueueItemID)itemID;

/**
 * Reloads the queue. The cache will be flushed and the item ID list will be re-fetched from the
 * receiver.
 */
- (void)reload;

/**
 * Clears the queue, removing all elements and flushing the cache.
 */
- (void)clear;

@end

/**
 * The delegate protocol for receiving asynchronous notifications from a GCKMediaQueue.
 *
 * @since 4.3.4
 */
GCK_EXPORT
@protocol GCKMediaQueueDelegate <NSObject>

@optional

/**
 * Called when one or more changes are about to be made to the queue.
 *
 * @param queue The queue.
 */
- (void)mediaQueueWillChange:(GCKMediaQueue *)queue;

/**
 * Called when the queue has been entirely reloaded. Any previously accessed queue items should be
 * considered invalid.
 *
 * @param queue The queue.
 */
- (void)mediaQueueDidReloadItems:(GCKMediaQueue *)queue;

/**
 * Called when a contiguous range of queue items ahve been inserted into the queue.
 *
 * @param queue The queue.
 * @param range The range indicating the starting index and count of items inserted.
 */
- (void)mediaQueue:(GCKMediaQueue *)queue didInsertItemsInRange:(NSRange)range;

/**
 * Called when one or more queue items have been updated in the queue. This includes the case where
 * previously accessed but unavailable items have been retrieved and placed in the cache, and the
 * case where previously cached items have been flushed from the cache.
 *
 * @param queue The queue.
 * @param indexes The ordered list of indexes of the items that have been updated.
 */
- (void)mediaQueue:(GCKMediaQueue *)queue didUpdateItemsAtIndexes:(NSArray<NSNumber *> *)indexes;

/**
 * Called when one or more queue items have been removed from the queue.
 *
 * @param queue The queue.
 * @param indexes The ordered list of indexes of the items that have been removed.
 */
- (void)mediaQueue:(GCKMediaQueue *)queue didRemoveItemsAtIndexes:(NSArray<NSNumber *> *)indexes;

/**
 * Called after one or more queue changes have been made to the queue.
 */
- (void)mediaQueueDidChange:(GCKMediaQueue *)queue;

@end

NS_ASSUME_NONNULL_END
