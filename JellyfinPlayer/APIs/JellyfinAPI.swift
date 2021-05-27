//
//  SearchAPI.swift
//  JellyfinPlayer
//
//  Created by PangMo5 on 2021/05/27.
//

import Foundation
import Moya

enum ImageType: String {
    case primary = "Primary"
    case backdrop = "Backdrop"
    case thumb = "Thumb"
    case banner = "Banner"
}

enum Field: String {
    case primaryImageAspectRatio = "PrimaryImageAspectRatio"
    case basicSyncInfo = "BasicSyncInfo"
}

enum ItemType: String {
    case movie = "Movie"
    case series = "Series"
}

enum SortType: String {
    case name = "Name"
    case dateCreated = "DateCreated"
}

enum ASC: String {
    case descending = "Descending"
    case ascending = "Ascending"
}

enum FilterType: String {
    case isFavorite = "IsFavorite"
}

struct Filter {
    var imageTypes = [ImageType]()
    var fields = [Field]()
    var itemTypes = [ItemType]()
    var filterTypes = [FilterType]()
    var sort: SortType?
    var asc: ASC?
    var parentID: String?
    var imageTypeLimit: Int?
    var recursive = true
    var genres = [String]()
    var personIds = [String]()
}

extension Filter {
    var toParamters: [String: Any] {
        var parameters = [String: Any]()
        parameters["EnableImageTypes"] = imageTypes.map(\.rawValue).joined(separator: ",")
        parameters["Fields"] = fields.map(\.rawValue).joined(separator: ",")
        parameters["Filters"] = filterTypes.map(\.rawValue).joined(separator: ",")
        parameters["ImageTypeLimit"] = imageTypeLimit
        parameters["IncludeItemTypes"] = itemTypes.map(\.rawValue).joined(separator: ",")
        parameters["ParentId"] = parentID
        parameters["Recursive"] = recursive.description
        parameters["SortBy"] = sort?.rawValue
        parameters["SortOrder"] = asc?.rawValue
        parameters["Genres"] = genres.joined(separator: ",")
        parameters["PersonIds"] = personIds.joined(separator: ",")
        return parameters
    }
}

enum JellyfinAPI {
    case items(globalData: GlobalData, filter: Filter, page: Int)
    case search(globalData: GlobalData, filter: Filter, searchQuery: String, page: Int)
}

extension JellyfinAPI: TargetType {
    var baseURL: URL {
        switch self {
        case let .items(global, _, _),
             let .search(global, _, _, _):
            return URL(string: global.server?.baseURI ?? "")!
        }
    }

    var path: String {
        switch self {
        case let .items(global, _, _),
             let .search(global, _, _, _):
            return "/Users/\(global.user?.user_id ?? "")/Items"
        }
    }

    var method: Moya.Method {
        switch self {
        case .items, .search:
            return .get
        }
    }

    var sampleData: Data {
        "{".data(using: .utf8)!
    }

    var task: Task {
        switch self {
        case let .search(_, filter, searchQuery, page):
            var parameters = filter.toParamters
            parameters["searchTerm"] = searchQuery
            parameters["StartIndex"] = (page - 1) * 100
            parameters["Limit"] = 100
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        case let .items(_, filter, page):
            var parameters = filter.toParamters
            parameters["StartIndex"] = (page - 1) * 100
            parameters["Limit"] = 100
            return .requestParameters(parameters: parameters, encoding: URLEncoding.default)
        }
    }

    var headers: [String: String]? {
        switch self {
        case let .items(global, _, _),
             let .search(global, _, _, _):
            return [
                "X-Emby-Authorization": global.authHeader
            ]
        }
    }
}
