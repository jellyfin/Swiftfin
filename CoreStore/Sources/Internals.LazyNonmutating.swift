//
//  Internals.LazyNonmutating.swift
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


// MARK: - Internals

extension Internals {

    // MARK: - LazyNonmutating

    @propertyWrapper
    internal final class LazyNonmutating<Value> {

        // MARK: Internal

        init(_ initializer: @escaping () -> Value) {

            self.initializer = initializer
        }

        init(uninitialized: Void) {

            self.initializer = { fatalError() }
        }

        func initialize(_ initializer: @escaping () -> Value) {

            self.initializer = initializer
        }

        func reset(_ initializer: @escaping () -> Value) {

            self.initializer = initializer
            self.initializedValue = nil
        }


        // MARK: @propertyWrapper

        var wrappedValue: Value {

            get {

                if let initializedValue = self.initializedValue {

                    return initializedValue
                }
                let initializedValue = self.initializer()
                self.initializedValue = initializedValue
                return initializedValue
            }
            set {

                self.initializer = { newValue }
                self.initializedValue = newValue
            }
        }

        var projectedValue: Internals.LazyNonmutating<Value> {

            return self
        }


        // MARK: Private

        private var initializer: () -> Value
        private var initializedValue: Value? = nil
    }
}
