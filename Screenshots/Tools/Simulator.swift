//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct SimulatorList: Decodable {

    struct DeviceType: Decodable {
        let identifier: String
        let name: String
    }

    struct Runtime: Decodable {
        let identifier: String
        let version: String
        let isAvailable: Bool
        let supportedDeviceTypes: [DeviceType]
    }

    struct Device: Decodable {
        let name: String
        let deviceTypeIdentifier: String?
        let isAvailable: Bool
    }

    let runtimes: [Runtime]
    let devices: [String: [Device]]
}

func simctl(_ arguments: String...) throws -> Data {
    let process = Process()
    let output = Pipe()

    process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    process.arguments = ["simctl"] + arguments
    process.standardOutput = output

    try process.run()
    let data = output.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    guard process.terminationStatus == 0 else {
        print("simctl \(arguments.joined(separator: " ")) failed")
        exit(1)
    }

    return data
}

guard CommandLine.arguments.count == 2 else {
    print("Usage: swift Screenshots/Tools/Simulator.swift <device type>")
    exit(1)
}

let typePrefix = "com.apple.CoreSimulator.SimDeviceType."
let deviceType = CommandLine.arguments[1]
let identifier = deviceType.hasPrefix(typePrefix) ? deviceType : typePrefix + deviceType

let list = try JSONDecoder().decode(SimulatorList.self, from: simctl("list", "-j"))

if let device = list.devices.values.joined().first(where: { $0.isAvailable && $0.deviceTypeIdentifier == identifier }) {
    print(device.name)
    exit(0)
}

guard let runtime = list.runtimes
    .filter({ $0.isAvailable && $0.supportedDeviceTypes.contains { $0.identifier == identifier } })
    .max(by: { $0.version.compare($1.version, options: .numeric) == .orderedAscending }),
    let type = runtime.supportedDeviceTypes.first(where: { $0.identifier == identifier })
else {
    let available = Set(list.runtimes.filter(\.isAvailable).flatMap(\.supportedDeviceTypes).map(\.identifier))
        .map { $0.replacing(typePrefix, with: "") }
        .sorted()

    print("Simulator type '\(deviceType)' is not installed. Available: \(available.joined(separator: ", "))")
    exit(1)
}

_ = try simctl("create", type.name, identifier, runtime.identifier)

print(type.name)
