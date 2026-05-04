//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@testable import Swiftfin_iOS
import XCTest

/// Covers `String.trimmingSuffix(_:)`. Used in display-name normalization
/// (e.g. stripping codec/quality suffixes from media titles). The
/// character-by-character compare is the high-risk piece — a regression
/// would either over-strip or under-strip user-visible text.
final class StringTrimmingSuffixTests: XCTestCase {

    func testTrimsExactSuffixAtEnd() {
        XCTAssertEqual("hello.txt".trimmingSuffix(".txt"), "hello")
    }

    func testReturnsOriginalWhenSuffixDoesNotMatch() {
        XCTAssertEqual("hello.mkv".trimmingSuffix(".txt"), "hello.mkv")
    }

    func testReturnsOriginalWhenSuffixIsLongerThanString() {
        XCTAssertEqual("ab".trimmingSuffix("longer-than-input"), "ab")
    }

    func testTrimsOnlyMatchingTrailingCharacters() {
        // Only the characters that match from the end are removed; a
        // partial mismatch in the middle stops the trim.
        XCTAssertEqual("file.tar.gz".trimmingSuffix(".gz"), "file.tar")
    }

    func testEmptySuffixIsNoop() {
        XCTAssertEqual("payload".trimmingSuffix(""), "payload")
    }
}
