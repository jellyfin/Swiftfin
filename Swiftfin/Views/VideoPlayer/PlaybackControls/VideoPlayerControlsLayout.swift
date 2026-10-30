//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct VideoPlayerControlsLayout<
    Toolbar: View,
    Buttons: View,
    Progress: View,
    ProgressBackground: View,
    Actions: View,
    Supplements: View,
    Toast: View
>: View {

    private enum Region: Hashable {
        case supplements
        case progress
    }

    let systemInsets: EdgeInsets
    let edgePadding: CGFloat
    let showsProgress: Bool
    let showsSupplements: Bool
    let buttonsInsets: EdgeInsets

    @State
    private var progressHeight: CGFloat = 0

    @ViewBuilder
    var toolbar: Toolbar
    @ViewBuilder
    var buttons: Buttons
    @ViewBuilder
    var progress: Progress
    @ViewBuilder
    var progressBackground: ProgressBackground
    @ViewBuilder
    var actions: Actions
    @ViewBuilder
    var supplements: Supplements
    @ViewBuilder
    var toast: Toast

    private var contentInsets: EdgeInsets {
        EdgeInsets(
            top: max(systemInsets.top, edgePadding),
            leading: max(systemInsets.leading, edgePadding),
            bottom: systemInsets.bottom,
            trailing: max(systemInsets.trailing, edgePadding)
        )
    }

    private var actionRegions: Set<Region> {
        if showsProgress {
            [.supplements, .progress]
        } else if showsSupplements {
            [.supplements]
        } else {
            []
        }
    }

    var body: some View {
        SafeRegion(Region.self, systemInsets: .forwarded(contentInsets)) {
            SafeRegionItem(Region.self, alignment: .bottom, clipsContent: false) {
                Color.clear
                    .frame(height: progressHeight)
                    .background(alignment: .top) {
                        progressBackground
                            .frame(height: progressHeight + 50 + edgePadding * 2)
                    }
            }
            .observingSafeRegion([.supplements])
            .ignoresSafeRegion(.all, edges: .horizontal)
            .ignoresSafeRegion(.system, edges: .top)
            .allowsHitTesting(false)

            SafeRegionItem {
                SafeRegion(systemInsets: .forwarded(buttonsInsets)) {
                    SafeRegionItem { buttons }
                }
            }
            .ignoresSafeRegion(.all)

            SafeRegionItem(alignment: .top, clipsContent: false) {
                toolbar
            }
            .ignoresSafeRegion(.custom)

            SafeRegionItem(Region.self, alignment: .bottomTrailing, clipsContent: false) {
                actions
                    .padding(.bottom, edgePadding)
            }
            .ignoresSafeRegion(.system, edges: .top)
            .observingSafeRegion(actionRegions)

            // Keep bottom controls in place while visibility changes.
            SafeRegionInset(
                edge: .bottom,
                id: Region.supplements,
                clipsContent: false
            ) {
                supplements
            }
            .ignoresSystemSafeRegion(edges: .top)

            SafeRegionInset(edge: .bottom, id: Region.progress, clipsContent: false) {
                progress
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { progressHeight = $0 }
            }
            .ignoresSystemSafeRegion(edges: .top)

            SafeRegionItem(alignment: .top, clipsContent: false) {
                toast
                    .padding(.top, 10)
            }
            .ignoresSafeRegion(.custom)
            .ignoresSafeRegion(.system, edges: .horizontal)
        }
    }
}
