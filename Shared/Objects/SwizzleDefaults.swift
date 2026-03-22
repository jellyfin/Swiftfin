//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import ObjectiveC.runtime

enum SwizzleDefaults {

    private static var overrides: [String: Any?] = [:]
    private static let lock = NSLock()
    private static let activeKeys = NSMapTable<Thread, NSMutableSet>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )

    static func install() {
        _ = swizzleOnce
    }

    private static func set(_ override: Any?, for key: String) {
        lock.lock()
        defer { lock.unlock() }
        overrides[key] = override
    }

    static func set(_ value: Bool, for key: String) {
        set(NSNumber(value: value), for: key)
    }

    static func set(_ value: String, for key: String) {
        set(value as NSString, for: key)
    }

    static func set(_ value: Int, for key: String) {
        set(NSNumber(value: value), for: key)
    }

    static func set(_ value: Double, for key: String) {
        set(NSNumber(value: value), for: key)
    }

    static func remove(_ key: String) {
        set(nil, for: key)
    }

    fileprivate static func resolve(_ key: String, in defaults: UserDefaults) -> Any?? {
        guard beginResolving(key) else { return nil }
        defer { endResolving(key) }

        lock.lock()
        let override = overrides[key]
        lock.unlock()

        guard let override else { return nil }
        return override
    }

    private static func beginResolving(_ key: String) -> Bool {
        let thread = Thread.current
        lock.lock()
        defer { lock.unlock() }

        let set = activeKeys.object(forKey: thread) ?? {
            let s = NSMutableSet()
            activeKeys.setObject(s, forKey: thread)
            return s
        }()

        if set.contains(key) { return false }
        set.add(key)
        return true
    }

    private static func endResolving(_ key: String) {
        let thread = Thread.current
        lock.lock()
        defer { lock.unlock() }
        activeKeys.object(forKey: thread)?.remove(key)
    }

    private static let swizzleOnce: Void = {
        swizzle(#selector(UserDefaults.object(forKey:)), #selector(UserDefaults._ds_object(forKey:)))
        swizzle(#selector(UserDefaults.bool(forKey:)), #selector(UserDefaults._ds_bool(forKey:)))
        swizzle(#selector(UserDefaults.string(forKey:)), #selector(UserDefaults._ds_string(forKey:)))
        swizzle(#selector(UserDefaults.integer(forKey:)), #selector(UserDefaults._ds_integer(forKey:)))
        swizzle(#selector(UserDefaults.double(forKey:)), #selector(UserDefaults._ds_double(forKey:)))
    }()

    private static func swizzle(_ original: Selector, _ replacement: Selector) {
        guard let a = class_getInstanceMethod(UserDefaults.self, original),
              let b = class_getInstanceMethod(UserDefaults.self, replacement)
        else { return }

        method_exchangeImplementations(a, b)
    }
}

fileprivate extension UserDefaults {

    @objc
    func _ds_object(forKey key: String) -> Any? {
        if let resolved = SwizzleDefaults.resolve(key, in: self) { return resolved }
        return _ds_object(forKey: key)
    }

    @objc
    func _ds_bool(forKey key: String) -> Bool {
        if let resolved = SwizzleDefaults.resolve(key, in: self) {
            switch resolved {
            case let n as NSNumber: return n.boolValue
            case let s as NSString: return s.boolValue
            case let b as Bool: return b
            default: return false
            }
        }
        return _ds_bool(forKey: key)
    }

    @objc
    func _ds_string(forKey key: String) -> String? {
        if let resolved = SwizzleDefaults.resolve(key, in: self) {
            switch resolved {
            case let s as NSString: return s as String
            case let s as String: return s
            case let n as NSNumber: return n.stringValue
            default: return nil
            }
        }
        return _ds_string(forKey: key)
    }

    @objc
    func _ds_integer(forKey key: String) -> Int {
        if let resolved = SwizzleDefaults.resolve(key, in: self) {
            switch resolved {
            case let n as NSNumber: return n.intValue
            case let s as NSString: return s.integerValue
            case let i as Int: return i
            default: return 0
            }
        }
        return _ds_integer(forKey: key)
    }

    @objc
    func _ds_double(forKey key: String) -> Double {
        if let resolved = SwizzleDefaults.resolve(key, in: self) {
            switch resolved {
            case let n as NSNumber: return n.doubleValue
            case let s as NSString: return s.doubleValue
            case let d as Double: return d
            default: return 0
            }
        }
        return _ds_double(forKey: key)
    }
}
