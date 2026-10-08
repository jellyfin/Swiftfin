//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct DeviceTypeList: Decodable {

    struct DeviceType: Decodable {
        let identifier: String
        let name: String
    }

    let devicetypes: [DeviceType]
}

struct RuntimeList: Decodable {

    struct Runtime: Decodable {
        let identifier: String
        let platform: String?
        let version: String
        let isAvailable: Bool
    }

    let runtimes: [Runtime]
}

struct DeviceList: Decodable {

    struct Device: Decodable {
        let name: String
        let deviceTypeIdentifier: String?
    }

    let devices: [String: [Device]]
}

func fail(_ message: String) -> Never {
    print(message)
    exit(1)
}

@discardableResult
func simctl(_ arguments: [String]) -> Data {
    let process = Process()
    let output = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["simctl"] + arguments
    process.standardOutput = output

    do {
        try process.run()
    } catch {
        fail("Unable to run simctl: \(error.localizedDescription)")
    }

    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        fail("simctl \(arguments.joined(separator: " ")) failed")
    }

    return data
}

func list<T: Decodable>(_ type: T.Type, _ arguments: String...) -> T {
    guard let list = try? JSONDecoder().decode(T.self, from: simctl(["list", "-j"] + arguments)) else {
        fail("Unable to read simctl list \(arguments.joined(separator: " "))")
    }

    return list
}

let arguments = CommandLine.arguments.dropFirst()

guard arguments.count == 2 else {
    fail("Usage: swift Screenshots/Tools/Simulator.swift <device type> <runtime platform>")
}

let deviceType = arguments[arguments.startIndex]
let runtimePlatform = arguments[arguments.startIndex + 1]
let typePrefix = "com.apple.CoreSimulator.SimDeviceType."
let identifier = deviceType.hasPrefix(typePrefix) ? deviceType : typePrefix + deviceType

let deviceTypes = list(DeviceTypeList.self, "devicetypes").devicetypes

guard let type = deviceTypes.first(where: { $0.identifier == identifier }) else {
    let available = deviceTypes.map { $0.identifier.replacing(typePrefix, with: "") }
    fail("Simulator type '\(deviceType)' is not installed. Available: \(available.joined(separator: ", "))")
}

let devices = list(DeviceList.self, "devices", "available").devices.values.flatMap(\.self)

if let existing = devices.first(where: { $0.deviceTypeIdentifier == identifier }) {
    print(existing.name)
    exit(0)
}

guard let runtime = list(RuntimeList.self, "runtimes")
    .runtimes
    .filter({ $0.isAvailable && $0.platform == runtimePlatform })
    .max(by: { $0.version.compare($1.version, options: .numeric) == .orderedAscending })
else {
    fail("No \(runtimePlatform) simulator runtime is installed")
}

simctl(["create", type.name, identifier, runtime.identifier])

print(type.name)
