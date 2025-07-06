//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct OfflineBanner: View {

    enum BannerType {
        case offline
        case serverUnreachable
    }

    private let type: BannerType
    private let showDescription: Bool
    private let compact: Bool

    init(
        type: BannerType,
        showDescription: Bool = false,
        compact: Bool = false
    ) {
        self.type = type
        self.showDescription = showDescription
        self.compact = compact
    }

    private var iconName: String {
        switch type {
        case .offline:
            return "wifi.slash"
        case .serverUnreachable:
            return "server.rack"
        }
    }

    private var title: String {
        switch type {
        case .offline:
            return compact ? "Offline" : "You're Offline"
        case .serverUnreachable:
            return "Server Unreachable"
        }
    }

    private var description: String {
        switch type {
        case .offline:
            return "Downloaded content will appear here when available"
        case .serverUnreachable:
            return "Can't connect to your Jellyfin server. Downloaded content is available below."
        }
    }

    private var padding: EdgeInsets {
        if compact {
            return EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8)
        } else {
            return EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12)
        }
    }

    private var cornerRadius: CGFloat {
        compact ? 6 : 8
    }

    private var font: Font {
        compact ? .caption : .body
    }

    var body: some View {
        VStack(spacing: showDescription ? 12 : 0) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(.orange)
                Text(title)
                    .foregroundColor(.orange)
                    .fontWeight(.medium)
            }
            .font(font)
            .padding(padding)
            .background(Color.orange.opacity(0.15))
            .cornerRadius(cornerRadius)

            if showDescription {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OfflineBanner(type: .offline, showDescription: true)
        OfflineBanner(type: .serverUnreachable, showDescription: true)
        OfflineBanner(type: .offline, compact: true)
        OfflineBanner(type: .serverUnreachable, compact: true)
    }
    .padding()
}
