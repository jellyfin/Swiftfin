//
//  Internals.FetchedDiffableDataSourceSnapshotDelegate.swift
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

#if canImport(UIKit)

import UIKit

#elseif canImport(AppKit)

import AppKit

#endif


// MARK: - FetchedDiffableDataSourceSnapshot

internal protocol FetchedDiffableDataSourceSnapshotHandler: AnyObject {

    var sectionIndexTransformer: (_ sectionName: KeyPathString?) -> String? { get }
    
    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChangeContentWith snapshot: Internals.DiffableDataSourceSnapshot
    )
}


// MARK: - Internal

extension Internals {

    // MARK: - FetchedDiffableDataSourceSnapshotDelegate

    internal final class FetchedDiffableDataSourceSnapshotDelegate: NSObject, NSFetchedResultsControllerDelegate {

        // MARK: Internal

        @nonobjc
        internal weak var handler: FetchedDiffableDataSourceSnapshotHandler?

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

        internal func initialFetch() {

            guard let fetchedResultsController = self.fetchedResultsController else {

                return
            }
            self.controllerDidChangeContent(fetchedResultsController.dynamicCast())
        }


        // MARK: NSFetchedResultsControllerDelegate
        
        @objc
        dynamic func controllerDidChangeContent(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>
        ) {

            var snapshot = Internals.DiffableDataSourceSnapshot(
                sections: controller.sections ?? [],
                sectionIndexTransformer: self.handler
                    .map({ $0.sectionIndexTransformer }) ?? { _ in nil },
                fetchOffset: controller.fetchRequest.fetchOffset,
                fetchLimit: controller.fetchRequest.fetchLimit
            )
            snapshot.reloadSections(self.reloadedSectionIDs)
            snapshot.reloadItems(self.reloadedItemIDs)
            
            self.handler?.controller(
                controller,
                didChangeContentWith: snapshot
            )
            self.reloadedItemIDs.removeAll()
            self.reloadedSectionIDs.removeAll()
        }

        @objc
        dynamic func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, sectionIndexTitleForSectionName sectionName: String) -> String? {

            return self.handler?.sectionIndexTransformer(sectionName)
        }
        
        @objc
        dynamic func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange anObject: Any,
            at indexPath: IndexPath?,
            for type: NSFetchedResultsChangeType,
            newIndexPath: IndexPath?
        ) {

            let object = anObject as! NSManagedObject
            self.reloadedItemIDs.append(object.objectID)
        }

        func controller(
            _ controller: NSFetchedResultsController<NSFetchRequestResult>,
            didChange sectionInfo: NSFetchedResultsSectionInfo,
            atSectionIndex sectionIndex: Int,
            for type: NSFetchedResultsChangeType
        ) {

            self.reloadedSectionIDs.append(sectionInfo.name)
        }
        
        
        // MARK: Private

        private var reloadedItemIDs: [NSManagedObjectID] = []
        private var reloadedSectionIDs: [String] = []
    }
}
