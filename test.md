The `DownloadManager` in the Swiftfin project is a comprehensive service designed to manage media downloads from a Jellyfin server. It supports multiple quality levels, background downloads, metadata management, and error handling. Below is a detailed summary of its functionality:

---

### **Core Responsibilities**
1. **Media Downloads**:
   - Handles downloading media files (movies, episodes) from the Jellyfin server.
   - Supports multiple quality levels, including original, high, medium, low, and custom transcoding parameters.
   - Allows downloading specific media versions using `mediaSourceId`.

2. **Metadata Management**:
   - Saves metadata for downloaded items, including version information.
   - Ensures metadata is updated and stored in a `metadata.json` file.
   - Supports backward compatibility with older metadata formats.

3. **Background Downloads**:
   - Uses a background `URLSession` to manage downloads, allowing them to continue even when the app is in the background.
   - Recovers active downloads when the app is relaunched.

4. **Error Handling and Retry Logic**:
   - Handles download errors gracefully, including HTTP errors, file validation issues, and insufficient disk space.
   - Implements retry logic with exponential backoff for failed downloads.

5. **File Management**:
   - Organizes downloaded files into structured directories.
   - Validates downloaded files for integrity and security.
   - Moves files from temporary locations to their final destinations with proper file protection attributes.

6. **Progress Tracking**:
   - Tracks the progress of downloads and updates the UI using `@Published` properties.
   - Differentiates between essential downloads (media and metadata) and optional ones (images, subtitles).

7. **Image and Subtitle Downloads**:
   - Downloads additional assets like backdrop images, primary images, and subtitles.
   - Handles failures for non-essential downloads without blocking the completion of the main task.

8. **Disk Space Management**:
   - Checks available disk space before starting downloads.
   - Ensures a minimum of 100MB free space is available.

9. **Pause, Resume, and Cancel**:
   - Allows pausing and resuming downloads, including support for resuming from partial data using `resumeData`.
   - Cancels downloads and optionally removes associated files.

10. **Debugging and Logging**:
    - Provides debug methods to list downloaded items and check specific versions.
    - Logs detailed information about download progress, errors, and file operations.

---

### **Key Features**

#### **Download Quality Options**
- **Original**: Downloads the original file without transcoding.
- **High**: 1080p, ~4 Mbps.
- **Medium**: 720p, ~2 Mbps.
- **Low**: 480p, ~1 Mbps.
- **Custom**: Allows specifying transcoding parameters like resolution, bitrate, and stream copy options.

#### **Metadata Management**
- Stores metadata for each downloaded item, including:
  - Item ID, type, and display title.
  - Full item payload (optional).
  - Version information (e.g., version ID, container, download date, task ID).
- Ensures metadata is updated when new versions are downloaded.

#### **Background URLSession**
- Configured with a unique identifier for background downloads.
- Supports launch events for background tasks.
- Recovers active downloads when the app is relaunched.

#### **Error Handling**
- Validates HTTP responses and file sizes to ensure downloads are successful.
- Handles critical errors (e.g., media download failures) and non-critical ones (e.g., image download failures).
- Retries failed downloads with exponential backoff.

#### **File Organization**
- Organizes downloaded files into directories based on item type (e.g., movies, episodes).
- Supports versioned filenames to avoid conflicts.
- Excludes files from iCloud backups and applies file protection attributes.

#### **Progress and State Management**
- Tracks the state of each download (`ready`, `downloading`, `paused`, `complete`, `error`).
- Updates progress for media downloads in real-time.
- Marks tasks as complete when essential downloads (media and metadata) are finished.

#### **Utility Methods**
- **Disk Space Management**:
  - Calculates total storage used by downloads.
  - Checks available disk space before starting downloads.
- **Deletion**:
  - Deletes all downloaded media or specific items.
  - Supports batch deletion of multiple items.
- **Validation**:
  - Checks if an item or specific version is downloaded.
  - Validates downloaded files for integrity.

#### **Debugging**
- Lists all downloaded items and their metadata.
- Checks if a specific item version is downloaded.

---

### **Public API**
1. **Download Management**:
   - `startDownload`: Starts a new download task.
   - `pauseDownload`: Pauses an active download.
   - `resumeDownload`: Resumes a paused download.
   - `cancelDownload`: Cancels a download and optionally removes files.

2. **Metadata and File Operations**:
   - `getDownloadMetadata`: Retrieves metadata for a specific item.
   - `getDownloadedVersions`: Lists all downloaded versions for an item.
   - `deleteDownloadedMedia`: Deletes downloaded media for a specific item or multiple items.
   - `getTotalDownloadSize`: Calculates the total storage used by downloads.

3. **State and Progress**:
   - `downloadStatus`: Retrieves the current state of a download task.
   - `allDownloads`: Returns a list of all active downloads.

4. **Debugging**:
   - `debugListDownloadedItems`: Lists all downloaded items and their metadata.
   - `debugCheckSpecificVersion`: Checks if a specific item version is downloaded.

---

### **Architecture**
- **Service/Coordinator Pattern**: The `DownloadManager` acts as a service, coordinating download tasks and managing their state.
- **ObservableObject**: Uses `@Published` properties to notify the UI of changes in download state and progress.
- **Background URLSession**: Ensures downloads continue even when the app is in the background.

---

### **Limitations**
- Subtitle downloads are not fully implemented.
- Some error handling (e.g., for subtitle retries) is marked as TODO.
- Image downloads are non-blocking but may fail silently.

---

### **Conclusion**
The `DownloadManager` is a robust and feature-rich component that handles all aspects of media downloads in the Swiftfin app. It ensures reliability, flexibility, and user-friendly functionality, making it a critical part of the app's offline playback experience.