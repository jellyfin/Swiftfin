#import <Foundation/Foundation.h>

#import <GoogleCast/GCKDefines.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * A class representing a VAST request for an ad break clip.
 *
 * @since 4.1
 */
GCK_EXPORT
@interface GCKVASTAdsRequest : NSObject <NSCopying, NSSecureCoding>

/**
 * A URL for the VAST file.
 *
 * @since 4.1
 */
@property(nonatomic, readonly, nullable) NSURL *adTagUrl;

/**
 * A string specifying a VAST document to be used as the ads response
 * instead of making a request via an ad tag url. This can be useful for
 * debugging and other situations where a VAST response is already
 * available. If the adsResponse is non-nil, the adTagURL will be ignored by the receiver.
 *
 * @since 4.1
 */
@property(nonatomic, readonly, nullable) NSString *adsResponse;

/**
 * Initializes a GCKVASTAdsRequest object. Needs an adTagURL or an adsResponse.
 * @param adTagURL The ad tag URL for the request.
 * @param adsResponse The ads response for the request. If this is non-nil, adTagURL will be
 * ignored by the receiver.
 *
 * @since 4.3.4
 */
- (nullable instancetype)initWithAdTagURL:(nullable NSURL *)adTagURL
                              adsResponse:(nullable NSString *)adsResponse
    NS_DESIGNATED_INITIALIZER;

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
