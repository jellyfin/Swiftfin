//
//  JellyfinAPI.swift
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
    case name = "SortName"
    case dateCreated = "DateCreated"
    case datePlayed = "DatePlayed"
    case premiereDate = "PremiereDate"
    case runtime = "Runtime"
}

enum ASC: String {
    case descending = "Descending"
    case ascending = "Ascending"
}

enum FilterType: String {
    case isFavorite = "IsFavorite"
    case isUnplayed = "IsUnplayed"
}

struct Filter {
    var imageTypes: [ImageType] = [.primary, .backdrop, .thumb, .banner]
    var fields: [Field] = [.primaryImageAspectRatio, .basicSyncInfo]
    var itemTypes: [ItemType] = [.movie, .series]
    var filterTypes = [FilterType]()
    var sort: SortType? = .dateCreated
    var asc: ASC? = .descending
    var parentID: String?
    var imageTypeLimit: Int? = 1
    var recursive = true
    var genres = [String]()
    var personIds = [String]()
    var officialRatings = [String]()
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
        parameters["Recursive"] = recursive
        parameters["SortBy"] = sort?.rawValue
        parameters["SortOrder"] = asc?.rawValue
        parameters["Genres"] = genres.joined(separator: ",")
        parameters["PersonIds"] = personIds.joined(separator: ",")
        parameters["OfficialRatings"] = officialRatings.joined(separator: ",")
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
            parameters["Limit"] = 60
            return .requestParameters(parameters: parameters, encoding: URLEncoding.jellyfin)
        case let .items(_, filter, page):
            var parameters = filter.toParamters
            parameters["StartIndex"] = (page - 1) * 100
            parameters["Limit"] = 100
            return .requestParameters(parameters: parameters, encoding: URLEncoding.jellyfin)
        }
    }

    var headers: [String: String]? {
        switch self {
        case let .items(global, _, _),
             let .search(global, _, _, _):
            var headers = [String: String]()
            headers["Content-Type"] = "application/json"
            headers["Accept"] = "application/json"
            headers["X-Emby-Authorization"] = global.authHeader
            return headers
        }
    }
}

extension URLEncoding {
    
    static var jellyfin: URLEncoding {
        URLEncoding(destination: .methodDependent, arrayEncoding: .noBrackets, boolEncoding: .literal)
    }
}
