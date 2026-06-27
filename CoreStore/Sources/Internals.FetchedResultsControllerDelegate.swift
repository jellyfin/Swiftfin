//
//  Internals.FetchedResultsControllerDelegate.swift
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

import Foundation
import CoreData


// MARK: - FetchedResultsControllerHandler

internal protocol FetchedResultsControllerHandler: AnyObject {
    
    var sectionIndexTransformer: (_ sectionName: KeyPathString?) -> String? { get }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeObject anObject: Any,
        atIndexPath indexPath: IndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    )
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType
    )
    
    func controllerWillChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    )
    
    func controllerDidChangeContent(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>
    )
}


// MARK: - Internal

extension Internals {

    // MARK: - FetchedResultsControllerDelegate

    internal final class FetchedResultsControllerDelegate: NSObject, NSFetchedResultsControllerDelegate {

        // MARK: Internal

        @nonobjc
        internal var enabled = true

        @nonobjc
        internal let taskGroup = DispatchGroup()

        @nonobjc
        internal weak var handler: FetchedResultsControllerHandler?

        @nonobjc
        internal weak var fetchedResultsController: Internals.CoreStoreFetchedResultsController? {

            didSet {

                oldValue?.delegate = nil
                self.fetchedResultsController?.delegate = self
            }
        }

        deinit {

            self.fetchedResultsController?.delegate = nil
        }


        // MARK: NSFetchedResultsControllerDelegate

        @objc
        dynamic func controllerWillChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {

            self.taskGroup.enter()
            guard self.enabled else {

                return
            }
            self.handler?.controllerWillChangeContent(controller)
        }

        @objc
        dynamic func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {

            defer {

                self.taskGroup.leave()
            }
            guard self.enabled else {

                return
            }
            self.handler?.controllerDidChangeContent(controller)
        }

        @objc
        dynamic func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any,
            at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType,
            newIndexPath: IndexPath?
        ) {

            guard self.enabled else {

                return
            }
            self.handler?.controller(
                controller,
                didChangeObject: anObject,
                atIndexPath: indexPath,
                forChangeType: type,
                newIndexPath: newIndexPath
            )
        }

        @objc
        dynamic func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange sectionInfo: NSFetchedResultsSectionInfo,
            atSectionIndex sectionIndex: Int,
            for type: NSFetchedResultsChangeType
        ) {

            guard self.enabled else {

                return
            }
            self.handler?.controller(
                controller,
                didChangeSection: sectionInfo,
                atIndex: sectionIndex,
                forChangeType: type
            )
        }

        @objc
        dynamic func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {

            return self.handler?.sectionIndexTransformer(sectionName)
        }
    }
}
