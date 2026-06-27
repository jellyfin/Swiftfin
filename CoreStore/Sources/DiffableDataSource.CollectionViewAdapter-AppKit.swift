//
//  DiffableDataSource.CollectionViewAdapter-AppKit.swift
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

#if canImport(AppKit) && os(macOS)

import AppKit
import CoreData


// MARK: - DiffableDataSource

extension DiffableDataSource {

    // MARK: - CollectionView
    
    /**
     The `DiffableDataSource.CollectionViewAdapter` serves as a `NSCollectionViewDataSource` that handles `ListPublisher` snapshots for a `NSCollectionView`. Subclasses of `DiffableDataSource.CollectionViewAdapter` may override some `NSCollectionViewDataSource` methods as needed.
     The `DiffableDataSource.CollectionViewAdapter` instance needs to be held on (retained) for as long as the `NSCollectionView`'s lifecycle.
     ```
     self.dataSource = DiffableDataSource.CollectionViewAdapter<Person>(
         collectionView: self.collectionView,
         dataStack: CoreStoreDefaults.dataStack,
         itemProvider: { (collectionView, indexPath, person) in
             let item = collectionView.makeItem(withIdentifier: .collectionViewItem, for: indexPath) as! PersonItem
             item.setPerson(person)
             return item
         }
     )
     ```
     The dataSource can then apply changes from a `ListPublisher` as shown:
     ```
     listPublisher.addObserver(self) { [weak self] (listPublisher) in
        self?.dataSource?.apply(
            listPublisher.snapshot,
            animatingDifferences: true
        )
     }
     ```
     `DiffableDataSource.CollectionViewAdapter` fully handles the reload animations.
     - SeeAlso: CoreStore's DiffableDataSource implementation is based on https://github.com/ra1028/DiffableDataSources     
     */
    open class CollectionViewAdapter<O: DynamicObject>: BaseAdapter<O, DefaultCollectionViewTarget<NSCollectionView>>, NSCollectionViewDataSource {

        // MARK: Public
        
        /**
         Initializes the `DiffableDataSource.CollectionViewAdapter`. This instance needs to be held on (retained) for as long as the `NSCollectionView`'s lifecycle.
         ```
         self.dataSource = DiffableDataSource.CollectionViewAdapter<Person>(
             collectionView: self.collectionView,
             dataStack: CoreStoreDefaults.dataStack,
             itemProvider: { (collectionView, indexPath, person) in
                 let item = collectionView.makeItem(withIdentifier: .collectionViewItem, for: indexPath) as! PersonItem
                 item.setPerson(person)
                 return item
             }
         )
         ```
         - parameter collectionView: the `NSCollectionView` to set the `dataSource` of. This instance is not retained by the `DiffableDataSource.CollectionViewAdapter`.
         - parameter dataStack: the `DataStack` instance that the dataSource will fetch objects from
         - parameter itemProvider: a closure that configures and returns the `NSCollectionViewItem` for the object
         */
        @nonobjc
        public init(
            collectionView: NSCollectionView,
            dataStack: DataStack,
            itemProvider: @escaping (NSCollectionView, IndexPath, O) -> NSCollectionViewItem?,
            supplementaryViewProvider: @escaping (NSCollectionView, String, IndexPath) -> NSView? = { _, _, _ in nil }
        ) {

            self.itemProvider = itemProvider
            self.supplementaryViewProvider = supplementaryViewProvider

            super.init(target: .init(collectionView), dataStack: dataStack)

            collectionView.dataSource = self
        }


        // MARK: - NSCollectionViewDataSource

        @objc
        public dynamic func numberOfSections(
            in collectionView: NSCollectionView
        ) -> Int {

            return self.numberOfSections()
        }

        @objc
        public dynamic func collectionView(
            _ collectionView: NSCollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {

            return self.numberOfItems(inSection: section) ?? 0
        }

        @objc
        open dynamic func collectionView(
            _ collectionView: NSCollectionView,
            itemForRepresentedObjectAt indexPath: IndexPath
        ) -> NSCollectionViewItem {

            guard let objectID = self.itemID(for: indexPath) else {

                Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) already removed from list")
            }
            guard let object = self.dataStack.fetchExisting(objectID) as O? else {

                Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) has been deleted")
            }
            guard let item = self.itemProvider(collectionView, indexPath, object) else {

                Internals.abort("\(Internals.typeName(NSCollectionViewDataSource.self)) returned a `nil` item for \(Internals.typeName(IndexPath.self)) \(indexPath)")
            }
            return item
        }

        @objc
        open dynamic func collectionView(
            _ collectionView: NSCollectionView,
            viewForSupplementaryElementOfKind kind: NSCollectionView.SupplementaryElementKind,
            at indexPath: IndexPath
        ) -> NSView {

            guard let view = self.supplementaryViewProvider(collectionView, kind, indexPath) else {

                return NSView()
            }
            return view
        }


        // MARK: Private

        private let itemProvider: (NSCollectionView, IndexPath, O) -> NSCollectionViewItem?
        private let supplementaryViewProvider: (NSCollectionView, String, IndexPath) -> NSView?
    }


    // MARK: - DefaultCollectionViewTarget

    public struct DefaultCollectionViewTarget<T: NSCollectionView>: Target {

        // MARK: Public

        public typealias Base = T

        public private(set) weak var base: Base?

        public init(_ base: Base) {

            self.base = base
        }


        // MARK: DiffableDataSource.Target:

        public var shouldSuspendBatchUpdates: Bool {

            return self.base?.window == nil
        }

        public func deleteSections(at indices: IndexSet, animated: Bool) {

            self.base?.deleteSections(indices)
        }

        public func insertSections(at indices: IndexSet, animated: Bool) {

            self.base?.insertSections(indices)
        }

        public func reloadSections(at indices: IndexSet, animated: Bool) {

            self.base?.reloadSections(indices)
        }

        public func moveSection(at index: IndexSet.Element, to newIndex: IndexSet.Element, animated: Bool) {

            self.base?.moveSection(index, toSection: newIndex)
        }

        public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.deleteItems(at: Set(indexPaths))
        }

        public func insertItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.insertItems(at: Set(indexPaths))
        }

        public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.reloadItems(at: Set(indexPaths))
        }

        public func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, animated: Bool) {

            self.base?.moveItem(at: indexPath, to: newIndexPath)
        }

        public func performBatchUpdates(updates: () -> Void, animated: Bool, completion: @escaping () -> Void) {

            self.base?.animator().performBatchUpdates(updates, completionHandler: { _ in completion() })
        }

        public func reloadData() {

            self.base?.reloadData()
        }
    }
}


#endif
