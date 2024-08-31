//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import SwiftUI

struct CustomDeviceProfileEditorView: View {

    @Binding
    var profile: CustomDeviceProfile

    @EnvironmentObject
    private var router: EditCustomDeviceProfileCoordinator.Router

    var body: some View {
        NavigationView {
            VStack {
                SplitFormWindowView()
                    .descriptionView {
                        Image(systemName: "doc")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 400)
                    }
                    .contentView {
                        Section(L10n.deviceProfile) {
                            Toggle(L10n.useAsTranscodingProfile, isOn: $profile.useAsTranscodingProfile)
                        }

                        Section {
                            ChevronButton(L10n.audio)
                                .onSelect {
                                    router.route(to: \.customDeviceAudioEditor, $profile.audio)
                                }
                            ChevronButton(L10n.video)
                                .onSelect {
                                    router.route(to: \.customDeviceVideoEditor, $profile.video)
                                }
                            ChevronButton(L10n.containers)
                                .onSelect {
                                    router.route(to: \.customDeviceContainerEditor, $profile.container)
                                }
                        }
                    }
                    .withDescriptionTopPadding()
                    .navigationTitle(L10n.customProfile)
            }
        }
    }
}
