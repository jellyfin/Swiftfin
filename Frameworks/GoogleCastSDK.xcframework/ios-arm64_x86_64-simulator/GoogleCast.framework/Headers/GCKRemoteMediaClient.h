// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>
#import <GoogleCast/GCKMediaCommon.h>
#import <GoogleCast/GCKMediaInformation.h>
#import <GoogleCast/GCKMediaMetadata.h>
#import <GoogleCast/GCKMediaQueue.h>
#import <GoogleCast/GCKMediaQueueItem.h>
#import <GoogleCast/GCKMediaStatus.h>
#import <GoogleCast/GCKRequest.h>

#import <Foundation/Foundation.h>

@class GCKMediaLoadOptions;
@class GCKMediaLoadRequestData;
@class GCKMediaQueueLoadOptions;
@class GCKMediaSeekOptions;
@protocol GCKRemoteMediaClientListener;
@protocol GCKRemoteMediaClientAdInfoParserDelegate;

NS_ASSUME_NONNULL_BEGIN


/**
 * A class for controlling media playback on a Cast receiver. An instance of this object is
 * available as the property GCKSession::remoteMediaClient.
 *
 * @since 3.0
 */
GCK_EXPORT
@interface GCKRemoteMediaClient : NSObject

/** A flag that indicates whether this object is connected to a session. */
@property(nonatomic, assign, readonly) BOOL connected;

/** The current media status, as reported by the media control channel. */
@property(nonatomic, strong, readonly, nullable) GCKMediaStatus *mediaStatus;

/**
 * The media queue.
 *
 * @since 4.3.4
 */
@property(nonatomic, strong, readonly) GCKMediaQueue *mediaQueue;

/**
 * The amount of time that has passed since the last media status update was received. If a
 * media status has not been received yet this value will be NAN.
 */
@property(nonatomic, assign, readonly) NSTimeInterval timeSinceLastMediaStatusUpdate;

/**
 * A flag that indicates whether this client is playing a live stream.
 *
 * @since 4.4.1
 */
@property(nonatomic, readonly, getter=isPlayingLiveStream) BOOL playingLiveStream;

/**
 * Adds a listener to this object's list of listeners.
 *
 * The added listener is weakly held, and should be retained to avoid unexpected deallocation.
 *
 * @param listener The listener to add.
 */
- (void)addListener:(id<GCKRemoteMediaClientListener>)listener;

/**
 * Removes a listener from this object's list of listeners.
 *
 * @param listener The listener to remove.
 */
- (void)removeListener:(id<GCKRemoteMediaClientListener>)listener;

/**
 * A delegate capable of extracting ad break information from the custom data in a GCKMediaStatus
 * object.
 *
 * @deprecated Use GCKAdBreakStatus instead.
 */
@property(nonatomic, weak) id<GCKRemoteMediaClientAdInfoParserDelegate> adInfoParserDelegate;

/**
 * Loads and starts playback of a media item or a queue of media items with a request data.
 *
 * @param requestData Describes the media load request.
 * @return The GCKRequest object for tracking this request.
 *
 * @since 4.4.1
 */
- (GCKRequest *)loadMediaWithLoadRequestData:(GCKMediaLoadRequestData *)requestData;

