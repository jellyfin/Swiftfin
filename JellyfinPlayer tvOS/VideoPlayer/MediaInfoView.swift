//
/*
 * SwiftFin is subject to the terms of the Mozilla Public
 * License, v2.0. If a copy of the MPL was not distributed with this
 * file, you can obtain one at https://mozilla.org/MPL/2.0/.
 *
 * Copyright 2021 Aiden Vigue & Jellyfin Contributors
 */

import SwiftUI
import JellyfinAPI

class MediaInfoViewController: UIViewController {
    private var contentView: UIHostingController<MediaInfoView>!

    var height: CGFloat = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        tabBarItem.title = "Info"
    }

    func setMedia(item: BaseItemDto) {
        contentView = UIHostingController(rootView: MediaInfoView(item: item))
        self.view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true

        height = self.view.frame.height

    }
}

struct MediaInfoView: View {
    @State var item: BaseItemDto?

    var body: some View {
        if let item = item {
            HStack(spacing: 30) {

                VStack {
                    ImageView(src: item.type == "Episode" ? item.getSeriesPrimaryImage(maxWidth: 200) : item.getPrimaryImage(maxWidth: 200), bh: item.type == "Episode" ? item.getSeriesPrimaryImageBlurHash() : item.getPrimaryImageBlurHash())
                        .frame(width: 200, height: 300)
                        .cornerRadius(10)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 10) {
                    if item.type == "Episode" {
                        Text(item.seriesName ?? "Series")
                            .fontWeight(.bold)

                        Text(item.name ?? "Episode")
                            .foregroundColor(.secondary)
                    } else {
                        Text(item.name ?? "Movie")
                            .fontWeight(.bold)
                    }

                    HStack(spacing: 10) {
                        if item.type == "Episode" {
                            Text("S\(item.parentIndexNumber ?? 0) • E\(item.indexNumber ?? 0)")

                            if let date = item.premiereDate {
                                Text("•")
                                Text(formatDate(date: date))
                            }

                        } else if let year = item.productionYear {
                            Text(String(year))
                        }

                        if item.runTimeTicks != nil {
                            Text("•")
                            Text(item.getItemRuntime())
                        }

                        if let rating = item.officialRating {
                            Text("•")

                            Text("\(rating)").font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                .overlay(RoundedRectangle(cornerRadius: 2)
                                            .stroke(Color.secondary, lineWidth: 1))

                        }
                    }
                    .foregroundColor(.secondary)

                    if let overview = item.overview {
                        Text(overview)
                            .padding(.top)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }

                Spacer()

            }
            .padding(.leading, 350)
            .padding(.trailing, 125)
        } else {
            EmptyView()
        }

    }

    func formatDate(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"

        return formatter.string(from: date)
    }
}
