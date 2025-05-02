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

final class CountryViewModel: ViewModel, Stateful {

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
    private(set) var countries: Set<CountryInfo> = []

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
                    let countries = try await getCountries()

                    guard !Task.isCancelled else { return }

                    await MainActor.run {
                        self.countries = countries
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

    // MARK: - Get All Countries

    private func getCountries() async throws -> Set<CountryInfo> {
        let serverCountries = try await getServerCountries()

        let displayNames = Set(serverCountries.compactMap(\.displayName))
        let twoLetterCodes = Set(serverCountries.compactMap(\.twoLetterISORegionName))
        let threeLetterCodes = Set(serverCountries.compactMap(\.threeLetterISORegionName))

        let deviceCountries = getDeviceCountries(
            excludingTwoCodes: twoLetterCodes,
            excludingThreeCodes: threeLetterCodes,
            excludingDisplayNames: displayNames
        )

        var uniqueCountriesDict: [String?: CountryInfo] = [:]

        for country in serverCountries {
            let key = country.twoLetterISORegionName
            uniqueCountriesDict[key] = country
        }

        for country in deviceCountries {
            let key = country.twoLetterISORegionName
            if uniqueCountriesDict[key] == nil {
                uniqueCountriesDict[key] = country
            }
        }

        return Set(uniqueCountriesDict.values)
    }

    // MARK: - Fetch Server Countries

    private func getServerCountries() async throws -> [CountryInfo] {
        let request = Paths.getCountries
        let response = try await userSession.client.send(request)

        return response.value
    }

    // MARK: - Get Device Countries

    private func getDeviceCountries(
        excludingTwoCodes: Set<String>,
        excludingThreeCodes: Set<String>,
        excludingDisplayNames: Set<String>
    ) -> Set<CountryInfo> {
        var deviceCountries: [CountryInfo] = []

        for code in Locale.isoRegionCodes {
            guard !excludingTwoCodes.contains(code),
                  let displayName = Locale.current.localizedString(forRegionCode: code),
                  !excludingDisplayNames.contains(displayName)
            else { continue }

            deviceCountries.append(CountryInfo(
                displayName: displayName,
                name: code,
                threeLetterISORegionName: nil,
                twoLetterISORegionName: code
            ))
        }

        return Set(deviceCountries)
    }
}
