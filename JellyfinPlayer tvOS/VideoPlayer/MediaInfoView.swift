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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.title = "Info"
    }
    
    func setMedia(item: BaseItemDto)
    {
        contentView = UIHostingController(rootView: MediaInfoView(item: item))
        self.view.addSubview(contentView.view)
        contentView.view.translatesAutoresizingMaskIntoConstraints = false
        contentView.view.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        contentView.view.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        contentView.view.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
    }
}

struct MediaInfoView: View {
    @State var item : BaseItemDto? = nil
    
    var body: some View {
        if let item = item {
            HStack {
                VStack {
                    ImageView(src: item.type == "Episode" ? item.getSeriesPrimaryImage(maxWidth: 200) : item.getPrimaryImage(maxWidth: 200), bh: item.type == "Episode" ? item.getSeriesPrimaryImageBlurHash() : item.getPrimaryImageBlurHash())                    .frame(width: 200, height: 300)
                        .cornerRadius(10)
                    Spacer()
                }
                .padding(.leading, 200)
                    
                    VStack(alignment: .leading) {
                        if item.type == "Episode" {
                            Text(item.seriesName!)
                                .font(.title3)
                            
                            Text("S\(item.parentIndexNumber ?? 0):E\(item.indexNumber ?? 0) • \(item.name!)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        else
                        {
                            Text(item.name!)
                                .font(.title3)
                        }
                        
                        HStack(spacing: 10) {
                            Text(String(item.productionYear!))
                            Text("•")
                            
                            Text(formatRunningtime())
                            
                            if item.officialRating != nil {
                                Text("•")
                                
                                Text("\(item.officialRating!)").font(.subheadline)
                                    .fontWeight(.semibold)
                                    .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                    .overlay(RoundedRectangle(cornerRadius: 2)
                                                .stroke(Color.secondary, lineWidth: 1))
                                
                            }
                        }
                        .padding(.top)
                        .foregroundColor(.secondary)
                        
                        
                        Text(item.overview!)
                            .padding([.top, .trailing])
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                
                
                Spacer()
                
                
            }
            .frame(maxWidth: .infinity)
        }
        else {
            EmptyView()
        }
        
    }
    
    func formatRunningtime() -> String {
        let timeHMSFormatter: DateComponentsFormatter = {
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .brief
            formatter.allowedUnits = [.hour, .minute]
            return formatter
        }()
        
        let text = timeHMSFormatter.string(from: Double(item!.runTimeTicks! / 10_000_000)) ?? ""
        
        return text
    }
}