/**
 * Loads and starts playback of a new media item with default options.
 *
 * It is recommended to use @ref loadMediaWithLoadRequestData: instead, which is an advanced
 * load command supporting loading a single item or a queue with additional options.
 *
 * @param mediaInfo Describes the media item to load.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo;

/**
 * Loads and starts playback of a new media item with the specified options.
 *
 * It is recommended to use @ref loadMediaWithLoadRequestData:  instead, which is an advanced
 * load command supporting loading a single item or a queue with additional options.
 *
 * @param mediaInfo Describes the media item to load.
 * @param options The load options for this request.
 * @return The GCKRequest object for tracking this request.
 *
 * @since 4.0
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo
              withOptions:(GCKMediaLoadOptions *)options;

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo Describes the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo
                 autoplay:(BOOL)autoplay GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo Describes the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo Describes the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
               customData:(nullable id)customData
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo Describes the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param activeTrackIDs An array of integers specifying the active tracks.
 * May be <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
           activeTrackIDs:(nullable NSArray<NSNumber *> *)activeTrackIDs
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new media item.
 *
 * @param mediaInfo Describes the media item to load.
 * @param autoplay Whether playback should start immediately.
 * @param playPosition The initial playback position.
 * @param activeTrackIDs An array of integers specifying the active tracks.
 * May be <code>nil</code>.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)loadMedia:(GCKMediaInformation *)mediaInfo
                 autoplay:(BOOL)autoplay
             playPosition:(NSTimeInterval)playPosition
           activeTrackIDs:(nullable NSArray<NSNumber *> *)activeTrackIDs
               customData:(nullable id)customData
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Sets the playback rate for the current media session.
 *
 * @param playbackRate The new playback rate.
 * @return The GCKRequest object for tracking this request.
 * @since 4.0
 */
- (GCKRequest *)setPlaybackRate:(float)playbackRate;

/**
 * Sets the playback rate for the current media session.
 *
 * @param playbackRate The new playback rate, which must be between
 * GCKMediaLoadOptions::kGCKMediaMinPlaybackRate and GCKMediaLoadOptions::kGCKMediaMaxPlaybackRate.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @since 4.0
 */
- (GCKRequest *)setPlaybackRate:(float)playbackRate customData:(nullable id)customData;

/**
 * Sets the active tracks. The request will fail if there is no current media status.
 *
 * @param activeTrackIDs An array of integers specifying the active tracks. May be empty or
 * <code>nil</code> to disable any currently active tracks.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)setActiveTrackIDs:(nullable NSArray<NSNumber *> *)activeTrackIDs;

/**
 * Sets the text track style. The request will fail if there is no current media status.
 *
 * @param textTrackStyle The text track style. The style will not be changed if this is
 * <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)setTextTrackStyle:(nullable GCKMediaTextTrackStyle *)textTrackStyle;

/**
 * Pauses playback of the current media item. The request will fail if there is no current media
 * status.
 *
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)pause;

/**
 * Pauses playback of the current media item. The request will fail if there is no current media
 * status.
 *
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)pauseWithCustomData:(nullable id)customData;

/**
 * Stops playback of the current media item. If a queue is currently loaded, it will be removed. The
 * request will fail if there is no current media status.
 *
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)stop;

/**
 * Stops playback of the current media item. If a queue is currently loaded, it will be removed. The
 * request will fail if there is no current media status.
 *
 *
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)stopWithCustomData:(nullable id)customData;

/**
 * Begins (or resumes) playback of the current media item. Playback always begins at the
 * beginning of the stream. The request will fail if there is no current media status.
 *
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)play;

/**
 * Begins (or resumes) playback of the current media item. Playback always begins at the
 * beginning of the stream. The request will fail if there is no current media status.
 *
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)playWithCustomData:(nullable id)customData;

/**
 * Sends a request to skip the playing ad.
 * @return The GCKRequest object for tracking this request.
 *
 * @since 4.3
 */
- (GCKRequest *)skipAd;

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param options The seek options for the request.
 * @return The GCKRequest object for tracking this request.
 * @since 4.0
 */
- (GCKRequest *)seekWithOptions:(GCKMediaSeekOptions *)options;

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param position The new position from the beginning of the stream.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use seekWithOptions:.
 */
- (GCKRequest *)seekToTimeInterval:(NSTimeInterval)position
    GCK_DEPRECATED("Use seekWithOptions:");

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param position The new position interval from the beginning of the stream.
 * @param resumeState The action to take after the seek operation has finished.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use seekWithOptions:.
 */
- (GCKRequest *)seekToTimeInterval:(NSTimeInterval)position
                       resumeState:(GCKMediaResumeState)resumeState
    GCK_DEPRECATED("Use seekWithOptions:");

