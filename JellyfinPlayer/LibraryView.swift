//
//  LibraryView.swift
//  JellyfinPlayer
//
//  Created by Aiden Vigue on 5/1/21.
//

import SDWebImageSwiftUI
import SwiftUI
import SwiftyJSON
import SwiftyRequest

struct LibraryView: View {
    @Environment(\.managedObjectContext)
    private var viewContext
    @EnvironmentObject
    var globalData: GlobalData
    @ObservedObject
    var viewModel: LibraryViewModel

    @State
    private var viewDidLoad: Bool = false
    @State
    private var showFiltersPopover: Bool = false
    @State
    private var showSearchPopover: Bool = false
    @State
    private var title: String = ""
    @State
    private var closeSearch: Bool = false

    init(viewModel: LibraryViewModel, title: String) {
        self.viewModel = viewModel
        self._title = State(initialValue: title)
    }

    func onAppear() {
        viewModel.globalData = globalData
        if viewModel.items.isEmpty {
            recalcTracks()
            viewModel.requestInitItems()
        }
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

    @State
    private var tracks: [GridItem] = []

    var body: some View {
        LoadingView(isShowing: $viewModel.isLoading) {
            ScrollView(.vertical) {
                Spacer().frame(height: 16)
                LazyVGrid(columns: tracks) {
                    ForEach(viewModel.items, id: \.Id) { item in
                        NavigationLink(destination: ItemView(item: item)) {
                            ItemGridView(item: item)
                        }
                    }
                }
                Spacer().frame(height: 16)
            }
            .gesture(DragGesture().onChanged { value in
                if value.translation.height > 0 {
                    print("Scroll down")
                } else {
                    print("Scroll up")
                }
            })
            .onChange(of: isPortrait) { _ in
                recalcTracks()
            }
        }
        .overrideViewPreference(.unspecified)
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
                NavigationLink(destination: LibrarySearchView(viewModel: .init(filter: viewModel.filter), close: $closeSearch),
                               isActive: $closeSearch) {
                    Image(systemName: "magnifyingglass")
                }
                Button {
                    showFiltersPopover = true
                } label: {
                    Image(systemName: "line.horizontal.3.decrease")
                }
            }
        }
//            .sheet(isPresented: self.$showFiltersPopover) {
//                LibraryFilterView(library: selected_library_id, output: $filterString, close: $showFiltersPopover)
//                    .environmentObject(self.globalData)
//            }
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
                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=250&quality=80&tag=\(item.Image)"))
                        .resizable()
                        .placeholder {
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
                    WebImage(url: URL(string: "\(globalData.server?.baseURI ?? "")/Items/\(item.Id)/Images/\(item.ImageType)?maxWidth=250&quality=80&tag=\(item.Image)"))
                        .resizable()
                        .placeholder {
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
