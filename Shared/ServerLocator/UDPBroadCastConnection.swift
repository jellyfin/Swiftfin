//
//  UDPBroadcastConnection.swift
//  UDPBroadcast
//
//  Created by Gunter Hager on 10.02.16.
//  Copyright © 2016 Gunter Hager. All rights reserved.
//

import Foundation
import Darwin

// Addresses

let INADDR_ANY = in_addr(s_addr: 0)
let INADDR_BROADCAST = in_addr(s_addr: 0xffffffff)


/// An object representing the UDP broadcast connection. Uses a dispatch source to handle the incoming traffic on the UDP socket.
open class UDPBroadcastConnection {
    
    // MARK: Properties
    
    /// The address of the UDP socket.
    var address: sockaddr_in
    
    /// Type of a closure that handles incoming UDP packets.
    public typealias ReceiveHandler = (_ ipAddress: String, _ port: Int, _ response: Data) -> Void
    /// Closure that handles incoming UDP packets.
    var handler: ReceiveHandler?
    
    /// Type of a closure that handles errors that were encountered during receiving UDP packets.
    public typealias ErrorHandler = (_ error: ConnectionError) -> Void
    /// Closure that handles errors that were encountered during receiving UDP packets.
    var errorHandler: ErrorHandler?
    
    /// A dispatch source for reading data from the UDP socket.
    var responseSource: DispatchSourceRead?
    
    /// The dispatch queue to run responseSource & reconnection on
    var dispatchQueue: DispatchQueue = DispatchQueue.main
    
    /// Bind to port to start listening without first sending a message
    var shouldBeBound: Bool = false
    
    // MARK: Initializers
    
    /// Initializes the UDP connection with the correct port address.
    
    /// - Note: This doesn't open a socket! The socket is opened transparently as needed when sending broadcast messages. If you want to open a socket immediately, use the `bindIt` parameter. This will also try to reopen the socket if it gets closed.
    ///
    /// - Parameters:
    ///   - port: Number of the UDP port to use.
    ///   - bindIt: Opens a port immediately if true, on demand if false. Default is false.
    ///   - handler: Handler that gets called when data is received.
    ///   - errorHandler: Handler that gets called when an error occurs.
    /// - Throws: Throws a `ConnectionError` if an error occurs.
    public init(port: UInt16, bindIt: Bool = false, handler: ReceiveHandler?, errorHandler: ErrorHandler?) throws {
        self.address = sockaddr_in(
            sin_len:    __uint8_t(MemoryLayout<sockaddr_in>.size),
            sin_family: sa_family_t(AF_INET),
            sin_port:   UDPBroadcastConnection.htonsPort(port: port),
            sin_addr:   INADDR_BROADCAST,
            sin_zero:   ( 0, 0, 0, 0, 0, 0, 0, 0 )
        )
        
        self.handler = handler
        self.errorHandler = errorHandler
        self.shouldBeBound = bindIt
        if bindIt {
            try createSocket()
        }
    }
    
    deinit {
        if responseSource != nil {
            responseSource!.cancel()
        }
    }
    
    // MARK: Interface
    
    
    /// Create a UDP socket for broadcasting and set up cancel and event handlers
    ///
    /// - Throws: Throws a `ConnectionError` if an error occurs.
    fileprivate func createSocket() throws {
        
        // Create new socket
        let newSocket = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard newSocket > 0 else { throw ConnectionError.createSocketFailed }
        
        // Enable broadcast on socket
        var broadcastEnable = Int32(1);
        let ret = setsockopt(newSocket, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, socklen_t(MemoryLayout<UInt32>.size));
        if ret == -1 {
            debugPrint("Couldn't enable broadcast on socket")
            close(newSocket)
            throw ConnectionError.enableBroadcastFailed
        }
        
        // Bind socket if needed
        if shouldBeBound {
            var saddr = sockaddr(sa_len: 0, sa_family: 0,
                                 sa_data: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0))
            self.address.sin_addr = INADDR_ANY
            memcpy(&saddr, &self.address, MemoryLayout<sockaddr_in>.size)
            self.address.sin_addr = INADDR_BROADCAST
            let isBound = bind(newSocket, &saddr, socklen_t(MemoryLayout<sockaddr_in>.size))
            if isBound == -1 {
                debugPrint("Couldn't bind socket")
                close(newSocket)
                throw ConnectionError.bindSocketFailed
            }
        }
        
