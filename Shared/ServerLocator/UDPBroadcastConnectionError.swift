//
//  UDPBroadcastConnectionError.swift
//  UDPBroadcast
//
//  Created by Gunter Hager on 25.03.19.
//  Copyright © 2019 Gunter Hager. All rights reserved.
//

import Foundation

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
