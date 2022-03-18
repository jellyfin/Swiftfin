// Copyright 2014 Google Inc.

#import <GoogleCast/GCKCastChannel.h>
#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@protocol GCKGenericChannelDelegate;

NS_ASSUME_NONNULL_BEGIN

/**
 * A generic GCKCastChannel implementation, suitable for use when subclassing is not desired.
 * GCKGenericChannel forwards message and connectivity events to its delegate, and has no
 * processing logic of its own.
 *
 * See GCKGenericChannelDelegate for the delegate protocol.
 */
GCK_EXPORT
@interface GCKGenericChannel : GCKCastChannel

/**
 * The delegate for receiving notifications about changes in the channel's state.
 */
@property(nonatomic, weak, nullable) id<GCKGenericChannelDelegate> delegate;

/**
 * Designated initializer.
 *
 * @param protocolNamespace The namespace for this channel. This namespace must be unique across
 * all channels used by a given application.
 */
- (instancetype)initWithNamespace:(NSString *)protocolNamespace NS_DESIGNATED_INITIALIZER;

@end

/**
 * The GCKGenericChannel delegate protocol.
 */
GCK_EXPORT
@protocol GCKGenericChannelDelegate <NSObject>

/**
 * Called when a text message has been received on the channel.
 */
- (void)castChannel:(GCKGenericChannel *)channel
    didReceiveTextMessage:(NSString *)message
            withNamespace:(NSString *)protocolNamespace;

@optional

/**
 * Called when the channel has been connected, indicating that messages can now be exchanged with
 * the Cast device over the channel.
 *
 * @param channel The channel.
 */
- (void)castChannelDidConnect:(GCKGenericChannel *)channel;

/**
 * Called when the channel has been disconnected, indicating that messages can no longer be
 * exchanged with the Cast device over the channel.
 *
 * @param channel The channel.
 */
- (void)castChannelDidDisconnect:(GCKGenericChannel *)channel;

/**
 * Called when the writable state of the channel has changed.
 *
 * @param channel The channel.
 * @param writable Whether the channel is now writable.
 * @since 4.0
 */
- (void)castChannel:(GCKCastChannel *)channel didChangeWritableState:(BOOL)writable;

@end

NS_ASSUME_NONNULL_END