        // Disable global SIGPIPE handler so that the app doesn't crash
        setNoSigPipe(socket: newSocket)
        
        // Set up a dispatch source
        let newResponseSource = DispatchSource.makeReadSource(fileDescriptor: newSocket, queue: dispatchQueue)
        
        // Set up cancel handler
        newResponseSource.setCancelHandler {
            debugPrint("Closing UDP socket")
            let UDPSocket = Int32(newResponseSource.handle)
            shutdown(UDPSocket, SHUT_RDWR)
            close(UDPSocket)
        }
        
        // Set up event handler (gets called when data arrives at the UDP socket)
        newResponseSource.setEventHandler { [unowned self] in
            guard let source = self.responseSource else { return }
            
            var socketAddress = sockaddr_storage()
            var socketAddressLength = socklen_t(MemoryLayout<sockaddr_storage>.size)
            let response = [UInt8](repeating: 0, count: 4096)
            let UDPSocket = Int32(source.handle)
            
            let bytesRead = withUnsafeMutablePointer(to: &socketAddress) {
                recvfrom(UDPSocket, UnsafeMutableRawPointer(mutating: response), response.count, 0, UnsafeMutableRawPointer($0).bindMemory(to: sockaddr.self, capacity: 1), &socketAddressLength)
            }
            
            do {
                guard bytesRead > 0 else {
                    self.closeConnection()
                    if bytesRead == 0 {
                        debugPrint("recvfrom returned EOF")
                        throw ConnectionError.receivedEndOfFile
                    } else {
                        if let errorString = String(validatingUTF8: strerror(errno)) {
                            debugPrint("recvfrom failed: \(errorString)")
                        }
                        throw ConnectionError.receiveFailed(code: errno)
                    }
                }
                
                guard let endpoint = withUnsafePointer(to: &socketAddress, { self.getEndpointFromSocketAddress(socketAddressPointer: UnsafeRawPointer($0).bindMemory(to: sockaddr.self, capacity: 1)) })
                else {
                    debugPrint("Failed to get the address and port from the socket address received from recvfrom")
                    self.closeConnection()
                    return
                }
                
                debugPrint("UDP connection received \(bytesRead) bytes from \(endpoint.host):\(endpoint.port)")
                
                let responseBytes = Data(response[0..<bytesRead])
                
                // Handle response
                self.handler?(endpoint.host, endpoint.port, responseBytes)
            } catch {
                if let error = error as? ConnectionError {
                    self.errorHandler?(error)
                } else {
                    self.errorHandler?(ConnectionError.underlying(error: error))
                }
            }
            
        }
        
