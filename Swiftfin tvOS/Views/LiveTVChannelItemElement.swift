//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LiveTVChannelItemElement: View {
	@FocusState
	private var focused: Bool
	@State
	private var loading: Bool = false
	@State
	private var isFocused: Bool = false

	var channel: BaseItemDto
	var program: BaseItemDto?
	var startString = " "
	var endString = " "
	var progressPercent = Double(0)
	var onSelect: (@escaping (Bool) -> Void) -> Void

	private var detailText: String {
		guard let program = program else {
			return ""
		}
		var text = ""
		if let season = program.parentIndexNumber,
		   let episode = program.indexNumber
		{
			text.append("\(season)x\(episode) ")
		} else if let episode = program.indexNumber {
			text.append("\(episode) ")
		}
		if let title = program.episodeTitle {
			text.append("\(title) ")
		}
		if let year = program.productionYear {
			text.append("\(year) ")
		}
		if let rating = program.officialRating {
			text.append("\(rating)")
		}
		return text
	}

	var body: some View {
		ZStack {
			VStack {
				HStack {
					Text(channel.number ?? "")
						.font(.footnote)
						.frame(alignment: .leading)
						.padding()
					Spacer()
				}.frame(alignment: .top)
				Spacer()
			}
			VStack {
				ImageView(channel.getPrimaryImage(maxWidth: 128))
					.aspectRatio(contentMode: .fit)
					.frame(width: 128, alignment: .center)
					.padding(.init(top: 8, leading: 0, bottom: 0, trailing: 0))
				Text(channel.name ?? "?")
					.font(.footnote)
					.lineLimit(1)
					.frame(alignment: .center)
				Text(program?.name ?? L10n.notAvailableSlash)
					.font(.body)
					.lineLimit(1)
					.foregroundColor(.green)
				Text(detailText)
					.font(.body)
					.lineLimit(1)
					.foregroundColor(.green)
				Spacer()
				HStack(alignment: .bottom) {
					VStack {
						Spacer()
						HStack {
							Text(startString)
								.font(.footnote)
								.lineLimit(1)
								.frame(alignment: .leading)

							Spacer()

							Text(endString)
								.font(.footnote)
								.lineLimit(1)
								.frame(alignment: .trailing)
						}
						GeometryReader { gp in
							ZStack(alignment: .leading) {
								RoundedRectangle(cornerRadius: 6)
									.fill(Color.gray)
									.opacity(0.4)
									.frame(minWidth: 100, maxWidth: .infinity, minHeight: 12, maxHeight: 12)
								RoundedRectangle(cornerRadius: 6)
									.fill(Color.jellyfinPurple)
									.frame(width: CGFloat(progressPercent * gp.size.width), height: 12)
							}
							.frame(alignment: .bottom)
						}
					}
				}
			}
			.padding()
			.opacity(loading ? 0.5 : 1.0)

			if loading {
				ProgressView()
			}
		}
		.overlay(RoundedRectangle(cornerRadius: 20)
			.stroke(isFocused ? Color.blue : Color.clear, lineWidth: 4))
		.cornerRadius(20)
		.scaleEffect(isFocused ? 1.1 : 1)
		.focusable(true)
		.focused($focused)
		.onChange(of: focused) { foc in
			withAnimation(.linear(duration: 0.15)) {
				self.isFocused = foc
			}
		}
		.onLongPressGesture(minimumDuration: 0.01, pressing: { _ in }) {
			onSelect { loadingState in
				loading = loadingState
			}
		}
	}
}
