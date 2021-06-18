//
//  CastDeviceScanner.swift
//  OpenCastSwift
//
//  Created by Miles Hollingsworth on 4/22/18
//  Copyright © 2018 Miles Hollingsworth. All rights reserved.
//

import Foundation

extension CastDevice {
  convenience init(service: NetService, info: [String: String]) {
    var ipAddress: String?

    if let address = service.addresses?.first {
      ipAddress = address.withUnsafeBytes { (pointer: UnsafePointer<sockaddr>) -> String? in
        var hostName = [CChar](repeating: 0, count: Int(NI_MAXHOST))

        return getnameinfo(pointer, socklen_t(address.count), &hostName, socklen_t(NI_MAXHOST), nil, 0, NI_NUMERICHOST) == 0 ? String.init(cString: hostName) : nil
      }
    }

    self.init(id: info["id"] ?? "",
              name: info["fn"] ?? service.name,
              modelName: info["md"] ?? "Google Cast",
              hostName: service.hostName!,
              ipAddress: ipAddress ?? "",
              port: service.port,
              capabilitiesMask: info["ca"].flatMap(Int.init) ?? 0 ,
              status: info["rs"] ?? "",
              iconPath: info["ic"] ?? "")
  }

}

public final class CastDeviceScanner: NSObject {
  public weak var delegate: CastDeviceScannerDelegate?

  public static let deviceListDidChange = Notification.Name(rawValue: "DeviceScannerDeviceListDidChangeNotification")

  private lazy var browser: NetServiceBrowser = configureBrowser()

  public var isScanning = false

  fileprivate var services = [NetService]()

  public fileprivate(set) var devices = [CastDevice]() {
    didSet {
      NotificationCenter.default.post(name: CastDeviceScanner.deviceListDidChange, object: self)
    }
  }

  private func configureBrowser() -> NetServiceBrowser {
    let b = NetServiceBrowser()

    b.includesPeerToPeer = true
    b.delegate = self

    return b
  }

  public func startScanning() {
    guard !isScanning else { return }

    browser.stop()
    browser.searchForServices(ofType: "_googlecast._tcp", inDomain: "local")

    #if DEBUG
      NSLog("Started scanning")
    #endif
  }

  public func stopScanning() {
    guard isScanning else { return }

    browser.stop()

    #if DEBUG
      NSLog("Stopped scanning")
    #endif
  }

  public func reset() {
    stopScanning()
    devices.removeAll()
  }

  deinit {
    stopScanning()
  }

}

extension CastDeviceScanner: NetServiceBrowserDelegate {

  public func netServiceBrowserWillSearch(_ browser: NetServiceBrowser) {
    isScanning = true
  }

  public func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
    isScanning = false
  }

  public func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
    removeService(service)

    service.delegate = self
    service.resolve(withTimeout: 30.0)
    services.append(service)

    #if DEBUG
      NSLog("Did find service: \(service) more: \(moreComing)")
    #endif
  }

  public func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
    guard let service = removeService(service) else { return }

    #if DEBUG
      NSLog("Did remove service: \(service)")
    #endif

    guard let deviceId = service.id,
          let index = devices.firstIndex(where: { $0.id == deviceId }) else {
        #if DEBUG
          NSLog("No device")
        #endif

        return
    }

    #if DEBUG
      NSLog("Removing device: \(devices[index])")
    #endif
    let device = devices.remove(at: index)
    delegate?.deviceDidGoOffline(device)
  }

  @discardableResult func removeService(_ service: NetService) -> NetService? {
      if let index = services.firstIndex(of: service) {
      return services.remove(at: index)
    }

    return nil
  }

  func addDevice(_ device: CastDevice) {
      if let index = devices.firstIndex(where: { $0.id == device.id }) {
      let existing = devices[index]

      guard existing.name != device.name ||  existing.hostName != device.hostName else { return }

      devices.remove(at: index)
      devices.insert(device, at: index)

      delegate?.deviceDidChange(device)
    } else {
      devices.append(device)
      delegate?.deviceDidComeOnline(device)
    }
  }
}

extension CastDeviceScanner: NetServiceDelegate {

  public func netServiceDidResolveAddress(_ sender: NetService) {
    guard let infoDict = sender.infoDict else {
      #if DEBUG
        NSLog("No TXT record for \(sender), skipping")
      #endif
      return
    }

    #if DEBUG
      NSLog("Did resolve service: \(sender)")
      NSLog("\(infoDict)")
    #endif

    guard infoDict["id"] != nil else {
      #if DEBUG
        NSLog("No id for device \(sender), skipping")
      #endif
      return
    }

    addDevice(CastDevice(service: sender, info: infoDict))
  }

  public func netService(_ sender: NetService, didNotResolve errorDict: [String: NSNumber]) {
    removeService(sender)

    #if DEBUG
      NSLog("!! Failed to resolve service: \(sender) - \(errorDict) !!")
    #endif
  }
}

extension NetService {
  var infoDict: [String: String]? {
    guard let data = txtRecordData() else {
      return nil
    }

    var dict = [String: String]()
    NetService.dictionary(fromTXTRecord: data).forEach({ dict[$0.key] = String(data: $0.value, encoding: .utf8)! })

    return dict
  }

  var id: String? {
    return infoDict?["id"]
  }
}

public protocol CastDeviceScannerDelegate: AnyObject {
  func deviceDidComeOnline(_ device: CastDevice)
  func deviceDidChange(_ device: CastDevice)
  func deviceDidGoOffline(_ device: CastDevice)
}
