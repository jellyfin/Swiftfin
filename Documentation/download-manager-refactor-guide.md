# DownloadManager Refactor & Modularization Guide

## 1. Overview
`DownloadManager.swift` has grown into a monolithic class that handles:

- URLSession background downloads (configuration, delegate callbacks)
- Construction of media & transcoding URLs
- Download metadata read/write (metadata.json, versions array)
- Downloading auxiliary assets (backdrop, primary images, subtitles)
- File system operations (create directories, move/validate files, cleanup)
- Disk space checks, error handling, retry logic
- Pause/resume/cancel and progress tracking

This single class violates the Single Responsibility Principle and is difficult to test or extend.

---

## 2. Goals
1. Split responsibilities into focused, testable services.  
2. Maintain a thin coordinator (`DownloadManager`) that orchestrates downloads.  
3. Improve readability, maintainability, and unit-test coverage.  
4. Enable dependency injection for easier mocking.

---

## 3. Proposed Modular Components

| Service                      | Responsibility                                                                                      | File                                      |
|------------------------------|----------------------------------------------------------------------------------------------------|-------------------------------------------|
| **DownloadSessionManager**   | - Configure & manage `URLSession` (background, delegates)
- Expose start/pause/resume/cancel methods
- Route delegate callbacks to observers                                    | `Shared/Services/Download/DownloadSessionManager.swift` |
| **DownloadURLBuilder**       | - Construct download URLs (original, transcoded)
- Build image & subtitle endpoints                                                       | `Shared/Services/Download/DownloadURLBuilder.swift`     |
| **DownloadMetadataManager**  | - Read & write `metadata.json`
- Merge versions, handle backward compatibility                                             | `Shared/Services/Download/DownloadMetadataManager.swift`|
| **DownloadImageManager**     | - Download or retry backdrop & primary images
- Track non-critical download failures                                                    | `Shared/Services/Download/DownloadImageManager.swift`   |
| **DownloadFileService**      | - Filesystem: create download folders, move & validate media files
- Calculate sizes, delete items, clear tmp                                       | `Shared/Services/Download/DownloadFileService.swift`    |
| **DownloadManager**          | - Orchestrates the above services
- Publishes progress & state as `@Published` properties in a slim class
- Handles high-level start/pause/resume/cancel API                             | `Shared/Services/Download/DownloadManager.swift`        |

---

## 4. Directory Structure
```
Shared/Services/Download/
├── DownloadSessionManager.swift
├── DownloadURLBuilder.swift
├── DownloadMetadataManager.swift
├── DownloadImageManager.swift
├── DownloadFileService.swift
└── DownloadManager.swift     ← Orchestration only
```

---

## 5. Interfaces & Responsibilities

### 5.1 DownloadSessionManager
```swift
protocol DownloadSessionManaging {
  func start(url: URL, taskID: UUID, jobType: DownloadJobType)
  func pause(taskID: UUID)
  func resume(taskID: UUID)
  func cancel(taskID: UUID)
  var delegate: DownloadSessionDelegate? { get set }
}
```
- Encapsulates `URLSession` setup (background config)
- Implements `URLSessionDownloadDelegate`
- Emits callbacks (progress, completion, errors) to its delegate

### 5.2 DownloadURLBuilder
```swift
protocol DownloadURLBuilding {
  func mediaURL(itemId: String, quality: DownloadQuality, mediaSourceId: String?) -> URL?
  func transcodingURL(...)
  func imageURL(item: BaseItemDto, type: DownloadJobType) -> URL?
}
```
- Moves all `construct*URL` functions here

### 5.3 DownloadMetadataManager
```swift
protocol DownloadMetadataManaging {
  func readMetadata(itemId: String) -> DownloadMetadata?
  func writeMetadata(_ metadata: DownloadMetadata, to folder: URL) throws
  func deleteMetadata(itemId: String) throws
}
```
- Handles Codable read/write of `DownloadMetadata` files

### 5.4 DownloadImageManager
```swift
protocol DownloadImageManaging {
  func downloadImages(for item: BaseItemDto, into folder: URL, completion: (Result<Void, Error>) -> Void)
}
```
- Coordinates non-blocking image downloads
- Reports failures without canceling the main media download

### 5.5 DownloadFileService
```swift
protocol DownloadFileServicing {
  func ensureDownloadDirectory() throws
  func moveMediaFile(from temp: URL, to destination: URL) throws
  func validateMediaFile(at url: URL, response: URLResponse?) throws
  func calculateSize(of folder: URL) throws -> Int64
  func deleteDownloads(for itemId: String) throws
}
```
- All file I/O, validation & cleanup logic

### 5.6 DownloadManager (Coordinator)
```swift
final class DownloadManager: ObservableObject {
  @Published private(set) var downloads: [DownloadTask]

  init(
    session: DownloadSessionManaging = DownloadSessionManager(),
    urlBuilder: DownloadURLBuilding = DownloadURLBuilder(),
    metadata: DownloadMetadataManaging = DownloadMetadataManager(),
    images: DownloadImageManaging = DownloadImageManager(),
    fileService: DownloadFileServicing = DownloadFileService()
  ) { … }

  func startDownload(itemId: String, ...) → UUID { … }
  func pauseDownload(taskID: UUID) { … }
  // ... other high-level APIs ...
}
```
- Injects each service for testability
- Coordinates the download workflow:  
  1. `checkAvailableDiskSpace` (via FileService)  
  2. `session.start` (via SessionManager)  
  3. On completion, move file & validate (via FileService)  
  4. Save metadata (via MetadataManager)  
  5. Download images (via ImageManager)

---

## 6. Implementation Steps

1. **Create `Shared/Services/Download/` folder.**  
2. **Define all protocols** (`DownloadSessionManaging`, etc.) in new files.  
3. **Move URLSession setup & delegate methods** from `DownloadManager.swift` → `DownloadSessionManager.swift`.  
4. **Extract URL construction logic** to `DownloadURLBuilder.swift`.  
5. **Extract metadata read/write** to `DownloadMetadataManager.swift`.  
6. **Extract image download logic** to `DownloadImageManager.swift`.  
7. **Extract all filesystem methods** (`moveDownloadedFile`, `getFolderSize`, delete, clearTmp) → `DownloadFileService.swift`.  
8. **Refactor `DownloadManager.swift`** to remove implementation details and inject new services.  
9. **Add unit tests** for each service, mocking dependencies as needed.  
10. **Update Factory+DI containers** to register new services.  

---

## 7. Testing & Validation
- Write tests for each protocol implementation.  
- Mock network (`URLProtocolStub`) and file system (in-memory or temporary directories).  
- Validate metadata read/write and folder size calculations.  
- Simulate delegate callbacks in `DownloadSessionManager` tests.  
- Ensure overall end-to-end workflow works via integration tests of `DownloadManager`.

---

## 8. Conclusion
This refactor decouples concerns, improves test coverage, and makes future enhancements (e.g. adding new asset types or quality options) straightforward. Each new service is small enough to understand and maintain in isolation, while `DownloadManager` remains a clear orchestrator of the download process.
