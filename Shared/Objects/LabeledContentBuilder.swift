//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@resultBuilder
struct LabeledContentBuilder {

    @ViewBuilder
    static func buildBlock<each A: View, each B: View>(
        _ content: repeat LabeledContent<each A, each B>
    ) -> some View {
        TupleView((repeat each content))
    }

    @ViewBuilder
    static func buildBlock(
        _ content: ForEach<some RandomAccessCollection, some Hashable, LabeledContent<some View, some View>?>
    ) -> some View {
        content
    }
}
