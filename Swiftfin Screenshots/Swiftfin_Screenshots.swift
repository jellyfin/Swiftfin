//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import XCTest

final class Swiftfin_Screenshots: XCTestCase {
    let demoServerUrl = "127.0.0.1:8096"
    let demoUsername = "username"
    let demoPassword = "password"

    let movieTitle = "Sintel"

    let showTitle = "Pioneer One"
    let episodeTitle = "The Man From Mars"

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run.
        // The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testScreenshots() throws {
        let app = XCUIApplication()

        setupSnapshot(app)
        app.launch()

        if UIDevice.current.userInterfaceIdiom == .pad {
            XCUIDevice.shared.orientation = .landscapeLeft
        }

        if app.buttons["Connect"].exists {
            app.buttons["ShowConnectToServer"].tap()
            app.textFields["Server URL"].tap()
            app.typeText(demoServerUrl)
            app.buttons["ConnectToServer"].tap()
        }

        if app.staticTexts["Add User"].exists {
            app.images["plus"].tap()

            app.typeText(demoUsername)
            app.secureTextFields["Password"].tap()
            app.typeText(demoPassword)

            app.buttons["Sign In"].tap()
            sleep(2)
        }

        snapshot("Home")

        let mediaTab = app.buttons["Media"].firstMatch

        mediaTab.tap()
        mediaTab.tap()

        snapshot("Media")

        app.buttons["Movies"].firstMatch.tap()

        snapshot("Movies")

        app.staticTexts[movieTitle].tap()
        app.images["play.fill"].tap()

        _ = app.buttons["OverlayExit"].waitForExistence(timeout: 5)
        sleep(5)

        // Use .coordinate to get a tap anywhere on screen to reveal overlay
        app.buttons["OverlayExitButton"].firstMatch.coordinate(withNormalizedOffset: .zero).tap()

        snapshot("Playback")

        app.buttons["OverlayExitButton"].firstMatch.coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5)).tap()

        mediaTab.tap()
        mediaTab.tap()

        app.buttons["Shows"].tap()
        app.staticTexts[showTitle].tap()

        snapshot("Series")

        app.staticTexts[episodeTitle].tap()

        snapshot("Episode")
    }
}