/**
 * Seeks to a new position within the current media item. The request will fail if there is no
 * current media status.
 *
 * @param position The new position from the beginning of the stream.
 * @param resumeState The action to take after the seek operation has finished.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use seekWithOptions:.
 */
- (GCKRequest *)seekToTimeInterval:(NSTimeInterval)position
                       resumeState:(GCKMediaResumeState)resumeState
                        customData:(nullable id)customData GCK_DEPRECATED("Use seekWithOptions:");

/**
 * Requests the list of item IDs for the queue. The results are passed to the delegate callback
 * GCKRemoteMediaClientDelegate::remoteMediaClient:didReceiveQueueItemIDs:.
 *
 * @return The GCKRequest object for tracking this request.
 *
 * @since 4.1
 */
- (GCKRequest *)queueFetchItemIDs;

/**
 * Requests complete information for the queue items with the given item IDs. The results are
 * passed to the delegate callback
 * GCKRemoteMediaClientDelegate::remoteMediaClient:didReceiveQueueItems:.
 *
 * @return The GCKRequest object for tracking this request.
 *
 * @since 4.1
 */
- (GCKRequest *)queueFetchItemsForIDs:(NSArray<NSNumber *> *)queueItemIDs;

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * @param queueItems An array of GCKMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param startIndex The index of the item in the items array that should be played first.
 * @param repeatMode The repeat mode for playing the queue.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)queueLoadItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                    startIndex:(NSUInteger)startIndex
                    repeatMode:(GCKMediaRepeatMode)repeatMode
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * @param queueItems An array of GCKMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param startIndex The index of the item in the items array that should be played first.
 * @param repeatMode The repeat mode for playing the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)queueLoadItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                    startIndex:(NSUInteger)startIndex
                    repeatMode:(GCKMediaRepeatMode)repeatMode
                    customData:(nullable id)customData
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * @param queueItems An array of GCKMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param startIndex The index of the item in the items array that should be played first.
 * @param playPosition The initial playback position for the item when it is first played,
 * relative to the beginning of the stream. This value is ignored when the same item is played
 * again, for example when the queue repeats, or the item is later jumped to. In those cases the
 * item's startTime is used.
 * @param repeatMode The repeat mode for playing the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 * @deprecated Use loadMediaWithLoadRequestData:.
 */
- (GCKRequest *)queueLoadItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                    startIndex:(NSUInteger)startIndex
                  playPosition:(NSTimeInterval)playPosition
                    repeatMode:(GCKMediaRepeatMode)repeatMode
                    customData:(nullable id)customData
    GCK_DEPRECATED("Use loadMediaWithLoadRequestData:");

/**
 * Loads and optionally starts playback of a new queue of media items.
 *
 * It is recommended to use @ref loadMediaWithLoadRequestData:  instead, which is an advanced
 * load command supporting loading a single item or a queue with additional options.
 *
 * @param queueItems An array of GCKMediaQueueItem instances to load. Must not be <code>nil</code>
 * or empty.
 * @param options The load options used to load the queue items, as defined by
 *   GCKMediaQueueLoadOptions
 *
 * @since 4.3.1
 */
- (GCKRequest *)queueLoadItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                   withOptions:(GCKMediaQueueLoadOptions *)options;

