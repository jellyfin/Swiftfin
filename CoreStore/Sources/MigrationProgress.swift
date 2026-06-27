//
//  MigrationProgress.swift
//  CoreStore
//
//  Copyright © 2021 John Rommel Estropia
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

import CoreData
import Foundation


// MARK: - MigrationProgress

/**
 A `MigrationProgress` contains info on a `LocalStorage`'s setup progress.

 - SeeAlso: DataStack.reactive.addStorage(_:)
 - SeeAlso: DataStack.async.addStorage(_:)
 */
public enum MigrationProgress<T: LocalStorage> {

    /**
     The `LocalStorage` is currently being migrated
     */
    case migrating(storage: T, progressObject: Progress)

    /**
     The `LocalStorage` has been added to the `DataStack` and is ready for reading and writing
     */
    case finished(storage: T, migrationRequired: Bool)

    /**
     The fraction of the overall work completed by the migration. Returns a value between 0.0 and 1.0, inclusive.
     */
    public var fractionCompleted: Double {

        switch self {

        case .migrating(_, let progressObject):
            return progressObject.fractionCompleted

        case .finished:
            return 1
        }
    }

    /**
     Returns `true` if the storage was successfully added to the stack, `false` otherwise.
     */
    public var isCompleted: Bool {

        switch self {

        case .migrating:
            return false

        case .finished:
            return true
        }
    }
}
