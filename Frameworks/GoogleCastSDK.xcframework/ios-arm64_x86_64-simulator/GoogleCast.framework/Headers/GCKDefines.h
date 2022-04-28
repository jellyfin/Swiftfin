// Copyright 2014 Google Inc.

#import <Availability.h>

#define GCK_VERSION_MAJOR 4
#define GCK_VERSION_MINOR 7
#define GCK_VERSION_FIX 0

#define GCK_VERSION_IS_LESS_THAN(__major, __minor, __fix)               \
  ((__major > GCK_VERSION_MAJOR)                                        \
   || ((__major == GCK_VERSION_MAJOR) && (__minor > GCK_VERSION_MINOR)) \
   || ((__major == GCK_VERSION_MAJOR) && (__minor == GCK_VERSION_MINOR) \
       && (__fix > GCK_VERSION_FIX)))

#define GCK_VERSION_IS_AT_LEAST(__major, __minor, __fix)                              \
  (!GCK_VERSION_IS_LESS_THAN(__major, __minor, __fix))

#define GCK_VERSION_IS_EQUAL_TO(__major, __minor, __fix)                              \
  ((__major == GCK_VERSION_MAJOR) && (__minor == GCK_VERSION_MINOR)                   \
   && (__fix == GCK_VERSION_FIX))

#define GCK_EXPORT __attribute__((visibility("default")))
#define GCK_DEPRECATED(message) __attribute__((deprecated(message)))
#define GCK_HIDDEN __attribute__((visibility("hidden")))

#ifdef __cplusplus
#define GCK_EXTERN extern "C" GCK_EXPORT
#else
#define GCK_EXTERN extern GCK_EXPORT
#endif

// The macros below are all deprecated, but are left for backwards compatibility reasons.
#if __has_feature(nullability)
  #define GCK_NULLABLE_TYPE _Nullable
  #define GCK_NONNULL_TYPE _Nonnull
  #define GCK_NULLABLE nullable
  #define GCK_NONNULL nonnull
#else
  #define GCK_NULLABLE_TYPE
  #define GCK_NONNULL_TYPE
  #define GCK_NULLABLE
  #define GCK_NONNULL
#endif  // __has_feature(nullability)

#if __has_feature(assume_nonnull)
  #define GCK_ASSUME_NONNULL_BEGIN _Pragma("clang assume_nonnull begin")
  #define GCK_ASSUME_NONNULL_END   _Pragma("clang assume_nonnull end")
#else
  #define GCK_ASSUME_NONNULL_BEGIN
  #define GCK_ASSUME_NONNULL_END
#endif  // __has_feature(assume_nonnull)
