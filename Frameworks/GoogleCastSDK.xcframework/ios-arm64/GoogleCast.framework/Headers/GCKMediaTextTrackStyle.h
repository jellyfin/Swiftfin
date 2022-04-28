// Copyright 2014 Google Inc.

#import <GoogleCast/GCKDefines.h>

#import <CoreGraphics/CoreGraphics.h>
#import <Foundation/Foundation.h>

@class GCKColor;

NS_ASSUME_NONNULL_BEGIN

/**
 * @enum GCKMediaTextTrackStyleEdgeType
 * Closed caption text edge types (font effects).
 */
typedef NS_ENUM(NSInteger, GCKMediaTextTrackStyleEdgeType) {
  /** Unknown edge type. */
  GCKMediaTextTrackStyleEdgeTypeUnknown = -1,
  /** None. */
  GCKMediaTextTrackStyleEdgeTypeNone = 0,
  /** Outline. */
  GCKMediaTextTrackStyleEdgeTypeOutline = 1,
  /** Drop shadow. */
  GCKMediaTextTrackStyleEdgeTypeDropShadow = 2,
  /** Raised. */
  GCKMediaTextTrackStyleEdgeTypeRaised = 3,
  /** Depressed. */
  GCKMediaTextTrackStyleEdgeTypeDepressed = 4,
};

/**
 * @enum GCKMediaTextTrackStyleWindowType
 * Closed caption window types.
 */
typedef NS_ENUM(NSInteger, GCKMediaTextTrackStyleWindowType) {
  /** Unknown window type. */
  GCKMediaTextTrackStyleWindowTypeUnknown = -1,
  /** None. */
  GCKMediaTextTrackStyleWindowTypeNone = 0,
  /** Normal. */
  GCKMediaTextTrackStyleWindowTypeNormal = 1,
  /** Rounded corners. */
  GCKMediaTextTrackStyleWindowTypeRoundedCorners = 2,
};

/**
 * @enum GCKMediaTextTrackStyleFontGenericFamily
 * Closed caption text generic font families.
 */
typedef NS_ENUM(NSInteger, GCKMediaTextTrackStyleFontGenericFamily) {
  /** Unknown font family. */
  GCKMediaTextTrackStyleFontGenericFamilyUnknown = -1,
  /** None. */
  GCKMediaTextTrackStyleFontGenericFamilyNone = 0,
  /** Sans serif. */
  GCKMediaTextTrackStyleFontGenericFamilySansSerif = 1,
  /** Monospaced sans serif. */
  GCKMediaTextTrackStyleFontGenericFamilyMonospacedSansSerif = 2,
  /** Serif. */
  GCKMediaTextTrackStyleFontGenericFamilySerif = 3,
  /** Monospaced serif. */
  GCKMediaTextTrackStyleFontGenericFamilyMonospacedSerif = 4,
  /** Casual. */
  GCKMediaTextTrackStyleFontGenericFamilyCasual = 5,
  /** Cursive. */
  GCKMediaTextTrackStyleFontGenericFamilyCursive = 6,
  /** Small Capitals. */
  GCKMediaTextTrackStyleFontGenericFamilySmallCapitals = 7,
};

/**
 * @enum GCKMediaTextTrackStyleFontStyle
 * Closed caption text font styles.
 */
typedef NS_ENUM(NSInteger, GCKMediaTextTrackStyleFontStyle) {
  /** Unknown font style. */
  GCKMediaTextTrackStyleFontStyleUnknown = -1,
  /** Normal. */
  GCKMediaTextTrackStyleFontStyleNormal = 0,
  /** Bold. */
  GCKMediaTextTrackStyleFontStyleBold = 1,
  /** Italic. */
  GCKMediaTextTrackStyleFontStyleItalic = 2,
  /** Bold italic. */
  GCKMediaTextTrackStyleFontStyleBoldItalic = 3,
};

/**
 * A class representing a style for a text media track.
 */
GCK_EXPORT
@interface GCKMediaTextTrackStyle : NSObject <NSCopying, NSSecureCoding>

/**
 * Designated initializer. All properties are mutable and so can be supplied after construction.
 */
- (instancetype)init;

/**
 * Creates an instance with default values based on the system's closed captioning settings. This
 * method will return nil on systems older than iOS 7.
 */
+ (instancetype)createDefault;

/** The font scaling factor for the text. */
@property(nonatomic, assign) CGFloat fontScale;

/** The foreground color. */
@property(nonatomic, copy, nullable) GCKColor *foregroundColor;

/** The background color. */
@property(nonatomic, copy, nullable) GCKColor *backgroundColor;

/** The edge type. */
@property(nonatomic, assign) GCKMediaTextTrackStyleEdgeType edgeType;

/** The edge color. */
@property(nonatomic, copy, nullable) GCKColor *edgeColor;

/** The window type. <i>Some receiver devices may not support this attribute.</i> */
@property(nonatomic, assign) GCKMediaTextTrackStyleWindowType windowType;

/** The window color. <i>Some receiver devices may not support this attribute.</i> */
@property(nonatomic, copy, nullable) GCKColor *windowColor;

/**
 * Rounded corner radius absolute value in pixels.
 * <i>Some receiver devices may not support this attribute.</i>
 */
@property(nonatomic, assign) CGFloat windowRoundedCornerRadius;

/** The font family; if the font is not available, the generic font family will be used. **/
@property(nonatomic, copy, nullable) NSString *fontFamily;

/** The generic font family. */
@property(nonatomic, assign) GCKMediaTextTrackStyleFontGenericFamily fontGenericFamily;

/** The font style. */
@property(nonatomic, assign) GCKMediaTextTrackStyleFontStyle fontStyle;

/** The custom data, if any. */
@property(nonatomic, strong, nullable) id customData;

@end

NS_ASSUME_NONNULL_END
