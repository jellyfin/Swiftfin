//
//  ListSnapshot.SectionInfo.swift
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

import CoreData


// MARK: - ListSnapshot

extension ListSnapshot {
  
    // MARK: - SectionInfo

    public struct SectionInfo: Hashable, RandomAccessCollection {
        
        // MARK: Private
        
        public let sectionID: SectionID
        
        public let itemIDs: [ItemID]
        
        
        // MARK: RandomAccessCollection
        
        public var startIndex: Index {
            
            return self.itemIDs.startIndex
        }
        
        public var endIndex: Index {
            
            return self.itemIDs.endIndex
        }

        public func index(after i: Index) -> Index {

            return self.itemIDs.index(after: i)
        }

        public func formIndex(after i: inout Index) {

            self.itemIDs.formIndex(after: &i)
        }

        public func index(before i: Index) -> Index {

            return self.itemIDs.index(before: i)
        }

        public func formIndex(before i: inout Index) {

            self.itemIDs.formIndex(before: &i)
        }


        // MARK: BidirectionalCollection
        
        public subscript(position: Int) -> ObjectPublisher<O> {
            
            let itemID = self.itemIDs[position]
            return self.context.objectPublisher(objectID: itemID)
        }

        public func index(_ i: Index, offsetBy distance: Int) -> Index {

            return self.itemIDs.index(i, offsetBy: distance)
        }

        public func index(_ i: Index, offsetBy distance: Int, limitedBy limit: Int) -> Index? {

            return self.itemIDs.index(i, offsetBy: distance, limitedBy: limit)
        }

        public func distance(from start: Index, to end: Index) -> Int {

            return self.itemIDs.distance(from: start, to: end)
        }

        public subscript(bounds: Range<Index>) -> ArraySlice<Element> {

            let itemIDs = self.itemIDs[bounds]
            return ArraySlice(itemIDs.map(self.context.objectPublisher(objectID:)))
        }

        
        // MARK: Sequence
        
        public typealias Element = ObjectPublisher<O>
        
        public typealias Index = Int
        
        
        // MARK: Internal
        
        internal let context: NSManagedObjectContext
        
        internal init?(
            sectionID: SectionID,
            listSnapshot: ListSnapshot<O>
        ) {
            
            guard let context = listSnapshot.context else {
                
                return nil
            }
            self.sectionID = sectionID
            self.itemIDs = listSnapshot.itemIDs(inSectionWithID: sectionID)
            self.context = context
        }
    }
}
