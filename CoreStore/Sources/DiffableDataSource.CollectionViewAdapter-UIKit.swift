//
//  DiffableDataSource.CollectionViewAdapter-UIKit.swift
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

#if canImport(UIKit) && (os(iOS) || os(tvOS))

import UIKit
import CoreData


// MARK: - DiffableDataSource

extension DiffableDataSource {

    // MARK: - CollectionView
    
    /**
     The `DiffableDataSource.CollectionViewAdapter` serves as a `UICollectionViewDataSource` that handles `ListPublisher` snapshots for a `UICollectionView`. Subclasses of `DiffableDataSource.CollectionViewAdapter` may override some `UICollectionViewDataSource` methods as needed.
     The `DiffableDataSource.CollectionViewAdapter` instance needs to be held on (retained) for as long as the `UICollectionView`'s lifecycle.
     ```
     self.dataSource = DiffableDataSource.CollectionViewAdapter<Person>(
         collectionView: self.collectionView,
         dataStack: CoreStoreDefaults.dataStack,
         cellProvider: { (collectionView, indexPath, person) in
             let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PersonCell") as! PersonCell
             cell.setPerson(person)
             return cell
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
    open class CollectionViewAdapter<O: DynamicObject>: BaseAdapter<O, DefaultCollectionViewTarget<UICollectionView>>, UICollectionViewDataSource {

        // MARK: Public
        
        /**
         Initializes the `DiffableDataSource.CollectionViewAdapter`. This instance needs to be held on (retained) for as long as the `UICollectionView`'s lifecycle.
         ```
         self.dataSource = DiffableDataSource.CollectionViewAdapter<Person>(
             collectionView: self.collectionView,
             dataStack: CoreStoreDefaults.dataStack,
             cellProvider: { (collectionView, indexPath, person) in
                 let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PersonCell") as! PersonCell
                 cell.setPerson(person)
                 return cell
             }
         )
         ```
         - parameter collectionView: the `UICollectionView` to set the `dataSource` of. This instance is not retained by the `DiffableDataSource.CollectionViewAdapter`.
         - parameter dataStack: the `DataStack` instance that the dataSource will fetch objects from
         - parameter cellProvider: a closure that configures and returns the `UICollectionViewCell` for the object
         - parameter supplementaryViewProvider: an optional closure for providing `UICollectionReusableView` supplementary views. If not set, defaults to returning `nil`
         */
        public init(
            collectionView: UICollectionView,
            dataStack: DataStack,
            cellProvider: @escaping (UICollectionView, IndexPath, O) -> UICollectionViewCell?,
            supplementaryViewProvider: @escaping (UICollectionView, String, IndexPath) -> UICollectionReusableView? = { _, _, _ in nil }
        ) {

            self.cellProvider = cellProvider
            self.supplementaryViewProvider = supplementaryViewProvider

            super.init(target: .init(collectionView), dataStack: dataStack)

            collectionView.dataSource = self
        }


        // MARK: - UICollectionViewDataSource

        @objc
        @MainActor
        public dynamic func numberOfSections(
            in collectionView: UICollectionView
        ) -> Int {

            return self.numberOfSections()
        }

        @objc
        @MainActor
        public dynamic func collectionView(
            _ collectionView: UICollectionView,
            numberOfItemsInSection section: Int
        ) -> Int {

            return self.numberOfItems(inSection: section) ?? 0
        }

        @objc
        @MainActor
        open dynamic func collectionView(
            _ collectionView: UICollectionView,
            cellForItemAt indexPath: IndexPath
        ) -> UICollectionViewCell {

            guard let objectID = self.itemID(for: indexPath) else {

                Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) already removed from list")
            }
            guard let object = self.dataStack.fetchExisting(objectID) as O? else {

                Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) has been deleted")
            }
            guard let cell = self.cellProvider(collectionView, indexPath, object) else {

                Internals.abort("\(Internals.typeName(UICollectionViewDataSource.self)) returned a `nil` cell for \(Internals.typeName(IndexPath.self)) \(indexPath)")
            }
            return cell
        }

        @objc
        @MainActor
        open dynamic func collectionView(
            _ collectionView: UICollectionView,
            viewForSupplementaryElementOfKind kind: String,
            at indexPath: IndexPath
        ) -> UICollectionReusableView {

            guard let view = self.supplementaryViewProvider(collectionView, kind, indexPath) else {

                return UICollectionReusableView()
            }
            return view
        }


        // MARK: Private

        private let cellProvider: (UICollectionView, IndexPath, O) -> UICollectionViewCell?
        private let supplementaryViewProvider: (UICollectionView, String, IndexPath) -> UICollectionReusableView?
    }


    // MARK: - DefaultCollectionViewTarget

    public struct DefaultCollectionViewTarget<T: UICollectionView>: Target {

        // MARK: Public

        public typealias Base = T

        public private(set) weak var base: Base?

        public init(_ base: Base) {

            self.base = base
        }


        // MARK: DiffableDataSource.Target

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

            self.base?.deleteItems(at: indexPaths)
        }

        public func insertItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.insertItems(at: indexPaths)
        }

        public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.reloadItems(at: indexPaths)
        }

        public func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, animated: Bool) {

            self.base?.moveItem(at: indexPath, to: newIndexPath)
        }

        public func performBatchUpdates(updates: () -> Void, animated: Bool, completion: @escaping () -> Void) {

            self.base?.performBatchUpdates(updates, completion: { _ in completion() })
        }

        public func reloadData() {

            self.base?.reloadData()
        }
    }
}

#endif
