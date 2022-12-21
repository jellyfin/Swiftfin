//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Factory
import Files
import Foundation
import JellyfinAPI
import Nuke

extension Container {
    
    static let downloadManager = Factory(scope: .singleton) {
        let a = DownloadManager()
        
        a.clearTmp()
        
        return a
    }
}

class DownloadManager: ObservableObject {
    
    @Injected(LogManager.service)
    private var logger
    
    @Published
    private(set) var downloads: [DownloadTask] = []
    
    func canDownload(mediaSource: MediaSourceInfo) throws {
        
    }
    
    func clearTmp() {
        do {
            try Folder(path: URL.tmp.absoluteString).files.delete()
            logger.trace("Cleared tmp directory")
        } catch {
            logger.error("Unable to clear tmp directory: \(error.localizedDescription)")
        }
    }
    
    func download(task: DownloadTask) {
        guard !downloads.contains(where: { $0.item == task.item }) else { return }
        
        downloads.append(task)
        
        task.download()
    }
    
    func task(for item: BaseItemDto) -> DownloadTask? {
        downloads.first(where: { $0.item == item })
    }
    
    func stop(task: DownloadTask) {
        guard downloads.contains(where: { $0.item == task.item }) else { return }
        
        task.stop()
        
        downloads.removeAll(where: { $0.item == task.item })
    }
    
    fileprivate func didComplete(task: DownloadTask, at url: URL) {
        let downloads = URL.documents.appendingPathComponent("Downloads")
        
        try? FileManager.default.createDirectory(
            at: downloads,
            withIntermediateDirectories: true
        )
        
        let itemURL = downloads.appendingPathComponent(task.item.displayTitle, isDirectory: true)
        
        try! FileManager.default.moveItem(atPath: url.path, toPath: itemURL.path)
        try! FileManager.default.removeItem(at: url)
    }
}

class DownloadTask: NSObject, ObservableObject {
    
    enum DownloadError: Error {
        
        case notEnoughStorage
        
        var localizedDescription: String {
            switch self {
            case .notEnoughStorage:
                return "Not enough storage"
            }
        }
    }
    
    enum State {
        
        case cancelled
        case complete
        case downloading(Double)
        case error(Error)
        case ready
    }
    
    @Injected(Container.userSession)
    private var userSession
    
    @Published
    private(set) var state: State = .ready
    
    private var downloadTask: Task<Void, Never>?
    
    let item: BaseItemDto
    
    init(item: BaseItemDto) {
        self.item = item
    }
    
    fileprivate func download() {
        let task = Task {
            let request = Paths.getDownload(itemID: item.id!)
            let a = try? await userSession.client.download(for: request, delegate: self)
            
            print("download complete: \(a?.value.absoluteString)")
        }
        
        self.downloadTask = task
    }
    
    fileprivate func stop() {
        self.downloadTask?.cancel()
    }
}

extension DownloadTask: URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        
        DispatchQueue.main.async {
            self.state = .downloading(progress)
        }
    }
    
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        print("here")
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        DispatchQueue.main.async {
            self.state = .complete
            
            Container.downloadManager.callAsFunction()
                .didComplete(task: self, at: location)
        }
    }
    
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error else { return }
        self.state = .error(error)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }
        self.state = .error(error)
    }
}
