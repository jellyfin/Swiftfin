//
//  DiffableDataSource.TableViewAdapter-UIKit.swift
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

    // MARK: - TableViewAdapter

    /**
     The `DiffableDataSource.TableViewAdapterAdapter` serves as a `UITableViewDataSource` that handles `ListPublisher` snapshots for a `UITableView`. Subclasses of `DiffableDataSource.TableViewAdapter` may override some `UITableViewDataSource` methods as needed.
     The `DiffableDataSource.TableViewAdapterAdapter` instance needs to be held on (retained) for as long as the `UITableView`'s lifecycle.
     ```
     self.dataSource = DiffableDataSource.TableViewAdapter<Person>(
         tableView: self.tableView,
         dataStack: CoreStoreDefaults.dataStack,
         cellProvider: { (tableView, indexPath, person) in
             let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
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
     `DiffableDataSource.TableViewAdapter` fully handles the reload animations.
     - SeeAlso: CoreStore's DiffableDataSource implementation is based on https://github.com/ra1028/DiffableDataSources
     */
    open class TableViewAdapter<O: DynamicObject>: BaseAdapter<O, DefaultTableViewTarget<UITableView>>, UITableViewDataSource {

        // MARK: Public

        /**
         Initializes the `DiffableDataSource.TableViewAdapter`. This instance needs to be held on (retained) for as long as the `UITableView`'s lifecycle.
         ```
         self.dataSource = DiffableDataSource.TableViewAdapter<Person>(
             tableView: self.tableView,
             dataStack: CoreStoreDefaults.dataStack,
             cellProvider: { (tableView, indexPath, person) in
                 let cell = tableView.dequeueReusableCell(withIdentifier: "PersonCell") as! PersonCell
                 cell.setPerson(person)
                 return cell
             }
         )
         ```
         - parameter tableView: the `UITableView` to set the `dataSource` of. This instance is not retained by the `DiffableDataSource.TableViewAdapter`.
         - parameter dataStack: the `DataStack` instance that the dataSource will fetch objects from
         - parameter cellProvider: a closure that configures and returns the `UITableViewCell` for the object
         */
        public init(
            tableView: UITableView,
            dataStack: DataStack,
            cellProvider: @escaping (UITableView, IndexPath, O) -> UITableViewCell?
        ) {

            self.cellProvider = cellProvider
            super.init(target: .init(tableView), dataStack: dataStack)

            tableView.dataSource = self
        }

        /**
         The target `UITableView`
         */
        public var tableView: UITableView? {

            return self.target.base
        }
        
        
        // MARK: - UITableViewDataSource

        @objc
        @MainActor
        public dynamic func numberOfSections(in tableView: UITableView) -> Int {
            
            return self.numberOfSections()
        }

        @objc
        @MainActor
        public dynamic func tableView(
            _ tableView: UITableView,
            numberOfRowsInSection section: Int
        ) -> Int {
            
            return self.numberOfItems(inSection: section) ?? 0
        }

        @objc
        @MainActor
        open dynamic func tableView(
            _ tableView: UITableView,
            titleForHeaderInSection section: Int
        ) -> String? {
            
            return self.sectionID(for: section)
        }

        @objc
        @MainActor
        open dynamic func tableView(
            _ tableView: UITableView,
            titleForFooterInSection section: Int
        ) -> String? {
            
            return nil
        }
        
        @objc
        @MainActor
        open dynamic func tableView(
            _ tableView: UITableView,
            cellForRowAt indexPath: IndexPath
        ) -> UITableViewCell {
            
            guard let objectID = self.itemID(for: indexPath) else {
                
                Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) already removed from list")
            }
            guard let object = self.dataStack.fetchExisting(objectID) as O? else {
                
                Internals.abort("Object at \(Internals.typeName(IndexPath.self)) \(indexPath) has been deleted")
            }
            guard let cell = self.cellProvider(tableView, indexPath, object) else {
                
                Internals.abort("\(Internals.typeName(UITableViewDataSource.self)) returned a `nil` cell for \(Internals.typeName(IndexPath.self)) \(indexPath)")
            }
            return cell
        }

        @objc
        @MainActor
        open dynamic func tableView(
            _ tableView: UITableView,
            canEditRowAt indexPath: IndexPath
        ) -> Bool {

            return true
        }

        @objc
        @MainActor
        open dynamic func tableView(
            _ tableView: UITableView,
            editingStyleForRowAt indexPath: IndexPath
        ) -> UITableViewCell.EditingStyle {

            return .delete
        }

        @objc
        @MainActor
        open dynamic func tableView(
            _ tableView: UITableView,
            commit editingStyle: UITableViewCell.EditingStyle,
            forRowAt indexPath: IndexPath
        ) {}
        
        @objc
        @MainActor
        open dynamic func sectionIndexTitles(
            for tableView: UITableView
        ) -> [String]? {
            
            return nil
        }
        
        @objc
        @MainActor 
        open dynamic func tableView(
            _ tableView: UITableView,
            sectionForSectionIndexTitle title: String,
            at index: Int
        ) -> Int {
            
            return index
        }


        // MARK: Private
        
        @nonobjc
        private let cellProvider: (UITableView, IndexPath, O) -> UITableViewCell?
    }


    // MARK: - DefaultTableViewTarget

    public struct DefaultTableViewTarget<T: UITableView>: Target {

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

            self.base?.deleteSections(indices, with: .automatic)
        }

        public func insertSections(at indices: IndexSet, animated: Bool) {

            self.base?.insertSections(indices, with: .automatic)
        }

        public func reloadSections(at indices: IndexSet, animated: Bool) {

            self.base?.reloadSections(indices, with: .automatic)
        }

        public func moveSection(at index: IndexSet.Element, to newIndex: IndexSet.Element, animated: Bool) {

            self.base?.moveSection(index, toSection: newIndex)
        }

        public func deleteItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.deleteRows(at: indexPaths, with: .automatic)
        }

        public func insertItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.insertRows(at: indexPaths, with: .automatic)
        }

        public func reloadItems(at indexPaths: [IndexPath], animated: Bool) {

            self.base?.reloadRows(at: indexPaths, with: .automatic)
        }

        public func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, animated: Bool) {

            self.base?.moveRow(at: indexPath, to: newIndexPath)
        }

        public func performBatchUpdates(updates: () -> Void, animated: Bool, completion: @escaping () -> Void) {

            guard let base = self.base else {

                return
            }
            base.performBatchUpdates(updates, completion: { _ in completion() })
        }

        public func reloadData() {

            self.base?.reloadData()
        }
    }
}

#endif
