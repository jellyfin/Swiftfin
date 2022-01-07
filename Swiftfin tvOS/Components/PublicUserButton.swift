//
 /* 
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

import SwiftUI
import JellyfinAPI
import CoreMedia

struct PublicUserButton: View {
    @Environment(\.isFocused) var envFocused: Bool
    @State var focused: Bool = false
    var publicUser: UserDto

    var body: some View {
        VStack {
            if publicUser.primaryImageTag != nil {
                ImageView(src: URL(string: "\(SessionManager.main.currentLogin.server.currentURI)/Users/\(publicUser.id ?? "")/Images/Primary?width=500&quality=80&tag=\(publicUser.primaryImageTag!)")!)
                    .frame(width: 250, height: 250)
                    .cornerRadius(125.0)
            } else {
                Image(systemName: "person.fill")
                    .foregroundColor(Color(red: 1, green: 1, blue: 1).opacity(0.8))
                    .font(.system(size: 35))
                    .frame(width: 250, height: 250)
                    .background(Color(red: 98 / 255, green: 121 / 255, blue: 205 / 255))
                    .cornerRadius(125.0)
                    .shadow(radius: 6)
            }
            if focused {
                Text(publicUser.name ?? "").font(.headline).fontWeight(.semibold)
            } else {
                Spacer().frame(height: 60)
            }
        }.onChange(of: envFocused) { envFocus in
            withAnimation(.linear(duration: 0.15)) {
                self.focused = envFocus
            }
        }.scaleEffect(focused ? 1.1 : 1)
    }
}
