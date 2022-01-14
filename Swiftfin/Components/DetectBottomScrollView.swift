//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// https://stackoverflow.com/questions/56573373/swiftui-get-size-of-child

struct ChildSizeReader<Content: View>: View {
	@Binding
	var size: CGSize
	let content: () -> Content
	var body: some View {
		ZStack {
			content()
				.background(GeometryReader { proxy in
					Color.clear
						.preference(key: SizePreferenceKey.self, value: proxy.size)
				})
		}
		.onPreferenceChange(SizePreferenceKey.self) { preferences in
			self.size = preferences
		}
	}
}

struct SizePreferenceKey: PreferenceKey {
	typealias Value = CGSize
	static var defaultValue: Value = .zero

	static func reduce(value _: inout Value, nextValue: () -> Value) {
		_ = nextValue()
	}
}

struct ViewOffsetKey: PreferenceKey {
	typealias Value = CGFloat
	static var defaultValue = CGFloat.zero
	static func reduce(value: inout Value, nextValue: () -> Value) {
		value += nextValue()
	}
}

struct DetectBottomScrollView<Content: View>: View {
	private let spaceName = "scroll"

	@State
	private var wholeSize: CGSize = .zero
	@State
	private var scrollViewSize: CGSize = .zero
	@State
	private var previousDidReachBottom = false
	let content: () -> Content
	let didReachBottom: (Bool) -> Void

	init(content: @escaping () -> Content,
	     didReachBottom: @escaping (Bool) -> Void)
	{
		self.content = content
		self.didReachBottom = didReachBottom
	}

	var body: some View {
		ChildSizeReader(size: $wholeSize) {
			ScrollView {
				ChildSizeReader(size: $scrollViewSize) {
					content()
						.background(GeometryReader { proxy in
							Color.clear.preference(key: ViewOffsetKey.self,
							                       value: -1 * proxy.frame(in: .named(spaceName)).origin.y)
						})
						.onPreferenceChange(ViewOffsetKey.self,
						                    perform: { value in

						                    	if value >= scrollViewSize.height - wholeSize.height {
						                    		if !previousDidReachBottom {
						                    			previousDidReachBottom = true
						                    			didReachBottom(true)
						                    		}
						                    	} else {
						                    		if previousDidReachBottom {
						                    			previousDidReachBottom = false
						                    			didReachBottom(false)
						                    		}
						                    	}
						                    })
				}
			}
			.coordinateSpace(name: spaceName)
		}
	}
}