/**
 * Inserts a list of new media items into the queue.
 *
 * @param queueItems An array of GCKMediaQueueItem instances to insert. Must not be <code>nil</code>
 * or empty.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted list.
 * If the value is @ref kGCKMediaQueueInvalidItemID, the inserted list will be appended to the end
 * of the queue.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueInsertItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * Inserts a list of new media items into the queue.
 *
 * @param queueItems An array of GCKMediaQueueItem instances to insert. Must not be <code>nil</code>
 * or empty.
 * @param beforeItemID ID of the item that will be located immediately after the inserted list. If
 * the value is @ref kGCKMediaQueueInvalidItemID, the inserted list will be appended to the end of
 * the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueInsertItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                beforeItemWithID:(NSUInteger)beforeItemID
                      customData:(nullable id)customData;

/**
 * A convenience method that inserts a single item into the queue.
 *
 * @param item The item to insert.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted item.
 * If the value is @ref kGCKMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the inserted item will be appended to the end of the queue.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueInsertItem:(GCKMediaQueueItem *)item beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * A convenience method that inserts a single item into the queue and makes it the current item.
 *
 * @param item The item to insert.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted item.
 * If the value is @ref kGCKMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the inserted item will be appended to the end of the queue.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueInsertAndPlayItem:(GCKMediaQueueItem *)item
                      beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * A convenience method that inserts a single item into the queue and makes it the current item.
 *
 * @param item The item to insert.
 * @param beforeItemID The ID of the item that will be located immediately after the inserted item.
 * If the value is @ref kGCKMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the inserted item will be appended to the end of the queue.
 * @param playPosition The initial playback position for the item when it is first played,
 * relative to the beginning of the stream. This value is ignored when the same item is played
 * again, for example when the queue repeats, or the item is later jumped to. In those cases the
 * item's startTime is used.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueInsertAndPlayItem:(GCKMediaQueueItem *)item
                      beforeItemWithID:(NSUInteger)beforeItemID
                          playPosition:(NSTimeInterval)playPosition
                            customData:(nullable id)customData;

/**
 * Updates the queue.
 *
 * @param queueItems The list of updated items.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueUpdateItems:(NSArray<GCKMediaQueueItem *> *)queueItems;

/**
 * Updates the queue.
 *
 * @param queueItems The list of updated items.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueUpdateItems:(NSArray<GCKMediaQueueItem *> *)queueItems
                      customData:(nullable id)customData;

/**
 * Removes a list of media items from the queue. If the queue becomes empty as a result, the current
 * media session will be terminated.
 *
 * @param itemIDs An array of media item IDs identifying the items to remove. Must not be
 * <code>nil</code> or empty.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueRemoveItemsWithIDs:(NSArray<NSNumber *> *)itemIDs;

/**
 * Removes a list of media items from the queue. If the queue becomes empty as a result, the current
 * media session will be terminated.
 *
 * @param itemIDs An array of media item IDs identifying the items to remove. Must not be
 * <code>nil</code> or empty.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueRemoveItemsWithIDs:(NSArray<NSNumber *> *)itemIDs
                             customData:(nullable id)customData;

/**
 * A convenience method that removes a single item from the queue.
 *
 * @param itemID The ID of the item to remove.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueRemoveItemWithID:(NSUInteger)itemID;

/**
 * Reorders a list of media items in the queue.
 *
 * @param queueItemIDs An array of media item IDs identifying the items to reorder. Must not be
 * <code>nil</code> or empty.
 * @param beforeItemID ID of the item that will be located immediately after the reordered list. If
 * the value is @ref kGCKMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the reordered list will be appended at the end of the queue.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueReorderItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs
                  insertBeforeItemWithID:(NSUInteger)beforeItemID;

/**
 * Reorder a list of media items in the queue.
 *
 * @param queueItemIDs An array of media item IDs identifying the items to reorder. Must not be
 * <code>nil</code> or empty.
 * @param beforeItemID The ID of the item that will be located immediately after the reordered list.
 * If the value is @ref kGCKMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the reordered list will be moved to the end of the queue.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueReorderItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs
                  insertBeforeItemWithID:(NSUInteger)beforeItemID
                              customData:(nullable id)customData;

/**
 * A convenience method that moves a single item in the queue.
 *
 * @param itemID The ID of the item to move.
 * @param beforeItemID The ID of the item that will be located immediately after the reordered list.
 * If the value is @ref kGCKMediaQueueInvalidItemID, or does not refer to any item currently in the
 * queue, the item will be moved to the end of the queue.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueMoveItemWithID:(NSUInteger)itemID beforeItemWithID:(NSUInteger)beforeItemID;

/**
 * Jumps to the item with the specified ID in the queue.
 *
 * @param itemID The ID of the item to jump to.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueJumpToItemWithID:(NSUInteger)itemID;

/**
 * Jumps to the item with the specified ID in the queue.
 *
 * @param itemID The ID of the item to jump to.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueJumpToItemWithID:(NSUInteger)itemID customData:(nullable id)customData;

/**
 * Jumps to the item with the specified ID in the queue.
 *
 * @param itemID The ID of the item to jump to.
 * @param playPosition The initial playback position for the item when it is first played,
 * relative to the beginning of the stream. This value is ignored when the same item is played
 * again, for example when the queue repeats, or the item is later jumped to. In those cases the
 * item's startTime is used.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueJumpToItemWithID:(NSUInteger)itemID
                         playPosition:(NSTimeInterval)playPosition
                           customData:(nullable id)customData;

/**
 * Moves to the next item in the queue.
 *
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueNextItem;

/**
 * Moves to the previous item in the queue.
 *
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queuePreviousItem;

/**
 * Sets the queue repeat mode.
 *
 * @param repeatMode The new repeat mode.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)queueSetRepeatMode:(GCKMediaRepeatMode)repeatMode;

/**
 * Sets the stream volume. The request will fail if there is no current media session.
 *
 * @param volume The new volume, in the range [0.0 - 1.0].
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)setStreamVolume:(float)volume;

/**
 * Sets the stream volume. The request will fail if there is no current media session.
 *
 * @param volume The new volume, in the range [0.0 - 1.0].
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)setStreamVolume:(float)volume customData:(nullable id)customData;

/**
 * Sets whether the stream is muted. The request will fail if there is no current media session.
 *
 * @param muted Whether the stream should be muted or unmuted.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)setStreamMuted:(BOOL)muted;

/**
 * Sets whether the stream is muted. The request will fail if there is no current media session.
 *
 * @param muted Whether the stream should be muted or unmuted.
 * @param customData Custom application-specific data to pass along with the request. Must either be
 * an object that can be serialized to JSON using
 * <a href="https://goo.gl/0vd4Q2"><b>NSJSONSerialization</b></a>, or <code>nil</code>.
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)setStreamMuted:(BOOL)muted customData:(nullable id)customData;

/**
 * Requests updated media status information from the receiver.
 *
 * @return The GCKRequest object for tracking this request.
 */
