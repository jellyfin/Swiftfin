# Swiftfin Downloads - File Structure & Management Guide

## Overview

Swiftfin's download system organizes media files, images, and metadata in a hierarchical structure that accommodates different content types (movies, TV series, episodes) while supporting multiple versions of the same content. This document provides a comprehensive guide to understanding how downloads are stored and managed locally.

## Base Download Location

```swift
static var downloads: URL {
    documents.appendingPathComponent("Downloads")
}
```

All downloads are stored under:
- **Path**: `Documents/Downloads/`
- **Location**: App's sandboxed Documents directory
- **Security**: Files are excluded from backup and protected with `FileProtectionType.completeUntilFirstUserAuthentication`

## File Structure Overview

### Movies
```
Downloads/
├── [movieId]/
│   ├── metadata.json                    # Movie metadata + versions
│   ├── Images/                         # Movie images
│   │   ├── Primary.jpeg               # Movie poster
│   │   └── Backdrop.jpeg              # Movie backdrop
│   ├── [movieId]-[versionId].mp4      # Media files (versioned)
│   └── [movieId]-[versionId2].mkv     # Additional versions
```

### TV Series/Episodes
```
Downloads/
├── [seriesId]/                         # Series root folder
│   ├── metadata.json                  # Series-level metadata
│   ├── Images/                        # Series-level images
│   │   ├── Series-[seriesId]-Primary.jpeg
│   │   └── Series-[seriesId]-Backdrop.jpeg
│   ├── Season-01/                     # Zero-padded season folders
│   │   ├── metadata.json             # Season metadata + episode info
│   │   ├── Images/                   # Season and episode images
│   │   │   ├── Season-[seasonId]-Primary.jpeg
│   │   │   ├── Episode-[episodeId]-Primary.jpeg
│   │   │   └── Episode-[episodeId]-Backdrop.jpeg
│   │   ├── [episodeId]-[versionId].mp4    # Episode media files
│   │   └── [episodeId2]-[versionId].mp4   # More episodes
│   └── Season-02/
│       ├── metadata.json
│       ├── Images/
│       └── [episodeId]-[versionId].mp4
```

## Content Type Determination

The folder structure is determined by the `BaseItemDto.downloadFolder` property:

```swift
var downloadFolder: URL? {
    guard let type, let id else { return nil }
    let root = URL.downloads
    
    switch type {
    case .movie:
        return root.appendingPathComponent(id)  // Uses movieId
    case .episode:
        guard let seriesID = seriesID else { return nil }
        return root.appendingPathComponent(seriesID)  // Uses seriesId, not episodeId
    default:
        return nil
    }
}
```

## Media File Naming Conventions

### Movies
- **Pattern**: `[movieId]-[versionId].{ext}`
- **Example**: `abc123-def456.mp4`
- **Location**: Direct in movie folder

### Episodes
- **Pattern**: `[episodeId]-[versionId].{ext}`
- **Example**: `ep789-med123.mp4`
- **Location**: Inside season folder (`Season-01/`, `Season-02/`, etc.)

### Version Identification
- **versionId**: Typically the `mediaSourceId` if available, otherwise defaults to `itemId`
- **Fallback**: If no explicit version, uses item ID as version identifier
- **Extension**: Determined from HTTP response MIME type or defaults to container format

## Image Organization & Hierarchy

### Hierarchical Distribution
Images are distributed across different levels based on their scope:

1. **Series Level**: `Downloads/[seriesId]/Images/`
   - Series posters and backdrops
   - Naming: `Series-[seriesId]-{Primary|Backdrop}.{ext}`

2. **Season Level**: `Downloads/[seriesId]/Season-XX/Images/`
   - Season-specific artwork
   - Naming: `Season-[seasonId]-{Primary|Backdrop}.{ext}`

3. **Episode Level**: `Downloads/[seriesId]/Season-XX/Images/`
   - Episode thumbnails and stills
   - Naming: `Episode-[episodeId]-{Primary|Backdrop}.{ext}`

4. **Movie Level**: `Downloads/[movieId]/Images/`
   - Movie posters and backdrops
   - Naming: `{Primary|Backdrop}.{ext}`

### Image Download Context
Images are downloaded with context awareness:

```swift
enum ImageDownloadContext {
    case episode(id: String)
    case season(id: String)
    case series(id: String)
    case movie(id: String)
}
```

## Metadata Structure & Management

### Metadata Format
All metadata is stored in `metadata.json` files using the `DownloadMetadata` structure:

```swift
struct DownloadMetadata: Codable {
    let itemId: String
    let itemType: String?
    let displayTitle: String
    var item: BaseItemDto?          // Full item payload
    var versions: [VersionInfo]     // All downloaded versions
}
```

### Version Information
Each downloaded version is tracked with detailed information:

```swift
struct VersionInfo: Codable {
    let versionId: String           // Unique version identifier
    let container: String           // File container (mp4, mkv, etc.)
    let isStatic: Bool             // Whether it's static download
    let mediaSourceId: String?      // Jellyfin media source ID
    let downloadDate: String        // ISO8601 download timestamp
    let taskId: String             // Download task UUID
}
```

### Hierarchical Metadata (TV Series)

For TV episodes, metadata is written at multiple levels:

1. **Series Level**: `Downloads/[seriesId]/metadata.json`
   - Contains series information
   - Aggregates versions from all seasons

2. **Season Level**: `Downloads/[seriesId]/Season-XX/metadata.json`
   - Contains season information
   - Includes episode versions within that season
   - Embedded episode item data

3. **No Episode Level**: Episodes don't have individual metadata files; they're tracked in season metadata

## Version Management

