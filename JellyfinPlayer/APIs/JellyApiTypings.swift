//
//  JellyApiTypings.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 4/30/21.
//

import Foundation
import SwiftUI

extension View {
    func rectReader(_ binding: Binding<CGRect>, in space: CoordinateSpace) -> some View {
        self.background(GeometryReader { (geometry) -> AnyView in
            let rect = geometry.frame(in: space)
            DispatchQueue.main.async {
                binding.wrappedValue = rect
            }
            return AnyView(Rectangle().fill(Color.clear))
        })
    }
}

extension View {
    func ifVisible(in rect: CGRect, in space: CoordinateSpace, execute: @escaping (CGRect) -> Void) -> some View {
        self.background(GeometryReader { (geometry) -> AnyView in
            let frame = geometry.frame(in: space)
            if frame.intersects(rect) {
                execute(frame)
            }
            return AnyView(Rectangle().fill(Color.clear))
        })
    }
}

struct ServerPublicInfoResponse: Codable {
    var LocalAddress: String
    var ServerName: String
    var Version: String
    var ProductName: String
    var OperatingSystem: String
    var Id: String
    var StartupWizardCompleted: Bool
}

struct ServerUserResponse: Codable {
    var Name: String
    var Id: String
    var PrimaryImageTag: String
}

struct ServerAuthByNameResponse: Codable {
    var User: ServerUserResponse
    var AccessToken: String
}

struct ResumeItem {
    var Name: String = "";
    var Id: String = "";
    var IndexNumber: Int? = nil;
    var ParentIndexNumber: Int? = nil;
    var Image: String = "";
    var ImageType: String = "";
    var BlurHash: String = "";
    var `Type`: String = "";
    var SeasonId: String? = nil;
    var SeriesId: String? = nil;
    var SeriesName: String? = nil;
    var ItemProgress: Double = 0;
    var SeasonImage: String? = nil;
    var SeasonImageType: String? = nil;
    var SeasonImageBlurHash: String? = nil;
    var ItemBadge: Int? = 0;
    var ProductionYear: Int = 1999;
    var Watched: Bool = false;
}

struct ServerMeResponse: Codable {
    
}