- (GCKRequest *)requestStatus;

/**
 * Returns the approximate stream position as calculated from the last received stream information
 * and the elapsed wall-time since that update. Returns 0 if the channel is not connected or if no
 * media is currently loaded.
 */
- (NSTimeInterval)approximateStreamPosition;

/**
 * Returns the approximate start position of seekable range as calculated from the last received
 * stream information and the elapsed wall-time since that update. Returns 0 if the channel is not
 * connected or if no media is currently loaded. Returns @c kGCKInvalidTimeInterval if the stream is
 * not live stream or there is no seekable range.
 *
 * @since 4.4.1
 */
- (NSTimeInterval)approximateLiveSeekableRangeStart;

/**
 * Returns the approximate end position of seekable range as calculated from the last received
 * stream information and the elapsed wall-time since that update. Returns 0 if the channel is not
 * connected or if no media is currently loaded. Returns @c kGCKInvalidTimeInterval if the stream is
 * not live stream or there is no seekable range.
 *
 * @since 4.4.1
 */
- (NSTimeInterval)approximateLiveSeekableRangeEnd;

@end  // GCKRemoteMediaClient

/**
 * The GCKRemoteMediaClient listener protocol.
 *
 * @since 3.0
 */
GCK_EXPORT
@protocol GCKRemoteMediaClientListener <NSObject>

@optional

