//
//  JellyfinHLSResourceLoaderDelegate.swift

import Foundation
import AVFoundation

class JellyfinHLSResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, URLSessionDataDelegate, URLSessionTaskDelegate {

    typealias Completion = (URL?) -> Void
    
    private static let SchemeSuffix = "icpt"
    
    // MARK: - Properties
    // MARK: Public
    
    var completion: Completion?
    
    lazy var streamingAssetURL: URL = {
        guard var components = URLComponents(url: self.url, resolvingAgainstBaseURL: false) else {
            fatalError()
        }
        components.scheme = (components.scheme ?? "") + JellyfinHLSResourceLoaderDelegate.SchemeSuffix
        guard let retURL = components.url else {
            fatalError()
        }
        return retURL
    }()
    
    // MARK: Private
    
    private let url:            URL
    private var infoResponse:   URLResponse?
    private var urlSession:     URLSession?
    private lazy var mediaData  = Data()
    private var loadingRequests = [AVAssetResourceLoadingRequest]()
    
    // MARK: - Life Cycle Methods
    
    init(withURL url: URL) {
        self.url = url
        
        super.init()
    }
    
    // MARK: - Public Methods
    
    func invalidate() {
        self.loadingRequests.forEach { $0.finishLoading() }
        self.invalidateURLSession()
    }
    
    // MARK: - AVAssetResourceLoaderDelegate
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        if self.urlSession == nil {
            self.urlSession = self.createURLSession()
            let task = self.urlSession!.dataTask(with: self.url)
            task.resume()
        }
        
        self.loadingRequests.append(loadingRequest)
        
        return true
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, didCancel loadingRequest: AVAssetResourceLoadingRequest) {
        if let index = self.loadingRequests.firstIndex(of: loadingRequest) {
            self.loadingRequests.remove(at: index)
        }
    }
    
    // MARK: - URLSessionDataDelegate
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        self.infoResponse = response
        self.processRequests()
        
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.mediaData.append(data)
        self.processRequests()
    }
    
    // MARK: - Private Methods
    
    private func createURLSession() -> URLSession {
        let config = URLSessionConfiguration.default
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = 1
        return URLSession(configuration: config, delegate: self, delegateQueue: operationQueue)
    }
    
    private func invalidateURLSession() {
        self.urlSession?.invalidateAndCancel()
        self.urlSession = nil
    }
    
    private func isInfo(request: AVAssetResourceLoadingRequest) -> Bool {
        return request.contentInformationRequest != nil
    }

    private func fillInfoRequest(request: inout AVAssetResourceLoadingRequest, response: URLResponse) {
        request.contentInformationRequest?.isByteRangeAccessSupported = true
        request.contentInformationRequest?.contentType = response.mimeType
        request.contentInformationRequest?.contentLength = response.expectedContentLength
    }
    
    private func processRequests() {
        var finishedRequests = Set<AVAssetResourceLoadingRequest>()
        self.loadingRequests.forEach {
            var request = $0
            if self.isInfo(request: request), let response = self.infoResponse {
                self.fillInfoRequest(request: &request, response: response)
            }
            if let dataRequest = request.dataRequest, self.checkAndRespond(forRequest: dataRequest) {
                finishedRequests.insert(request)
                request.finishLoading()
            }
        }
        
        self.loadingRequests = self.loadingRequests.filter { !finishedRequests.contains($0) }
    }
    
    private func checkAndRespond(forRequest dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
        let downloadedData          = self.mediaData
        let downloadedDataLength    = Int64(downloadedData.count)
        
        let requestRequestedOffset  = dataRequest.requestedOffset
        let requestRequestedLength  = Int64(dataRequest.requestedLength)
        let requestCurrentOffset    = dataRequest.currentOffset
        
        if downloadedDataLength < requestCurrentOffset {
            return false
        }
        
        let downloadedUnreadDataLength  = downloadedDataLength - requestCurrentOffset
        let requestUnreadDataLength     = requestRequestedOffset + requestRequestedLength - requestCurrentOffset
        let respondDataLength           = min(requestUnreadDataLength, downloadedUnreadDataLength)

        dataRequest.respond(with: downloadedData.subdata(in: Range(NSMakeRange(Int(requestCurrentOffset), Int(respondDataLength)))!))
        
        let requestEndOffset = requestRequestedOffset + requestRequestedLength
        
        return requestCurrentOffset >= requestEndOffset
    }
}
