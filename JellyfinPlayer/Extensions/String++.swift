//
//  String++.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/28.
//

import Foundation

extension String {
    func removeRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch { return self }
    }
}
