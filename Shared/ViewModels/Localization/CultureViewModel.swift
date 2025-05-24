//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import Foundation
import JellyfinAPI

final class CultureViewModel: ViewModel, Stateful {

    // MARK: Action

    enum Action: Equatable {
        case refresh
    }

    // MARK: State

    enum State: Hashable {
        case content
        case error(JellyfinAPIError)
        case initial
        case refreshing
    }

    @Published
    private(set) var cultures: Set<CultureDto> = []

    @Published
    var state: State = .initial

    private var currentRefreshTask: AnyCancellable?

    func respond(to action: Action) -> State {
        switch action {
        case .refresh:
            currentRefreshTask?.cancel()

            currentRefreshTask = Task { [weak self] in
                guard let self else { return }

                do {
                    let cultures = try await getCultures()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.cultures = cultures
                        self.state = .content
                    }
                } catch {
                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.state = .error(.init(error.localizedDescription))
                    }
                }
            }
            .asAnyCancellable()

            return state
        }
    }

    // MARK: - Get All Cultures

    private func getCultures() async throws -> Set<CultureDto> {
        let serverCultures = try await getServerCultures()

        // TODO: Remove after iOS 15 drop
        /// Only attempt to get device cultures on iOS 16+
        if #available(iOS 16, *) {
            let displayNames = Set(serverCultures.compactMap(\.displayName))
            let twoLetterCodes = Set(serverCultures.compactMap(\.twoLetterISOLanguageName))
            let threeLetterCodes = Set(serverCultures.compactMap(\.threeLetterISOLanguageName))

            let deviceCultures = getDeviceCultures(
                excludingTwoCodes: twoLetterCodes,
                excludingThreeCodes: threeLetterCodes,
                excludingDisplayNames: displayNames
            )

            var uniqueCulturesDict: [String?: CultureDto] = [:]

            for culture in serverCultures {
                let key = culture.twoLetterISOLanguageName
                uniqueCulturesDict[key] = culture
            }

            for culture in deviceCultures {
                let key = culture.twoLetterISOLanguageName
                if uniqueCulturesDict[key] == nil {
                    uniqueCulturesDict[key] = culture
                }
            }

            return Set(uniqueCulturesDict.values)
        } else {
            return Set(serverCultures)
        }
    }

    // MARK: - Fetch Server Cultures

    private func getServerCultures() async throws -> [CultureDto] {
        let request = Paths.getCultures
        let response = try await userSession.client.send(request)

        return response.value
    }

    // MARK: - Get Device Cultures

    private func getDeviceCultures(
        excludingTwoCodes: Set<String>,
        excludingThreeCodes: Set<String>,
        excludingDisplayNames: Set<String>
    ) -> Set<CultureDto> {

        // TODO: Remove after iOS 15 drop
        /// Only attempt to get device cultures on iOS 16+
        guard #available(iOS 16, *) else { return [] }

        let systemCulturesDict = Locale.availableIdentifiers.reduce(into: [String: CultureDto]()) { dict, identifier in
            let locale = Locale(identifier: identifier)

            guard let code = locale.language.languageCode?.identifier,
                  let threeLetterCode = locale.language.languageCode?.identifier(.alpha3),
                  let twoLetterCode = locale.language.languageCode?.identifier(.alpha2),
                  let displayName = Locale.current.localizedString(forIdentifier: code),
                  !dict.keys.contains(twoLetterCode),
                  !excludingTwoCodes.contains(twoLetterCode),
                  !excludingDisplayNames.contains(displayName)
            else { return }

            dict[twoLetterCode] = CultureDto(
                displayName: displayName,
                name: code,
                threeLetterISOLanguageName: threeLetterCode,
                threeLetterISOLanguageNames: [threeLetterCode],
                twoLetterISOLanguageName: twoLetterCode
            )
        }

        return Set(systemCulturesDict.values)
    }
}
