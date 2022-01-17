//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct VLCPlayerChapterOverlayView: View {

	@ObservedObject
	var viewModel: VideoPlayerViewModel
	private let chapterImages: [URL]

	init(viewModel: VideoPlayerViewModel) {
		self.viewModel = viewModel
		self.chapterImages = viewModel.item.getChapterImage(maxWidth: 500)
	}

	@ViewBuilder
	private var mainBody: some View {
		ZStack(alignment: .bottom) {

			LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8), .black]),
			               startPoint: .top,
			               endPoint: .bottom)
				.ignoresSafeArea()
				.frame(height: 300)

			VStack {
				Spacer()

				VStack(alignment: .leading, spacing: 0) {

					L10n.chapters.text
						.font(.title3)
						.fontWeight(.bold)
						.padding(.leading)

					ScrollView(.horizontal, showsIndicators: false) {
						ScrollViewReader { reader in
							HStack {
								ForEach(0 ..< viewModel.chapters.count) { chapterIndex in
									VStack(alignment: .leading) {
										Button {
											viewModel.playerOverlayDelegate?.didSelectChapter(viewModel.chapters[chapterIndex])
										} label: {
											ImageView(src: chapterImages[chapterIndex])
												.cornerRadius(10)
												.frame(width: 150, height: 100)
												.overlay {
													if viewModel.chapters[chapterIndex] == viewModel.currentChapter {
														RoundedRectangle(cornerRadius: 6)
															.stroke(Color.jellyfinPurple, lineWidth: 4)
													}
												}
										}

										VStack(alignment: .leading, spacing: 5) {

											Text(viewModel.chapters[chapterIndex].name ?? L10n.noTitle)
												.font(.subheadline)
												.fontWeight(.semibold)
												.foregroundColor(.white)

											Text(viewModel.chapters[chapterIndex].timestampLabel)
												.font(.subheadline)
												.fontWeight(.semibold)
												.foregroundColor(Color(UIColor.systemBlue))
												.padding(.vertical, 2)
												.padding(.horizontal, 4)
												.background {
													Color(UIColor.darkGray).opacity(0.2).cornerRadius(4)
												}
										}
									}
									.id(viewModel.chapters[chapterIndex])
								}
							}
							.padding(.top)
							.onAppear {
								reader.scrollTo(viewModel.currentChapter)
							}
						}
					}
				}
				.padding(.bottom)
			}
		}
	}

	var body: some View {
		mainBody
			.edgesIgnoringSafeArea(.bottom)
			.contentShape(Rectangle())
			.onTapGesture {
				viewModel.playerOverlayDelegate?.didSelectChapters()
			}
	}
}
