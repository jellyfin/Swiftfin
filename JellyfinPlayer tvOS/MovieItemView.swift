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

struct MovieItemView: View {
    let item: BaseItemDto
    @EnvironmentObject private var playbackInfo: VideoPlayerItem
    
    @State var actors: [BaseItemPerson] = [];
    @State var studio: String? = nil;
    @State var director: String? = nil;
    
    @Namespace private var namespace
    
    func onAppear() {
        actors = []
        director = nil
        studio = nil
        var actor_index = 0;
        item.people?.forEach { person in
            if(person.type == "Actor") {
                if(actor_index < 8) {
                    actors.append(person)
                }
                actor_index = actor_index + 1;
            }
            if(person.type == "Director") {
                director = person.name ?? ""
            }
        }
    }
    
    var body: some View {
        ZStack {
            ImageView(src: item.getBackdropImage(maxWidth: 1920), bh: item.getBackdropImageBlurHash())
                .opacity(0.4)
            ScrollView {
                LazyVStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.name ?? "")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            HStack {
                                if item.productionYear != nil {
                                    Text(String(item.productionYear!)).font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Text(item.getItemRuntime()).font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                if item.officialRating != nil {
                                    Text(item.officialRating!).font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                        .padding(EdgeInsets(top: 1, leading: 4, bottom: 1, trailing: 4))
                                        .overlay(RoundedRectangle(cornerRadius: 2)
                                            .stroke(Color.secondary, lineWidth: 1))
                                }
                            }
                            
                            HStack {
                                VStack(alignment: .trailing) {
                                    if(studio != nil) {
                                        Text("STUDIO")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text(studio!)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 40)
                                    }
                                    
                                    if(director != nil) {
                                        Text("DIRECTOR")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Text(director!)
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.secondary)
                                            .padding(.bottom, 40)
                                    }
                                    
                                    if(!actors.isEmpty) {
                                        Text("CAST")
                                            .font(.body)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        ForEach(actors, id: \.id) { person in
                                            Text(person.name!)
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                }
                                VStack(alignment: .leading) {
                                    Text(item.taglines?.first ?? "")
                                        .font(.body)
                                        .italic()
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Text(item.overview ?? "")
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    HStack {
                                        VStack {
                                            Button {
                                                playbackInfo.shouldShowPlayer = true
                                            } label: {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 40))
                                                    .padding(.vertical, 12).padding(.horizontal, 20)
                                            }
                                            Text("Favorite")
                                                .font(.caption)
                                        }
                                        VStack {
                                            Button {
                                                playbackInfo.itemToPlay = item
                                                playbackInfo.shouldShowPlayer = true
                                            } label: {
                                                Image(systemName: "play.fill")
                                                    .font(.system(size: 40))
                                                    .padding(.vertical, 12).padding(.horizontal, 20)
                                            }.prefersDefaultFocus(in: namespace)
                                            Text("Play")
                                                .font(.caption)
                                        }
                                        VStack {
                                            Button {
                                                playbackInfo.shouldShowPlayer = true
                                            } label: {
                                                Image(systemName: "eye.fill")
                                                    .font(.system(size: 40))
                                                    .padding(.vertical, 12).padding(.horizontal, 20)
                                            }
                                            Text("Mark Watched")
                                                .font(.caption)
                                        }
                                    }.padding(.top, 15)
                                    Spacer()
                                }
                            }.padding(.top, 50)
                        }
                        
                        VStack {
                            ImageView(src: item.getPrimaryImage(maxWidth: 450), bh: item.getPrimaryImageBlurHash())
                                .frame(width: 450, height: 675)
                                .cornerRadius(10)
                            Spacer()
                        }
                    }
                }.padding(EdgeInsets(top: 90, leading: 90, bottom: 0, trailing: 90))
            }
        }.onAppear(perform: onAppear)
        .focusScope(namespace)
    }
}