/**
 * Called when a new media session has started on the receiver.
 *
 * @param client The client.
 * @param sessionID The ID of the new session.
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
    didStartMediaSessionWithID:(NSInteger)sessionID;

/**
 * Called when updated media status has been received from the receiver.
 *
 * @param client The client.
 * @param mediaStatus The updated media status. The status can also be accessed as a property of
 * the player.
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
     didUpdateMediaStatus:(nullable GCKMediaStatus *)mediaStatus;

/**
 * Called when updated media metadata has been received from the receiver.
 *
 * @param client The client.
 * @param mediaMetadata The updated media metadata. The metadata can also be accessed through the
 * GCKRemoteMediaClient::mediaStatus property.
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
    didUpdateMediaMetadata:(nullable GCKMediaMetadata *)mediaMetadata;

/**
 * Called when the media playback queue has been updated on the receiver.
 *
 * @param client The client.
 */
- (void)remoteMediaClientDidUpdateQueue:(GCKRemoteMediaClient *)client;

/**
 * Called when the media preload status has been updated on the receiver.
 *
 * @param client The client.
 */
- (void)remoteMediaClientDidUpdatePreloadStatus:(GCKRemoteMediaClient *)client;

/**
 * Called when the list of media queue item IDs has been received.
 *
 * @param client The client.
 * @param queueItemIDs The list of media queue item IDs.
 *
 * @since 4.1
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
    didReceiveQueueItemIDs:(NSArray<NSNumber *> *)queueItemIDs;

/**
 * Called when a contiguous sequence of items has been inserted into the media queue.
 *
 * @param client The client.
 * @param queueItemIDs The item IDs of the inserted items.
 * @param beforeItemID The item ID of the item in front of which the new items have been inserted.
 * If the value is kGCKMediaQueueInvalidItemID, it indicates that the items were appended at the
 * end of the queue.
 *
 * @since 4.1
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
    didInsertQueueItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs
              beforeItemWithID:(GCKMediaQueueItemID)beforeItemID;

/**
 * Called when existing items has been updated in the media queue.
 *
 * @param client The client.
 * @param queueItemIDs The item IDs of the updated items.
 *
 * @since 4.1
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
    didUpdateQueueItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs;

/**
 * Called when a contiguous sequence of items has been removed from the media queue.
 *
 * @param client The client.
 * @param queueItemIDs The item IDs of the removed items.
 *
 * @since 4.1
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
    didRemoveQueueItemsWithIDs:(NSArray<NSNumber *> *)queueItemIDs;

/**
 * Called when detailed information has been received for one or more items in the queue.
 *
 * @param client The client.
 * @param queueItems The queue items.
 *
 * @since 4.1
 */
- (void)remoteMediaClient:(GCKRemoteMediaClient *)client
     didReceiveQueueItems:(NSArray<GCKMediaQueueItem *> *)queueItems;

@end

/**
 * The delegate protocol for parsing ad break information from a media status.
 *
 * @deprecated
 */
@protocol GCKRemoteMediaClientAdInfoParserDelegate <NSObject>
@optional

/**
 * Allows the delegate to determine whether the receiver is playing an ad or not, based on the
 * current media status.
 * @param client The client.
 * @param mediaStatus The current media status.
 * @return YES if the receiver is currently playing an ad, NO otherwise.
 */
- (BOOL)remoteMediaClient:(GCKRemoteMediaClient *)client
    shouldSetPlayingAdInMediaStatus:(GCKMediaStatus *)mediaStatus;

/**
 * Allows the delegate to determine the list of ad breaks in the current content.
 * @param client The client.
 * @param mediaStatus The current media status.
 * @return An array of GCKAdBreakInfo objects representing the ad breaks for this content, or nil
 * if there are no ad breaks.
 */
- (nullable NSArray<GCKAdBreakInfo *> *)remoteMediaClient:(GCKRemoteMediaClient *)client
                           shouldSetAdBreaksInMediaStatus:(GCKMediaStatus *)mediaStatus;

@end // GCKRemoteMediaClientListener

NS_ASSUME_NONNULL_END
