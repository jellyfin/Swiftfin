//
//  SearchAPI.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/27.
//

import Foundation
import Moya

enum SortType: String {
    case name = "Name"
}

enum ASC: String {
    case descending = "Descending"
    case ascending = "Ascending"
}

enum JellyfinAPI {
    case search(globalData: GlobalData, url: URL, query: String, sort: SortType = .name, asc: ASC = .descending)
}

extension JellyfinAPI: TargetType {
    var baseURL: URL {
        switch self {
        case let .search(_, url, _, _, _):
            return url
        }
    }

    var path: String {
        return ""
    }

    var method: Moya.Method {
        switch self {
        case .search:
            return .get
        }
    }

    var sampleData: Data {
        "{".data(using: .utf8)!
    }

    var task: Task {
        switch self {
        case let .search(_, _, query, sort, asc):
            var parameters = [String: Any]()
            parameters["searchTerm"] = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
            parameters["SortBy"] = sort.rawValue
            parameters["SortOrder"] = asc.rawValue
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }

    var headers: [String: String]? {
        switch self {
        case let .search(globalData, _, _, _, _):
            return ["X-Emby-Authorization": globalData.authHeader]
        }
    }
}
