//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import OrderedCollections
import SwiftUI

struct AppPermissionsView: View {

    @State
    private var statuses: OrderedDictionary<AppPermission, PermissionStatus> = [:]

    var body: some View {
        Form(systemImage: "hand.raised.fill") {
            ForEach(AppPermission.allCases) { permission in
                let title = permission.displayTitle
                let status = statuses[permission] ?? permission.status

                Section {
                    StateAdapter(initialValue: nil as String?) { errorMessage in
                        Button {
                            switch status {
                            case .authorized: ()
                            default:
                                Task { @MainActor in
                                    do {
                                        statuses[permission] = try await permission.request(reason: title)
                                    } catch {
                                        errorMessage.wrappedValue = error.localizedDescription
                                    }
                                }
                            }
                        } label: {
                            LabeledContent {
                                switch status {
                                case .authorized:
                                    Label(L10n.active, systemImage: "circle.fill")
                                        .foregroundStyle(.green)
                                        .labelStyle(.iconOnly)
                                default:
                                    Text(L10n.allow.localizedUppercase)
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .minimumScaleFactor(0.2)
                                        .lineLimit(1)
                                        .foregroundStyle(.blue)
                                        .padding(4)
                                        .padding(.horizontal, 4)
                                        .backport
                                        .glassEffect(in: .capsule)
                                }
                            } label: {
                                Text(title)
                            }
                        }
                        .foregroundStyle(.primary, .secondary)
                        .alert(
                            L10n.error,
                            isPresented: errorMessage.isNotNil()
                        ) {
                            Button(L10n.ok, role: .cancel) {}
                        } message: {
                            Text(L10n.permissionRequestError(title, errorMessage.wrappedValue ?? L10n.unknownError))
                        }
                    }
                } footer: {
                    if permission.privacyDescription.isNotEmpty {
                        Text(permission.privacyDescription)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // TODO: local network permission just with description

            Section {
                ChevronButton(
                    L10n.settings,
                    systemName: "gearshape.fill",
                    external: true
                ) {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }
            } footer: {
                Text(L10n.permissionsSettingsAppFooter)
            }
        }
        .animation(.linear(duration: 0.1), value: statuses)
        .navigationTitle(L10n.permissions)
        .onAppear {
            statuses = OrderedDictionary(uniqueKeysWithValues: AppPermission.allCases.map { ($0, $0.status) })
        }
    }
}
