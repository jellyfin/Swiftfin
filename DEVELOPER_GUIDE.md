# Swiftfin Developer Guide for Beginners

Welcome to the Swiftfin codebase! This guide will help you understand the project structure, where to find and add new features, and how to implement a simple download feature. It is written for Swift/iOS beginners and follows the project's architectural conventions.

---

## 1. Project Structure Overview

Here is a simplified tree of the most relevant folders and files:

```
Swiftfin/
├── Shared/
│   ├── Components/
│   ├── Coordinators/
│   ├── Errors/
│   ├── Extensions/
│   ├── Logging/
│   ├── Objects/
│   ├── ServerDiscovery/
│   ├── Services/
│   ├── Strings/
│   ├── SwiftfinStore/
│   └── ViewModels/
├── Swiftfin/
│   ├── App/
│   ├── Components/
│   ├── Extensions/
│   ├── Objects/
│   ├── Resources/
│   ├── Views/
├── Swiftfin tvOS/
│   └── ...
```

- **Shared/**: Code shared between iOS and tvOS (business logic, models, services, view models, reusable components)
- **Swiftfin/**: iOS-specific code (UI, platform-specific components, views)
- **Swiftfin/Views/**: iOS-specific SwiftUI views, including tab views and screens
- **Shared/Services/**: Shared services (networking, data, etc.)
- **Shared/Components/**: Reusable UI components for both platforms

---

## 2. Where to Find and Add Code

### **Services**
- **Location:** `Shared/Services/`
- **Purpose:** Business logic, networking, data access, and background tasks.
- **How to Add:**
  1. Create a new Swift file in `Shared/Services/` (e.g., `DownloadService.swift`).
  2. Implement your service as a class or struct.
  3. Register it with the dependency injection container if needed.

### **Tab Views**
- **Location:** `Swiftfin/Views/`
- **Purpose:** Main app tabs (e.g., Home, Library, Downloads).
- **How to Add:**
  1. Create a new SwiftUI view in `Swiftfin/Views/` (e.g., `DownloadsTabView.swift`).
  2. Add it to the tab coordinator or main tab view.

### **Components for Items**
- **Location:** `Shared/Components/` (for shared UI), `Swiftfin/Components/` (for iOS-specific UI)
- **Purpose:** Reusable UI elements (e.g., media item cards, buttons).
- **How to Add:**
  1. Create a new SwiftUI view in the appropriate folder.
  2. Use it in your screens or other components.

---

## 3. Reusing Code from Shared and Swiftfin/Views

- **Shared/** contains logic and UI that can be used on both iOS and tvOS.
- To reuse a component or service, simply import and use it in your iOS-specific code:

```swift
import Shared

struct MyScreen: View {
    var body: some View {
        SharedComponent()
    }
}
```

- For view models and services, use dependency injection:

```swift
@Injected(\.downloadService) var downloadService: DownloadService
```

---

## 4. Step-by-Step: Implementing a Download Feature

### **A. Add a New Service**

1. **Create the Service:**
   - File: `Shared/Services/DownloadService.swift`
   - Example:

```swift
import Foundation

final class DownloadService {
    func downloadItem(with url: URL, completion: @escaping (Result<URL, Error>) -> Void) {
        // Simple download logic
        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
            if let localURL = localURL {
                completion(.success(localURL))
            } else if let error = error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}
```

2. **Register with Dependency Injection:**
   - In your DI container (e.g., `Shared/Services/Container+Services.swift`):

```swift
extension Container {
    var downloadService: Factory<DownloadService> { self { DownloadService() } }
}
```

---

### **B. Create New Views**

1. **Tab View:**
   - File: `Swiftfin/Views/DownloadsTabView.swift`
   - Example:

```swift
import SwiftUI
import Shared

struct DownloadsTabView: View {
    @Injected(\.downloadService) var downloadService: DownloadService
    @State private var downloadURL: String = ""
    @State private var status: String = ""

    var body: some View {
        VStack {
            TextField("Enter URL", text: $downloadURL)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            Button("Download") {
                guard let url = URL(string: downloadURL) else { return }
                downloadService.downloadItem(with: url) { result in
                    DispatchQueue.main.async {
                        switch result {
                        case .success(let fileURL):
                            status = "Downloaded to: \(fileURL.path)"
                        case .failure(let error):
                            status = "Error: \(error.localizedDescription)"
                        }
                    }
                }
            }
            Text(status)
                .padding()
        }
        .navigationTitle("Downloads")
    }
}
```

2. **Add to Tab Bar:**
   - In your main tab view or coordinator (e.g., `Swiftfin/Views/MainTabView.swift`):

```swift
TabView {
    // ...existing tabs...
    DownloadsTabView()
        .tabItem {
            Image(systemName: "arrow.down.circle")
            Text("Downloads")
        }
}
```

---

### **C. Reuse Shared Components**

- Use any UI from `Shared/Components/` in your new views:

```swift
import Shared

struct DownloadsTabView: View {
    var body: some View {
        VStack {
            SharedDownloadProgressView()
            // ...
        }
    }
}
```

---

## 5. Summary Table

| Feature         | Directory Path                | Example File                        |
|-----------------|------------------------------|-------------------------------------|
| Service         | Shared/Services/             | DownloadService.swift               |
| Tab View        | Swiftfin/Views/              | DownloadsTabView.swift              |
| Component       | Shared/Components/           | SharedDownloadProgressView.swift    |

---

## 6. Tips

- Always prefer shared code for business logic and reusable UI.
- Use dependency injection for services and view models.
- Follow MVVM and coordinator patterns for navigation and state.
- For platform-specific UI, use the respective target folder (Swiftfin/ for iOS).

---

Happy coding! If you have questions, check the code in the referenced folders or ask your team for guidance.
