//
//  SettingsModel.swift
//  JellyfinPlayer
//
//  Created by Julien Machiels on 25/05/2021.
//

import Foundation

struct UserSettings: Decodable {
    var LocalMaxBitrate: Int;
    var RemoteMaxBitrate: Int;
    var AutoSelectSubtitles: Bool;
    var AutoSelectSubtitlesLangcode: String;
}

struct Bitrates: Codable, Hashable {
    public var name: String
    public var value: Int
}
