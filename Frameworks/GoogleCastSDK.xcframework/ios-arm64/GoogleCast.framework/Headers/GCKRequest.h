// Copyright 2015 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <Foundation/Foundation.h>

@class GCKError;
@protocol GCKRequestDelegate;

typedef NSInteger GCKRequestID;

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKRequestAbortReason
 * Enum defining the reasons that could cause a request to be aborted.
 *
 * @since 3.0
 */
typedef NS_ENUM(NSInteger, GCKRequestAbortReason) {
  /** The request was aborted because a similar and overridding request was initiated. */
  GCKRequestAbortReasonReplaced = 1,
  /** The request was aborted after a call to @ref cancel on this request */
  GCKRequestAbortReasonCancelled = 2,
};

/**
 * An object for tracking an asynchronous request.
 *
 * See GCKRequestDelegate for the delegate protocol.
 *
 * @since 3.0
*/
GCK_EXPORT
@interface GCKRequest : NSObject

/**
 * The delegate for receiving notifications about the status of the request.
 */
@property(nonatomic, weak, nullable) id<GCKRequestDelegate> delegate;

/**
 * The unique ID assigned to this request.
 */
@property(nonatomic, assign, readonly) GCKRequestID requestID;

/**
 * The error that caused the request to fail, if any, otherwise <code>nil</code>.
 */
@property(nonatomic, copy, readonly, nullable) GCKError *error;

/**
 * A flag indicating whether the request is currently in progress.
 */
@property(nonatomic, assign, readonly) BOOL inProgress;

/**
 * A flag indicating whether this is an external request--that is, one created by the application
 * rather than by the framework itself.
 *
 * @since 3.4
 */
@property(nonatomic, assign, readonly) BOOL external;

/**
 * Cancels the request. Canceling a request does not guarantee that the request will not complete
 * on the receiver; it simply causes the sender to stop tracking the request.
 */
- (void)cancel;

/**
 * Constructs a GCKRequest object for use by the calling application. Request objects created using
 * this factory method can be managed by the application using the methods GCKRequest::complete,
 * GCKRequest::failWithError:, and GCKRequest::abortWithReason:.
 *
 * @since 3.4
 */
+ (GCKRequest *)applicationRequest;

/**
 * Completes the request and notifies the delegate accordingly. This method may only be called on
 * GCKRequest objects that have been constructed by the application using the
 * GCKRequest::applicationRequest factory method. Calling this method on a GCKRequest object that
 * was created by the framework itself will raise an exception.
 *
 * @since 3.4
 */
- (void)complete;

/**
 * Fails the request with an error and notifies the delegate accordingly. This method may only be
 * called on GCKRequest objects that have been constructed by the application using the
 * GCKRequest::requestWithID: factory method. Calling this method on a GCKRequest object that was
 * created by the framework itself will raise an exception.
 *
 * @param error The error describing the failure.
 *
 * @since 3.4
 */
- (void)failWithError:(GCKError *)error;

/**
 * Aborts the request with a reason and notifies the delegate accordingly. This method may only be
 * called on GCKRequest objects that have been constructed by the application using the
 * GCKRequest::requestWithID: factory method. Calling this method on a GCKRequest object that was
 * created by the framework itself will raise an exception.
 *
 * @param reason The reason for the abort.
 *
 * @since 3.4
 */
- (void)abortWithReason:(GCKRequestAbortReason)reason;

@end

/**
 * The GCKRequest delegate protocol.
 *
 * @since 3.0
 */
GCK_EXPORT
@protocol GCKRequestDelegate <NSObject>

@optional

/**
 * Called when the request has successfully completed.
 *
 * @param request The request.
 */
- (void)requestDidComplete:(GCKRequest *)request;

/**
 * Called when the request has failed.
 *
 * @param request The request.
 * @param error The error describing the failure.
 */
- (void)request:(GCKRequest *)request didFailWithError:(GCKError *)error;

/**
 * Called when the request is no longer being tracked. It does not guarantee that the request has
 * succeed or failed.
 *
 * @param request The request.
 * @param abortReason The reason why the request is no longer being tracked.
 */
- (void)request:(GCKRequest *)request didAbortWithReason:(GCKRequestAbortReason)abortReason;

@end

NS_ASSUME_NONNULL_END
