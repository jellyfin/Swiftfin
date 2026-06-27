//
//  Internals.DiffableDataUIDispatcher.swift
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

import CoreData

#if canImport(QuartzCore)
import QuartzCore

#endif


// MARK: - Internals

extension Internals {

    // MARK: Internal

    // Implementation based on https://github.com/ra1028/DiffableDataSources
    @usableFromInline
    internal final class DiffableDataUIDispatcher<O: DynamicObject> {

        // MARK: Internal
        
        typealias ObjectType = O
        
        init(dataStack: DataStack) {
            
            self.dataStack = dataStack
        }

        func purge<Target: DiffableDataSource.Target>(
            target: Target?,
            animatingDifferences: Bool,
            performUpdates: @escaping (
                Target,
                StagedChangeset<[Internals.DiffableDataSourceSnapshot.Section]>,
                @escaping ([Internals.DiffableDataSourceSnapshot.Section]) -> Void
            ) -> Void
        ) {

            self.apply(
                .init(),
                target: target,
                animatingDifferences: animatingDifferences,
                performUpdates: performUpdates
            )
        }
        
        func apply<Target: DiffableDataSource.Target>(
            _ snapshot: DiffableDataSourceSnapshot,
            target: Target?,
            animatingDifferences: Bool,
            performUpdates: @escaping (
                Target,
                StagedChangeset<[Internals.DiffableDataSourceSnapshot.Section]>,
                @escaping ([Internals.DiffableDataSourceSnapshot.Section]) -> Void
            ) -> Void
        ) {
            
            self.dispatcher.dispatch { [weak self] in
                
                guard let self = self else {
                    
                    return
                }

                self.currentSnapshot = snapshot

                let newSections = snapshot.sections
                guard let target = target else {
                    
                    self.sections = newSections
                    return
                }

                let performDiffingUpdates: () -> Void = {
                    
                    let changeset = StagedChangeset(source: self.sections, target: newSections)
                    performUpdates(target, changeset) { sections in
                        
                        self.sections = sections
                    }
                }

#if os(watchOS) || !canImport(QuartzCore)

                performDiffingUpdates()

#else

                CATransaction.begin()
                
                if !animatingDifferences {
                    
                    CATransaction.setDisableActions(true)
                }
                performDiffingUpdates()
                
                CATransaction.commit()

#endif
            }
        }

        func snapshot() -> DiffableDataSourceSnapshot {
            
            var snapshot: DiffableDataSourceSnapshot = .init()
            snapshot.sections = self.currentSnapshot.sections
            return snapshot
        }

        func sectionIdentifier(inSection section: Int) -> String? {

            guard self.sections.indices.contains(section) else {

                return nil
            }
            return self.sections[section].differenceIdentifier
        }

        func itemIdentifier(for indexPath: IndexPath) -> O.ObjectID? {

            guard self.sections.indices.contains(indexPath.section) else {
                
                return nil
            }
            let items = self.sections[indexPath.section].elements
            guard items.indices.contains(indexPath.item) else {
                
                return nil
            }
            return items[indexPath.item].differenceIdentifier
        }

        func indexPath(for itemIdentifier: O.ObjectID) -> IndexPath? {
            
            let indexPathMap: [O.ObjectID: IndexPath] = self.sections.enumerated().reduce(into: [:]) { result, section in
                
                for (itemIndex, item) in section.element.elements.enumerated() {
                    
                    result[item.differenceIdentifier] = IndexPath(
                        item: itemIndex,
                        section: section.offset
                    )
                }
            }
            return indexPathMap[itemIdentifier]
        }

        func numberOfSections() -> Int {
            
            return self.sections.count
        }

        func numberOfItems(inSection section: Int) -> Int? {

            guard self.sections.indices.contains(section) else {

                return nil
            }
            return self.sections[section].elements.count
        }
        
        func sectionIndexTitle(for section: Int) -> String? {
            
            guard self.sections.indices.contains(section) else {

                return nil
            }
            return self.sections[section].indexTitle
        }
        
        func sectionIndexTitlesForAllSections() -> [String?] {
            
            return self.sections.map({ $0.indexTitle })
        }


        // MARK: Private

        private let dispatcher: MainThreadSerialDispatcher = .init()
        private let dataStack: DataStack

        private var currentSnapshot: Internals.DiffableDataSourceSnapshot = .init()
        private var sections: [Internals.DiffableDataSourceSnapshot.Section] = []
        
        
        // MARK: - ElementPath
        
        @usableFromInline
        internal struct ElementPath: Hashable {
            
            @usableFromInline
            var element: Int
            
            @usableFromInline
            var section: Int

            @usableFromInline
            init(element: Int, section: Int) {
                
                self.element = element
                self.section = section
            }
        }


        // MARK: - MainThreadSerialDispatcher

        fileprivate final class MainThreadSerialDispatcher {

            // MARK: FilePrivate

            fileprivate init() {}

            fileprivate func dispatch(_ action: @escaping () -> Void) {

                let count = self.executingCount.incrementAndGet()
                if Thread.isMainThread && count == 1 {

                    action()
                    self.executingCount.decrement()
                }
                else {

                    DispatchQueue.main.async { [weak self] in

                        guard let self = self else {

                            return
                        }
                        action()
                        self.executingCount.decrement()
                    }
                }
            }


            // MARK: Private

            private let executingCount: AtomicInt = .init()

            
            // MARK: - AtomicInt
            
            fileprivate class AtomicInt {
                
                // MARK: FilePrivate

                fileprivate func incrementAndGet() -> Int {

                    self.lock.wait()
                    defer {
                        
                        self.lock.signal()
                    }
                    self.value += 1
                    return self.value
                }

                fileprivate func decrement() {

                    self.lock.wait()
                    defer {
                        
                        self.lock.signal()
                    }
                    self.value -= 1
                }

                
                // MARK: Private

                private let lock = DispatchSemaphore(value: 1)
                private var value = 0
            }
        }
        
    }
}

#endif
