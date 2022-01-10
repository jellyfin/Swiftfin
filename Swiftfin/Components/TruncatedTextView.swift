//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TruncatedTextView: View {

	@State
	private var truncated: Bool = false
	@State
	private var shrinkText: String
	private var text: String
	let font: UIFont
	let lineLimit: Int
	let seeMoreAction: () -> Void

	private var moreLessText: String {
		if !truncated {
			return ""
		} else {
			return "See More"
		}
	}

	init(_ text: String,
	     lineLimit: Int,
	     font: UIFont = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body),
	     seeMoreAction: @escaping () -> Void)
	{
		self.text = text
		self.lineLimit = lineLimit
		_shrinkText = State(wrappedValue: text)
		self.font = font
		self.seeMoreAction = seeMoreAction
	}

	var body: some View {
		VStack(alignment: .center) {
			Group {
				Text(shrinkText)
					.overlay {
						if truncated {
							LinearGradient(stops: [
								.init(color: .systemBackground.opacity(0), location: 0.5),
								.init(color: .systemBackground.opacity(0.8), location: 0.7),
								.init(color: .systemBackground, location: 1),
							],
							startPoint: .top,
							endPoint: .bottom)
						}
					}
			}
			.lineLimit(lineLimit)
			.background {
				// Render the limited text and measure its size
				Text(text)
					.lineLimit(lineLimit + 2)
					.background {
						GeometryReader { visibleTextGeometry in
							Color.clear
								.onAppear {
									let size = CGSize(width: visibleTextGeometry.size.width, height: .greatestFiniteMagnitude)
									let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
									var low = 0
									var heigh = shrinkText.count
									var mid = heigh
									while (heigh - low) > 1 {
										let attributedText = NSAttributedString(string: shrinkText, attributes: attributes)
										let boundingRect = attributedText.boundingRect(with: size,
										                                               options: NSStringDrawingOptions
										                                               	.usesLineFragmentOrigin,
										                                               context: nil)
										if boundingRect.size.height > visibleTextGeometry.size.height {
											truncated = true
											heigh = mid
											mid = (heigh + low) / 2

										} else {
											if mid == text.count {
												break
											} else {
												low = mid
												mid = (low + heigh) / 2
											}
										}
										shrinkText = String(text.prefix(mid))
									}

									if truncated {
										shrinkText = String(shrinkText.prefix(shrinkText.count - 2))
									}
								}
						}
					}
					.hidden()
			}
			.font(Font(font))

			if truncated {
				Button {
					seeMoreAction()
				} label: {
					Text(moreLessText)
				}
			}
		}
	}
}
