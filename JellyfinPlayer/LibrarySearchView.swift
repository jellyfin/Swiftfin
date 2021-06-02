//
//  LibrarySearchView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/2/21.
//

import SwiftUI
import SwiftyJSON
import SwiftyRequest
import NukeUI

struct LibrarySearchView: View {
    @Environment(\.managedObjectContext)
    private var viewContext
    @EnvironmentObject
    var globalData: GlobalData
    @StateObject
    var viewModel: LibrarySearchViewModel
    
    @State
    private var tracks: [GridItem] = []

    @Environment(\.verticalSizeClass)
    var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass: UserInterfaceSizeClass?

    func onAppear() {
        guard viewModel.globalData != globalData else { return }
        recalcTracks()
        viewModel.globalData = globalData
    }

    var isPortrait: Bool {
        let result = verticalSizeClass == .regular && horizontalSizeClass == .compact
        return result
    }

    func recalcTracks() {
        let trkCnt = Int(floor(UIScreen.main.bounds.size.width / 125))
        _tracks.wrappedValue = []
        for _ in 0 ..< trkCnt {
            _tracks.wrappedValue.append(GridItem(.flexible()))
        }
    }

    var body: some View {
        ZStack {
            VStack {
                Spacer().frame(height: 6)
                TextField("Search", text: $viewModel.searchQuery, onEditingChanged: { _ in
                    print("changed")
                })
                    .padding(.horizontal, 10)
                    .foregroundColor(Color.secondary)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                ScrollView(.vertical) {
                    LazyVGrid(columns: tracks) {
                        ForEach(viewModel.items, id: \.Id) { item in
                            NavigationLink(destination: ItemView(item: item)) {
                                ResumeItemGridCell(item: item)
                            }
                        }
                    }.onChange(of: isPortrait) { _ in
                        recalcTracks()
                    }
                }
            }
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.items.isEmpty {
                Text("Empty Response")
            }
        }
        .onAppear(perform: onAppear)
        .navigationBarTitle("Search", displayMode: .inline)
    }
}

struct ResumeItemGridCell: View {
    @EnvironmentObject
    var globalData: GlobalData

    var item: ResumeItem

    var body: some View {
        VStack(alignment: .leading) {
            if item.Type == "Movie" {
                LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))
                    .placeholderAndFailure {
                        Image(uiImage: UIImage(blurHash: item
                                .BlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item
                                .BlurHash,
                            size: CGSize(width: 32, height: 32))!)
                            .resizable()
                            .frame(width: 100, height: 150)
                            .cornerRadius(10)
                    }
                    .frame(width: 100, height: 150)
                    .cornerRadius(10)
            } else {
                LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?fillWidth=300&fillHeight=450&quality=90&tag=\(item.Image)"))                    
                    .placeholderAndFailure {
                        Image(uiImage: UIImage(blurHash: item
                                .BlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item
                                .BlurHash,
                            size: CGSize(width: 32, height: 32))!)
                            .resizable()
                            .frame(width: 100, height: 150)
                            .cornerRadius(10)
                    }
                    .frame(width: 100, height: 150)
                    .cornerRadius(10).overlay(ZStack {
                        if item.ItemBadge == 0 {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .padding(3)
                                .foregroundColor(.white)
                        } else {
                            Text("\(String(item.ItemBadge ?? 0))")
                                .font(.caption)
                                .padding(3)
                                .foregroundColor(.white)
                        }
                    }.background(Color.black)
                        .opacity(0.8)
                        .cornerRadius(10.0)
                        .padding(3), alignment: .topTrailing)
            }
            Text(item.Name)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .lineLimit(1)
            Text(String(item.ProductionYear))
                .foregroundColor(.secondary)
                .font(.caption)
                .fontWeight(.medium)
        }.frame(width: 100)
    }
}