        newResponseSource.resume()
        responseSource = newResponseSource
    }
    
    /// Send broadcast message.
    ///
    /// - Parameter message: Message to send via broadcast.
    /// - Throws: Throws a `ConnectionError` if an error occurs.
    open func sendBroadcast(_ message: String) throws {
        guard let data = message.data(using: .utf8) else { throw ConnectionError.messageEncodingFailed }
        try sendBroadcast(data)
    }
    
    /// Send broadcast data.
    ///
    /// - Parameter data: Data to send via broadcast.
    /// - Throws: Throws a `ConnectionError` if an error occurs.
    open func sendBroadcast(_ data: Data) throws {
        if responseSource == nil {
            try createSocket()
        }
        
        guard let source = responseSource else { return }
        let UDPSocket = Int32(source.handle)
        let socketLength = socklen_t(address.sin_len)
        try data.withUnsafeBytes { (broadcastMessage) in
            let broadcastMessageLength = data.count
            let sent = withUnsafeMutablePointer(to: &address) { pointer -> Int in
                let memory = UnsafeRawPointer(pointer).bindMemory(to: sockaddr.self, capacity: 1)
                return sendto(UDPSocket, broadcastMessage.baseAddress, broadcastMessageLength, 0, memory, socketLength)
            }
            
            guard sent > 0 else {
                if let errorString = String(validatingUTF8: strerror(errno)) {
                    debugPrint("UDP connection failed to send data: \(errorString)")
                }
                closeConnection()
                throw ConnectionError.sendingMessageFailed(code: errno)
            }
            
            if sent == broadcastMessageLength {
                // Success
                debugPrint("UDP connection sent \(broadcastMessageLength) bytes")
            }
        }
    }
    
    /// Close the connection.
    ///
    /// - Parameter reopen: Automatically reopens the connection if true. Defaults to true.
    open func closeConnection(reopen: Bool = true) {
        if let source = responseSource {
            source.cancel()
            responseSource = nil
        }
        if shouldBeBound && reopen {
            dispatchQueue.async {
                do {
                    try self.createSocket()
                } catch {
                    self.errorHandler?(ConnectionError.reopeningSocketFailed(error: error))
                }
            }
        }
    }
    
    // MARK: - Helper
    
    /// Convert a sockaddr structure into an IP address string and port.
    ///
    /// - Parameter socketAddressPointer: socketAddressPointer: Pointer to a socket address.
    /// - Returns: Returns a tuple of the host IP address and the port in the socket address given.
    func getEndpointFromSocketAddress(socketAddressPointer: UnsafePointer<sockaddr>) -> (host: String, port: Int)? {
        let socketAddress = UnsafePointer<sockaddr>(socketAddressPointer).pointee
        
        switch Int32(socketAddress.sa_family) {
            case AF_INET:
                var socketAddressInet = UnsafeRawPointer(socketAddressPointer).load(as: sockaddr_in.self)
                let length = Int(INET_ADDRSTRLEN) + 2
                var buffer = [CChar](repeating: 0, count: length)
                let hostCString = inet_ntop(AF_INET, &socketAddressInet.sin_addr, &buffer, socklen_t(length))
                let port = Int(UInt16(socketAddressInet.sin_port).byteSwapped)
                return (String(cString: hostCString!), port)
                
            case AF_INET6:
                var socketAddressInet6 = UnsafeRawPointer(socketAddressPointer).load(as: sockaddr_in6.self)
                let length = Int(INET6_ADDRSTRLEN) + 2
                var buffer = [CChar](repeating: 0, count: length)
                let hostCString = inet_ntop(AF_INET6, &socketAddressInet6.sin6_addr, &buffer, socklen_t(length))
                let port = Int(UInt16(socketAddressInet6.sin6_port).byteSwapped)
                return (String(cString: hostCString!), port)
                
            default:
                return nil
        }
    }
    
    
    // MARK: - Private
    
    /// Prevents crashes when blocking calls are pending and the app is paused (via Home button).
    ///
    /// - Parameter socket: The socket for which the signal should be disabled.
    fileprivate func setNoSigPipe(socket: CInt) {
        var no_sig_pipe: Int32 = 1;
        setsockopt(socket, SOL_SOCKET, SO_NOSIGPIPE, &no_sig_pipe, socklen_t(MemoryLayout<Int32>.size));
    }
    
    fileprivate class func htonsPort(port: in_port_t) -> in_port_t {
        let isLittleEndian = Int(OSHostByteOrder()) == OSLittleEndian
        return isLittleEndian ? _OSSwapInt16(port) : port
    }
    
    fileprivate class func ntohs(value: CUnsignedShort) -> CUnsignedShort {
        return (value << 8) + (value >> 8)
    }
    
}



//  Created by Gunter Hager on 25.03.19.
//  Copyright © 2019 Gunter Hager. All rights reserved.
//
public extension UDPBroadcastConnection {
    
    enum ConnectionError: Error {
        // Creating socket
        case createSocketFailed
        case enableBroadcastFailed
        case bindSocketFailed
        
        // Sending message
        case messageEncodingFailed
        case sendingMessageFailed(code: Int32)
        
        // Receiving data
        case receivedEndOfFile
        case receiveFailed(code: Int32)
        
        // Closing socket
        case reopeningSocketFailed(error: Error)
        
        // Underlying
        case underlying(error: Error)
    }
    
}
