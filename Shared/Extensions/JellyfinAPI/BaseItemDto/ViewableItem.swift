//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import BlurHashKit
import JellyfinAPI
import SwiftUI

protocol ViewableItem: Hashable, Identifiable, Poster {
    
    // MARK: Identity
    
    var id: String? { get }
    var name: String? { get }
    var type: BaseItemKind? { get }
    var unwrappedIDHashOrZero: Int { get }
    var hashValue: Int { get }
    
    // MARK: Display
    
    var displayTitle: String { get }
    var alternateTitle: String? { get }
    var parentTitle: String? { get }
    
    // MARK: Metadata
    
    var overview: String? { get }
    var taglines: [String]? { get }
    var genres: [String]? { get }
    var itemGenres: [ItemGenre]? { get }
    var studios: [NameGuidPair]? { get }
    var officialRating: String? { get }
    var customRating: String? { get }
    var criticRating: Float? { get }
    var communityRating: Float? { get }
    var hasRatings: Bool { get }
    var libraryType: BaseItemKind? { get }
    
    // MARK: Dates & Time
    
    var premiereDate: Date? { get }
    var premiereDateYear: String? { get }
    var birthday: Date? { get }
    var deathday: Date? { get }
    var birthplace: String? { get }
    var airDateLabel: String? { get }
    var isUnaired: Bool { get }
    var isMissing: Bool { get }
    var runTimeTicks: Int? { get }
    var runTimeLabel: String? { get }
    
    // MARK: Relationships
    
    var people: [BaseItemPerson]? { get }
    var seriesID: String? { get }
    var seriesName: String? { get }
    var seasonID: String? { get }
    var parentIndexNumber: Int? { get }
    var indexNumber: Int? { get }
    var partCount: Int? { get }
    
    // MARK: Media
    
    var mediaSources: [MediaSourceInfo]? { get }
    var remoteTrailers: [MediaURL]? { get }
    var canBePlayed: Bool { get }
    var presentPlayButton: Bool { get }
    var isPlayable: Bool { get }
    
    // MARK: Episodes
    
    var episodeLocator: String? { get }
    var seasonEpisodeLabel: String? { get }
    var playButtonLabel: String? { get }
    var progressLabel: String? { get }
    
    // MARK: Extras
    
    var extraType: ExtraType? { get }
    
    // MARK: User Data
    
    var userData: UserItemDataDto? { get set }
    
    // MARK: Images
    
    func imageSource(_ type: ImageType, maxWidth: Int) -> ImageSource
    func imageSource(_ type: ImageType, maxHeight: Int) -> ImageSource
    func imageURL(_ type: ImageType, maxWidth: Int) -> URL?
    func imageURL(_ type: ImageType, maxHeight: Int) -> URL?
    func blurHash(for type: ImageType) -> BlurHash?
    func parentImageSource(_ type: ImageType, maxWidth: CGFloat?, maxHeight: CGFloat?, quality: Int?) -> ImageSource
    
    // MARK: Methods
    
    func getFullItem(userSession: UserSession) async throws -> Self
}
