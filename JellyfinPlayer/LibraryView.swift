//
//  LibraryView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/1/21.
//

import SwiftUI
import NukeUI

struct LibraryView: View {
    @Environment(\.managedObjectContext)
    private var viewContext
    @EnvironmentObject
    var globalData: GlobalData
    @StateObject
    var viewModel: LibraryViewModel

    @State
    private var showFiltersPopover: Bool = false
    @State
    private var showingSearchView: Bool = false

    private var title: String

    @State
    private var tracks: [GridItem] = []

    init(viewModel: LibraryViewModel, title: String) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.title = title
    }

    func onAppear() {
        guard viewModel.globalData != globalData else { return }
        recalcTracks()
        viewModel.globalData = globalData
    }

    @Environment(\.verticalSizeClass)
    var verticalSizeClass: UserInterfaceSizeClass?
    @Environment(\.horizontalSizeClass)
    var horizontalSizeClass: UserInterfaceSizeClass?

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
            ScrollView(.vertical) {
                Spacer().frame(height: 16)
                LazyVGrid(columns: tracks) {
                    ForEach(viewModel.items, id: \.Id) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            ItemGridView(item: item)
                        }
                    }
                }
                HStack() {
                    Spacer()
                    Button {
                        viewModel.requestPreviousPage()
                    } label: {
                        Image(systemName: "chevron.left").font(.system(size: 25))
                    }.disabled(viewModel.isHiddenPreviousButton)
                    Text("\(viewModel.page) of \(viewModel.totalPages)")
                    Button {
                        viewModel.requestNextPage()
                    } label: {
                        Image(systemName: "chevron.right").font(.system(size: 25))
                    }.disabled(viewModel.isHiddenNextButton)
                    Spacer()
                }
                Spacer().frame(height: 16)
            }
            .onChange(of: isPortrait) { _ in
                recalcTracks()
            }
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.items.isEmpty {
                Text("Empty Response")
            }
        }
        .onAppear(perform: onAppear)
        .navigationTitle(title)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if !viewModel.isHiddenPreviousButton {
                    Button {
                        viewModel.requestPreviousPage()
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                if !viewModel.isHiddenNextButton {
                    Button {
                        viewModel.requestNextPage()
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
                NavigationLink(destination: LazyView { LibrarySearchView(viewModel: .init(filter: viewModel.filter)) }) {
                    Image(systemName: "magnifyingglass")
                }
                Button {
                    showFiltersPopover = true
                } label: {
                    Image(systemName: "line.horizontal.3.decrease")
                }
            }
        }
        .sheet(isPresented: self.$showFiltersPopover) {
            LibraryFilterView(library: viewModel.filter.parentID ?? "", filter: $viewModel.filter)
                .environmentObject(self.globalData)
        }
    }
}

extension LibraryView {
    struct ItemGridView: View {
        @EnvironmentObject
        var globalData: GlobalData
        var item: ResumeItem

        var body: some View {
            VStack(alignment: .leading) {
                if item.Type == "Movie" {
                    LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=250&quality=80&tag=\(item.Image)"))
                        .placeholderAndFailure {
                            Image(uiImage: UIImage(blurHash: item
                                    .BlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item
                                    .BlurHash,
                                size: CGSize(width: 16, height: 16))!)
                                .resizable()
                                .frame(width: 100, height: 150)
                                .cornerRadius(10)
                        }
                        .frame(width: 100, height: 150)
                        .cornerRadius(10)
                } else {
                    LazyImage(source: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=250&quality=80&tag=\(item.Image)"))
                        .placeholderAndFailure {
                            Image(uiImage: UIImage(blurHash: item
                                    .BlurHash == "" ? "W$H.4}D%bdo#a#xbtpxVW?W?jXWsXVt7Rjf5axWqxbWXnhada{s-" : item
                                    .BlurHash,
                                size: CGSize(width: 16, height: 16))!)
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
}
