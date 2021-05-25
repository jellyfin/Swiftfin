//
//  SettingsViewModel.swift
//  JellyfinPlayer
//
//  Created by Julien Machiels on 25/05/2021.
//

import Foundation

final class SettingsViewModel: ObservableObject {
    var bitrates: [Bitrates] = []

    init() {
        let url = Bundle.main.url(forResource: "bitrates", withExtension: "json")!

        do {
            let jsonData = try Data(contentsOf: url, options: .mappedIfSafe)
            do {
                self.bitrates = try JSONDecoder().decode([Bitrates].self, from: jsonData)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
    }
}
