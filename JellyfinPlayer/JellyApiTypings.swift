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

class ResumeItem: ObservableObject {
    @Published var Name: String = "";
    @Published var Id: String = "";
    @Published var IndexNumber: Int? = nil;
    @Published var ParentIndexNumber: Int? = nil;
    @Published var Image: String = "";
    @Published var ImageType: String = "";
    @Published var BlurHash: String = "";
    @Published var `Type`: String = "";
    @Published var SeasonId: String? = nil;
    @Published var SeriesId: String? = nil;
    @Published var SeriesName: String? = nil;
    @Published var ItemProgress: Double = 0;
    @Published var SeasonImage: String? = nil;
    @Published var SeasonImageType: String? = nil;
    @Published var SeasonImageBlurHash: String? = nil;
    @Published var ItemBadge: Int? = 0;
    @Published var ProductionYear: Int = 1999;
    @Published var Watched: Bool = false;
}

struct ServerMeResponse: Codable {
    
}
