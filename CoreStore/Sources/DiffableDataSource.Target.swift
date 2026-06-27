//
//  DiffableDataSource.Target.swift
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


// MARK: - DiffableDataSourc

extension DiffableDataSource {

    // MARK: - Target

    /**
     The `DiffableDataSource.Target` protocol allows custom views to consume `ListSnapshot` diffable data similar to how `DiffableDataSource.TableViewAdapter` and `DiffableDataSource.CollectionViewAdapter` reloads data for their corresponding views.
     */
    public typealias Target = DiffableDataSourceTarget
}


// MARK: - DiffableDataSource.Target

/**
 The `DiffableDataSource.Target` protocol allows custom views to consume `ListSnapshot` diffable data similar to how `DiffableDataSource.TableViewAdapter` and `DiffableDataSource.CollectionViewAdapter` reloads data for their corresponding views.
 */
public protocol DiffableDataSourceTarget {

    // MARK: Public

    /**
     Whether `reloadData()` should be executed instead of `performBatchUpdates(updates:animated:)`.
     */
    var shouldSuspendBatchUpdates: Bool { get }

    /**
     Deletes one or more sections.
     */
    func deleteSections(at indices: IndexSet, animated: Bool)

    /**
     Inserts one or more sections
     */
    func insertSections(at indices: IndexSet, animated: Bool)

    /**
     Reloads the specified sections.
     */
    func reloadSections(at indices: IndexSet, animated: Bool)

    /**
     Moves a section to a new location.
     */
    func moveSection(at index: IndexSet.Element, to newIndex: IndexSet.Element, animated: Bool)

    /**
     Deletes the items specified by an array of index paths.
     */
    func deleteItems(at indexPaths: [IndexPath], animated: Bool)

    /**
     Inserts items at the locations identified by an array of index paths.
     */
    func insertItems(at indexPaths: [IndexPath], animated: Bool)

    /**
     Reloads the specified items.
     */
    func reloadItems(at indexPaths: [IndexPath], animated: Bool)

    /**
     Moves the item at a specified location to a destination location.
     */
    func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, animated: Bool)

    /**
     Animates multiple insert, delete, reload, and move operations as a group.
     */
    func performBatchUpdates(updates: () -> Void, animated: Bool, completion: @escaping () -> Void)

    /**
     Reloads all sections and items.
     */
    func reloadData()
}

extension DiffableDataSource.Target {

    // MARK: Internal

    internal func reload<C, O>(
        using stagedChangeset: Internals.DiffableDataUIDispatcher<O>.StagedChangeset<C>,
        animated: Bool,
        interrupt: ((Internals.DiffableDataUIDispatcher<O>.Changeset<C>) -> Bool)? = nil,
        setData: (C) -> Void,
        completion: @escaping () -> Void
    ) {

        let group = DispatchGroup()
        defer {

            group.notify(queue: .main, execute: completion)
        }
        if self.shouldSuspendBatchUpdates, let data = stagedChangeset.last?.data {

            setData(data)
            self.reloadData()
            return
        }
        for changeset in stagedChangeset {

            if let interrupt = interrupt,
                interrupt(changeset),
                let data = stagedChangeset.last?.data {

                setData(data)
                self.reloadData()
                return
            }
            group.enter()
            self.performBatchUpdates(
                updates: {

                    setData(changeset.data)

                    if !changeset.sectionDeleted.isEmpty {

                        self.deleteSections(
                            at: IndexSet(changeset.sectionDeleted),
                            animated: animated
                        )
                    }
                    if !changeset.sectionInserted.isEmpty {

                        self.insertSections(
                            at: IndexSet(changeset.sectionInserted),
                            animated: animated
                        )
                    }
                    if !changeset.sectionUpdated.isEmpty {

                        self.reloadSections(
                            at: IndexSet(changeset.sectionUpdated),
                            animated: animated
                        )
                    }
                    for (source, target) in changeset.sectionMoved {

                        self.moveSection(
                            at: source,
                            to: target,
                            animated: animated
                        )
                    }
                    if !changeset.elementDeleted.isEmpty {

                        self.deleteItems(
                            at: changeset.elementDeleted.map {

                                IndexPath(item: $0.element, section: $0.section)
                            },
                            animated: animated
                        )
                    }
                    if !changeset.elementInserted.isEmpty {

                        self.insertItems(
                            at: changeset.elementInserted.map {

                                IndexPath(item: $0.element, section: $0.section)
                            },
                            animated: animated
                        )
                    }
                    if !changeset.elementUpdated.isEmpty {

                        self.reloadItems(
                            at: changeset.elementUpdated.map {

                                IndexPath(item: $0.element, section: $0.section)
                            },
                            animated: animated
                        )
                    }
                    for (source, target) in changeset.elementMoved {

                        self.moveItem(
                            at: IndexPath(item: source.element, section: source.section),
                            to: IndexPath(item: target.element, section: target.section),
                            animated: animated
                        )
                    }
                },
                animated: animated,
                completion: group.leave
            )
        }
    }
}

#endif
