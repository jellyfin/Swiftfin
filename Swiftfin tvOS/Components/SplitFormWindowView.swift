//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct SplitFormWindowView: View {
    
    private var contentView: () -> any View
    private var description: String?
    private var descriptionView: () -> any View
    
    var body: some View {
        HStack {
            
            VStack(spacing: 20) {
                descriptionView()
                    .eraseToAnyView()
                
                if let description {
                    Text(description)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            
            Form {
                contentView()
                    .eraseToAnyView()
            }
        }
    }
}

extension SplitFormWindowView {
    
    init() {
        self.init(
            contentView: { EmptyView() },
            description: nil,
            descriptionView: { Color.clear }
        )
    }
    
    func contentView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.contentView, with: content)
    }
    
    func description(_ content: String?) -> Self {
        copy(modifying: \.description, with: content)
    }
    
    func descriptionView(@ViewBuilder _ content: @escaping () -> any View) -> Self {
        copy(modifying: \.descriptionView, with: content)
    }
}
