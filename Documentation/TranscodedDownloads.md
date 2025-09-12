# Transcoded Downloads

The enhanced DownloadManager now supports downloading media in both original quality and transcoded formats at different quality levels.

## Usage

### Original Quality Download (Default)
```swift
let taskID = downloadManager.startDownload(
    itemId: "item123",
    quality: .original
)
```

### Transcoded Quality Downloads

#### High Quality (1080p, ~4 Mbps)
```swift
let taskID = downloadManager.startDownload(
    itemId: "item123",
    quality: .high
)
```

#### Medium Quality (720p, ~2 Mbps)
```swift
let taskID = downloadManager.startDownload(
    itemId: "item123",
    quality: .medium
)
```

#### Low Quality (480p, ~1 Mbps)
```swift
let taskID = downloadManager.startDownload(
    itemId: "item123", 
    quality: .low
)
```

#### Custom Quality Parameters
```swift
let customParams = DownloadManager.TranscodingParameters(
    maxWidth: 1280,
    maxHeight: 720,
    videoBitRate: 1_500_000,  // 1.5 Mbps
    audioBitRate: 128_000,    // 128 kbps
    enableAutoStreamCopy: true
)

let taskID = downloadManager.startDownload(
    itemId: "item123",
    quality: .custom(customParams)
)
```

## Quality Settings

| Quality | Resolution | Video Bitrate | Audio Bitrate | Use Case |
|---------|------------|---------------|---------------|----------|
| Original | Unchanged | Unchanged | Unchanged | Best quality, larger files |
| High | 1080p | 4 Mbps | 128 kbps | High quality, moderate size |
| Medium | 720p | 2 Mbps | 128 kbps | Good quality, smaller size |
| Low | 480p | 1 Mbps | 96 kbps | Acceptable quality, smallest size |

## How It Works

- **Original Quality**: Uses Jellyfin's `/Items/{itemId}/Download` endpoint with `static=true` to download the original file without transcoding
- **Transcoded Quality**: Uses Jellyfin's `/Videos/{itemId}/stream.{container}` endpoint with `static=false` and quality constraints to force server-side transcoding

## Multi-File Downloads

All quality levels support downloading additional files:
- Media file (with chosen quality)
- Backdrop images
- Primary images  
- Metadata files

## Background Downloads

Transcoded downloads work with the background URLSession infrastructure, supporting:
- App backgrounding during downloads
- Download progress tracking
- Pause/resume functionality
- Automatic retry with exponential backoff
- Error handling and recovery

---

## Download Management

The DownloadManager provides comprehensive functionality for managing downloaded media:

### Listing Downloaded Media

```swift
// Get all downloaded items as DownloadTask objects
let downloadedItems = downloadManager.downloadedItems()

// Get just the item IDs
let itemIds = downloadManager.getDownloadedItemIds()

// Check if a specific item is downloaded
let isDownloaded = downloadManager.isItemDownloaded(itemId: "item123")
```

### Deleting Downloaded Media

#### Delete All Downloaded Media
```swift
// Permanently deletes all downloaded content
downloadManager.deleteAllDownloadedMedia()
```

#### Delete Specific Items
```swift
// Delete a single item
let wasDeleted = downloadManager.deleteDownloadedMedia(itemId: "item123")

// Delete multiple items
let itemIds = ["item1", "item2", "item3"]
let deletedItems = downloadManager.deleteDownloadedMedia(itemIds: itemIds)
```

#### Cancel Active Downloads with File Removal
```swift
// Cancel and remove files for an active download
downloadManager.cancelDownload(taskID: taskID, removeFile: true)
```

### Storage Management

```swift
// Get total storage used by all downloads (in bytes)
if let totalSize = downloadManager.getTotalDownloadSize() {
    let sizeInMB = totalSize / (1024 * 1024)
    print("Total download size: \(sizeInMB) MB")
}

// Get storage used by a specific item
if let itemSize = downloadManager.getDownloadSize(itemId: "item123") {
    let sizeInMB = itemSize / (1024 * 1024) 
    print("Item size: \(sizeInMB) MB")
}
```

### File Structure

Downloaded media is organized as follows:
```
Downloads/
├── [itemId]/
│   ├── [itemId]-[versionId].mp4     # Media file
│   ├── Images/
│   │   ├── Primary.jpg              # Primary image
│   │   └── Backdrop.jpg             # Backdrop image  
│   ├── Metadata/
│   │   └── Item.json                # Item metadata
│   └── metadata.json                # Version metadata
└── [episodeItemId]/                 # For TV episodes
    ├── Season-[number]/
    │   └── [episodeId]-[versionId].mp4
    ├── Images/
    ├── Metadata/
    └── metadata.json
```

### Error Handling

All deletion methods include proper error handling and logging:
- Failed deletions are logged with detailed error messages
- Methods return success/failure indicators
- Active downloads are properly cancelled before file deletion
- File system errors are handled gracefully
