//
//  Internals.SharedNotificationObserver.swift
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

// MARK: - Internal

extension Internals {

    // MARK: - SharedNotificationObserver

    internal final class SharedNotificationObserver<T> {

        // MARK: Internal

        internal init(
            notificationName: Notification.Name,
            object: Any?,
            queue: OperationQueue? = nil,
            sharedValue: @escaping (_ note: Notification) -> T
        ) {

            self.observer = NotificationCenter.default.addObserver(
                forName: notificationName,
                object: object,
                queue: queue,
                using: { [weak self] (notification) in

                    guard let self = self else {

                        return
                    }
                    let value = sharedValue(notification)
                    self.notifyObservers(value)
                }
            )
        }

        deinit {

            self.observer.map(NotificationCenter.default.removeObserver(_:))
            self.observers.removeAllObjects()
        }

        internal func addObserver<U: AnyObject>(
            _ observer: U,
            closure: @escaping (T) -> Void
        ) {

            self.observers.setObject(
                Closure<T, Void>(closure),
                forKey: observer
            )
        }
        
        internal func removeObserver<U: AnyObject>(_ observer: U) {

            self.observers.removeObject(forKey: observer)
        }


        // MARK: Private

        private var observer: NSObjectProtocol!
        private let observers: NSMapTable<AnyObject, Closure<T, Void>> = .weakToStrongObjects()

        private func notifyObservers(_ sharedValue: T) {

            guard let enumerator = self.observers.objectEnumerator() else {

                return
            }
            for closure in enumerator {

                (closure as! Closure<T, Void>).invoke(with: sharedValue)
            }
        }
    }
}
