//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI

struct ItemDetailsView: View {
    
    @ObservedObject var viewModel: ItemViewModel
    @FocusState private var focused: Bool
    
    var body: some View {
        
        ZStack(alignment: .leading) {
            
            Color(UIColor.darkGray).opacity(focused ? 0.2 : 0)
                .cornerRadius(30, corners: [.topLeft, .topRight])
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Details")
                        .font(.title3)
                        .padding(.bottom, 5)

                    ForEach(detailItems, id: \.self.0) { (title, content) in
                        ItemDetail(title: title, content: content)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Media")
                        .font(.title3)
                        .padding(.bottom, 5)

                    ForEach(mediaItems, id: \.self.0) { (title, content) in
                        ItemDetail(title: title, content: content)
                    }
                }
                
                Spacer()
            }
            .ignoresSafeArea()
            .focusable()
            .focused($focused)
            .padding(.horizontal, 50)
            .padding(.bottom, 50)
        }
    }
}

fileprivate struct ItemDetail: View {
    
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.body)
            Text(content)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }
}

struct RoundedCorner: Shape {

    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}
