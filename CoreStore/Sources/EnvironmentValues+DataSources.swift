//
//  EnvironmentValues+DataSources.swift
//  CoreStore
//
//  Copyright © 2018 John Rommel Estropia
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#if canImport(SwiftUI) && canImport(Combine)

import SwiftUI
import Combine

import CoreData


// MARK: - EnvironmentValues

extension EnvironmentValues {

    // MARK: Public

    /**
     The `DataStack` instance injected to `self`:
     ```
     @Environment(\.dataStack)
     var dataStack: DataStack
     ```
     */
    public var dataStack: DataStack {
        
        get {
            
            return self[DataStackKey.self]
        }
        set {
            
            self[DataStackKey.self] = newValue
        }
    }


    // MARK: - DataStackEnvironmentKey

    fileprivate struct DataStackKey: EnvironmentKey {

        // MARK: FilePrivate
        
        fileprivate static var defaultValue: DataStack {
            
            return CoreStoreDefaults.dataStack
        }
    }
}

#endif
