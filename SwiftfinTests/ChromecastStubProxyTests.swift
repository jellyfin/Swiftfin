//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
@testable import Swiftfin_iOS
import XCTest

@MainActor
final class ChromecastStubProxyTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        Defaults[.sendProgressReports] = false
    }

    private func makeManagerWithStub() -> (MediaPlayerManager, ChromecastStubVideoMediaPlayerProxy) {
        let item = MediaPlayerItem(
            baseItem: BaseItemDto(),
            mediaSource: MediaSourceInfo(),
            playSessionID: "",
            url: URL(string: "https://example.invalid/media")!
        )
        let manager = MediaPlayerManager(playbackItem: item, queue: nil)
        let stub = ChromecastStubVideoMediaPlayerProxy()
        manager.proxy = stub
        return (manager, stub)
    }

    func testSetPlaybackRequestStatusForwardsPlayPause() async {
        let (manager, stub) = makeManagerWithStub()

        await manager.setPlaybackRequestStatus(status: .paused)
        await Task.yield()
        XCTAssertEqual(stub.recordedInvocations, ["pause"])

        await manager.setPlaybackRequestStatus(status: .playing)
        await Task.yield()
        XCTAssertEqual(stub.recordedInvocations, ["pause", "play"])
    }

    func testTogglePlayPauseForwardsToProxy() async {
        let (manager, stub) = makeManagerWithStub()
        await manager.setPlaybackRequestStatus(status: .playing)
        await Task.yield()
        stub.resetRecordedInvocations()

        await manager.togglePlayPause()
        await Task.yield()
        XCTAssertEqual(stub.recordedInvocations, ["pause"])

        await manager.togglePlayPause()
        await Task.yield()
        XCTAssertEqual(stub.recordedInvocations, ["pause", "play"])
    }

    func testDirectProxyTransportCallsAreRecorded() {
        let (manager, stub) = makeManagerWithStub()

        manager.proxy?.setSeconds(.seconds(10))
        manager.proxy?.jumpForward(.seconds(5))
        manager.proxy?.jumpBackward(.seconds(2))
        manager.proxy?.setRate(1.25)

        XCTAssertEqual(
            stub.recordedInvocations,
            ["setSeconds", "jumpForward", "jumpBackward", "setRate"]
        )
    }

    func testStopIsRecordedWhenProxyReceivesStop() {
        let (_, stub) = makeManagerWithStub()
        stub.stop()
        XCTAssertEqual(stub.recordedInvocations, ["stop"])
    }

    func testManagerStopForwardsToProxy() async {
        let (manager, stub) = makeManagerWithStub()
        await manager.stop()
        XCTAssertTrue(stub.recordedInvocations.contains("stop"))
    }
}
