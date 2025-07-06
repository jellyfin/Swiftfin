import Foundation

enum VideoQuality: String {
    case hls
}

class APIClient {
    let baseURL: URL
    let apiKey: String
    let userId: String

    init(baseURL: URL, apiKey: String, userId: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.userId = userId
    }

    enum DownloadError: Error {
        case invalidURL
        case httpError(Int)
    }

    func downloadItem(
        itemId: String,
        quality: VideoQuality = .hls,
        onProgress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        var url = baseURL
            .appendingPathComponent("Users/\(userId)/Items/\(itemId)/Download")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components = components?.addingQueryItem(key: "Quality", value: quality.rawValue)
        components = components?.addingQueryItem(key: "api_key", value: apiKey)
        guard let finalURL = components?.url else {
            completion(.failure(DownloadError.invalidURL))
            return
        }

        let task = URLSession.shared.streamTask(with: finalURL)
        let destination = URL.tmp.appendingPathComponent(UUID().uuidString)

        guard FileManager.default.createFile(atPath: destination.path, contents: nil) else {
            completion(.failure(DownloadError.invalidURL))
            return
        }
        var fileHandle: FileHandle!
        do {
            fileHandle = try FileHandle(forWritingTo: destination)
        } catch {
            completion(.failure(error))
            return
        }

        var received: Int64 = 0
        let expected = task.countOfBytesExpectedToReceive

        func readChunk() {
            task.readData(ofMinLength: 1, maxLength: 64 * 1024, timeout: 60) { data, atEOF, error in
                if let error {
                    task.cancel()
                    completion(.failure(error))
                    return
                }
                if let data {
                    received += Int64(data.count)
                    try? fileHandle.write(contentsOf: data)
                    if expected > 0 {
                        let progress = Double(received) / Double(expected)
                        onProgress(progress)
                    }
                }
                if atEOF {
                    fileHandle.closeFile()
                    completion(.success(destination))
                } else {
                    readChunk()
                }
            }
        }

        task.resume()
        readChunk()
    }
}

// End of download implementation