### Version Identification
- **Primary**: `mediaSourceId` (if available)
- **Fallback**: `itemId` (for backward compatibility)
- **Normalization**: `nil` mediaSourceId is treated as equivalent to `itemId`

### Duplicate Prevention
The system prevents duplicate versions by:

1. **Metadata Deduplication**: Removes existing version entries with same `mediaSourceId`
2. **File Replacement**: Atomically replaces existing media files
3. **Version Comparison**: Normalizes `nil` mediaSourceId to `itemId` for comparison

### Version Lookup
```swift
func isItemVersionDownloaded(itemId: String, mediaSourceId: String?) -> Bool {
    let targetMediaSourceId = mediaSourceId ?? itemId
    let downloadedVersions = getDownloadedVersions(for: itemId)
    
    let hasMetadataVersion = downloadedVersions.contains { version in
        let versionMediaSourceId = version.mediaSourceId ?? itemId
        return versionMediaSourceId == targetMediaSourceId
    }
    
    let hasMediaFile = fileService.hasMediaFile(for: itemId, mediaSourceId: mediaSourceId)
    return hasMetadataVersion && hasMediaFile
}
```

## File Discovery Patterns

### Media File Discovery
The system uses multiple strategies to locate media files:

1. **Version-Specific Search**: Looks for files containing `mediaSourceId`
2. **Item-Based Search**: Falls back to files containing `itemId`
3. **Legacy Support**: Recognizes old `Media.*` naming pattern
4. **Recursive Search**: Searches season folders for episodes (up to 3 levels deep)

### Image File Discovery
Images are located using hierarchical search:

1. **Season-Level First**: For episodes, checks season Images folder
2. **Series-Level Fallback**: Falls back to series Images folder
3. **Type-Specific**: Searches for `Primary` or `Backdrop` prefixed files

### Metadata Discovery
1. **Direct Read**: Reads `metadata.json` from item folder
2. **Series Aggregation**: For series, aggregates from season folders
3. **Legacy Compatibility**: Falls back to old `Metadata/Item.json` format

## Legacy Compatibility

### File Structure Migration
The system maintains backward compatibility:

- **Old Episode Structure**: Individual episode folders
- **New Episode Structure**: Episodes within series folders by season
- **Legacy Metadata**: Old `Metadata/Item.json` format still readable
- **File Naming**: Supports both new versioned names and legacy `Media.*` pattern

### Cleanup Process
During metadata writing, legacy structures are cleaned up:
```swift
// Remove legacy Metadata folder if present
let legacyMetadataFolder = downloadFolder.appendingPathComponent("Metadata")
if FileManager.default.fileExists(atPath: legacyMetadataFolder.path, isDirectory: &isDir), isDir.boolValue {
    try FileManager.default.removeItem(at: legacyMetadataFolder)
}
```

## Download Job Types

### Job Type Enumeration
```swift
enum DownloadJobType: Hashable, Equatable {
    case media              // The primary media file
    case backdropImage      // Backdrop/fanart images
    case primaryImage       // Poster/primary images
    case metadata           // Item metadata
    case subtitle(index: Int)  // Subtitle files (future)
}
```

### Job Completion Tracking
Essential jobs for completion:
- **Media**: The actual video/audio file
- **Metadata**: Item and version information
- **Images**: Optional (don't block completion)

## Technical Implementation Details

### File Protection & Security
- **Backup Exclusion**: `isExcludedFromBackup = true`
- **File Protection**: `FileProtectionType.completeUntilFirstUserAuthentication`
- **Atomic Operations**: File moves are atomic to prevent corruption

### Storage Management
- **Disk Space Checks**: Requires minimum 100MB free space before download
- **Size Calculation**: Recursive directory size calculation for storage management
- **File Validation**: HTTP response validation and minimum file size checks

### Error Handling
- **Retry Logic**: Exponential backoff for network errors
- **Validation**: Media file validation before final placement
- **Cleanup**: Automatic cleanup of incomplete downloads

## Download URL Construction

### Media Downloads
```
/Items/{mediaSourceId ?? itemId}/Download?
  MediaSourceId={mediaSourceId}&
  Container={container}&
  Static={isStatic}&
  AllowVideoStreamCopy={allowVideoStreamCopy}&
  AllowAudioStreamCopy={allowAudioStreamCopy}&
  api_key={accessToken}
```

### Image Downloads
- **Primary Images**: Item's primary image source (300px width)
- **Backdrop Images**: Item's backdrop source (600px width)
- **Series Images**: Uses series-level image sources
- **Episode Images**: Uses episode primary image for backdrop context

## Performance Considerations

### File Operations
- **Enumerator Usage**: Uses `FileManager.DirectoryEnumerator` for large directories
- **Resource Keys**: Optimized property fetching with specific resource keys
- **Depth Limiting**: Recursive searches limited to prevent deep traversal

### Memory Management
- **Streaming**: Large file operations use streaming where possible
- **Lazy Evaluation**: Directory contents loaded lazily
- **Weak References**: Delegate patterns use weak references

## Debugging & Troubleshooting

### Debug Methods
```swift
func debugListDownloadedItems()
func debugCheckSpecificVersion(itemId: String, mediaSourceId: String?)
```

### Common Issues
1. **Missing Media Files**: Check version normalization and file naming
2. **Image Not Found**: Verify hierarchical image search path
3. **Metadata Corruption**: System falls back to creating new metadata
4. **Version Conflicts**: Deduplication handles multiple versions of same content

---

This guide provides a comprehensive understanding of Swiftfin's download system architecture, enabling developers to work effectively with the local file organization and implement new features that integrate properly with the existing structure.
