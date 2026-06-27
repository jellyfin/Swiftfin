//
//  DiffableDataSource.BaseAdapter.swift
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

#if canImport(UIKit) || canImport(AppKit)

import Foundation
import CoreData


// MARK: - DiffableDataSource

extension DiffableDataSource {

    // MARK: - BaseAdapter

    /**
     The `DiffableDataSource.BaseAdapter` serves as a superclass for consumers of `ListPublisher` and `ListSnapshot` diffable data.
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
     - SeeAlso: CoreStore's DiffableDataSource implementation is based on https://github.com/ra1028/DiffableDataSources
     */
    open class BaseAdapter<O: DynamicObject, T: Target>: NSObject {

        // MARK: Public

        /**
         The object type represented by this dataSource
         */
        public typealias ObjectType = O

        /**
         The target to be updated by this dataSource
         */
        public let target: T

        /**
         The `DataStack` where object fetches are performed
         */
        public let dataStack: DataStack

        /**
         Initializes the `DiffableDataSource.BaseAdapter` object. This instance needs to be held on (retained) for as long as the target's lifecycle.
         ```
         self.dataSource = DiffableDataSource.TableViewAdapterAdapter<Person>(
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
        public init(target: T, dataStack: DataStack) {

            self.target = target
            self.dataStack = dataStack
            self.dispatcher = Internals.DiffableDataUIDispatcher<O>(dataStack: dataStack)
        }

        /**
         Clears the target.
         - parameter animatingDifferences: if `true`, animations may be applied accordingly. Defaults to `true`.
         */
        open func purge(animatingDifferences: Bool = true, completion: @escaping () -> Void = {}) {

            self.dispatcher.purge(
                target: self.target,
                animatingDifferences: animatingDifferences,
                performUpdates: { target, changeset, setSections in

                    target.reload(
                        using: changeset,
                        animated: animatingDifferences,
                        setData: setSections,
                        completion: completion
                    )
                }
            )
        }

        /**
         Reloads the target using a `ListSnapshot`. This is typically from the `snapshot` property of a `ListPublisher`:
         ```
         listPublisher.addObserver(self) { [weak self] (listPublisher) in
            self?.dataSource?.apply(
                listPublisher.snapshot,
                animatingDifferences: true
            )
         }
         ``
         - parameter snapshot: the `ListSnapshot` used to reload the target with. This is typically from the `snapshot` property of a `ListPublisher`.
         - parameter animatingDifferences: if `true`, animations may be applied accordingly. Defaults to `true`.
         */
        open func apply(_ snapshot: ListSnapshot<O>, animatingDifferences: Bool = true, completion: @escaping () -> Void = {}) {

            let diffableSnapshot = snapshot.diffableSnapshot
            self.dispatcher.apply(
                diffableSnapshot,
                target: self.target,
                animatingDifferences: animatingDifferences,
                performUpdates: { target, changeset, setSections in

                    target.reload(
                        using: changeset,
                        animated: animatingDifferences,
                        setData: setSections,
                        completion: completion
                    )
                }
            )
        }
        
        /**
         Creates a new empty `ListSnapshot` suitable for building custom lists inside subclass implementations of `apply(_:animatingDifferences:completion:)`.
         */
        public func makeEmptySnapshot() -> ListSnapshot<O> {
            
            return .init(
                diffableSnapshot: .init(),
                context: self.dataStack.unsafeContext()
            )
        }

        /**
         Returns the number of sections

         - parameter indexPath: the `IndexPath` to search for
         - returns: the number of sections
         */
        public func numberOfSections() -> Int {

            return self.dispatcher.numberOfSections()
        }

        /**
         Returns the number of items at the specified section, or `nil` if the section is not found

         - parameter section: the section index to search for
         - returns: the number of items at the specified section, or `nil` if the section is not found
         */
        public func numberOfItems(inSection section: Int) -> Int? {

            return self.dispatcher.numberOfItems(inSection: section)
        }

        /**
         Returns the section identifier at the specified index, or `nil` if not found

         - parameter section: the section index to search for
         - returns: the section identifier at the specified indec, or `nil` if not found
         */
        public func sectionID(for section: Int) -> String? {

            return self.dispatcher.sectionIdentifier(inSection: section)
        }

        /**
         Returns the object identifier for the item at the specified `IndexPath`, or `nil` if not found

         - parameter indexPath: the `IndexPath` to search for
         - returns: the object identifier for the item at the specified `IndexPath`, or `nil` if not found
         */
        public func itemID(for indexPath: IndexPath) -> O.ObjectID? {

            return self.dispatcher.itemIdentifier(for: indexPath)
        }

        /**
         Returns the `IndexPath` for the item with the specified object identifier, or `nil` if not found

         - parameter itemID: the object identifier to search for
         - returns: the `IndexPath` for the item with the specified object identifier, or `nil` if not found
         */
        public func indexPath(for itemID: O.ObjectID) -> IndexPath? {

            return self.dispatcher.indexPath(for: itemID)
        }
        
        /**
         Returns the section index title for the specified `section` if the `SectionBy` for this list has provided a `sectionIndexTransformer`
         
         - parameter section: the section index to search for
         - returns: the section index title for the specified `section`, or `nil` if not found
         */
        public func sectionIndexTitle(for section: Int) -> String? {
            
            return self.dispatcher.sectionIndexTitle(for: section)
        }
        
        /**
         Returns the section index titles for all sections if the `SectionBy` for this list has provided a `sectionIndexTransformer`
         */
        public func sectionIndexTitlesForAllSections() -> [String?] {
            
            return self.dispatcher.sectionIndexTitlesForAllSections()
        }


        // MARK: Internal

        internal let dispatcher: Internals.DiffableDataUIDispatcher<O>
    }
}

#endif
