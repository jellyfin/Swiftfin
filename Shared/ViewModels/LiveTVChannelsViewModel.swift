//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUICollection

typealias LiveTVChannelRow = CollectionRow<Int, LiveTVChannelRowCell>

struct LiveTVChannelRowCell: Hashable {
	let id = UUID()
	let item: LiveTVChannelProgram
}

struct LiveTVChannelProgram: Hashable {
	let id = UUID()
	let channel: BaseItemDto
	let currentProgram: BaseItemDto?
    let programs: [BaseItemDto]
}

final class LiveTVChannelsViewModel: ViewModel {

	@Published
	var channels = [BaseItemDto]()
	@Published
	var channelPrograms = [LiveTVChannelProgram]() {
		didSet {
			rows = []
			let rowChannels = channelPrograms.chunked(into: 4)
			for (index, rowChans) in rowChannels.enumerated() {
				rows.append(LiveTVChannelRow(section: index, items: rowChans.map { LiveTVChannelRowCell(item: $0) }))
			}
		}
	}

	@Published
	var rows = [LiveTVChannelRow]()

	private var programs = [BaseItemDto]()
	private var channelProgramsList = [BaseItemDto: [BaseItemDto]]()
	private var timer: Timer?

	var timeFormatter: DateFormatter {
		let df = DateFormatter()
		df.dateFormat = "h:mm"
		return df
	}

	override init() {
		super.init()

		getChannels()
		startScheduleCheckTimer()
	}

	deinit {
		stopScheduleCheckTimer()
	}

	private func getGuideInfo() {
		LiveTvAPI.getGuideInfo()
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] _ in
				LogManager.shared.log.debug("Received Guide Info")
				guard let self = self else { return }
				self.getChannels()
			})
			.store(in: &cancellables)
	}

	func getChannels() {
		LiveTvAPI.getLiveTvChannels(userId: SessionManager.main.currentLogin.user.id,
		                            startIndex: 0,
		                            limit: 1000,
		                            enableImageTypes: [.primary],
		                            enableUserData: false,
		                            enableFavoriteSorting: true)
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				LogManager.shared.log.debug("Received \(response.items?.count ?? 0) Channels")
				guard let self = self else { return }
				self.channels = response.items ?? []
				self.getPrograms()
			})
			.store(in: &cancellables)
	}

	private func getPrograms() {
		// http://192.168.1.50:8096/LiveTv/Programs
		guard !channels.isEmpty else {
			LogManager.shared.log.debug("Cannot get programs, channels list empty. ")
			return
		}
		let channelIds = channels.compactMap(\.id)

		let minEndDate = Date.now.addComponentsToDate(hours: -1)
		let maxStartDate = minEndDate.addComponentsToDate(hours: 6)

		let getProgramsDto = GetProgramsDto(channelIds: channelIds,
		                                    userId: SessionManager.main.currentLogin.user.id,
		                                    maxStartDate: maxStartDate,
		                                    minEndDate: minEndDate,
		                                    sortBy: ["StartDate"],
		                                    enableImages: true,
		                                    enableTotalRecordCount: false,
		                                    imageTypeLimit: 1,
		                                    enableImageTypes: [.primary],
		                                    enableUserData: false)

		LiveTvAPI.getPrograms(getProgramsDto: getProgramsDto)
			.trackActivity(loading)
			.sink(receiveCompletion: { [weak self] completion in
				self?.handleAPIRequestError(completion: completion)
			}, receiveValue: { [weak self] response in
				LogManager.shared.log.debug("Received \(response.items?.count ?? 0) Programs")
				guard let self = self else { return }
				self.programs = response.items ?? []
				self.channelPrograms = self.processChannelPrograms()
			})
			.store(in: &cancellables)
	}

	private func processChannelPrograms() -> [LiveTVChannelProgram] {
		var channelPrograms = [LiveTVChannelProgram]()
		let now = Date()
		for channel in self.channels {
			let prgs = self.programs.filter { item in
				item.channelId == channel.id
			}
			DispatchQueue.main.async {
				self.channelProgramsList[channel] = prgs
			}

			var currentPrg: BaseItemDto?
			for prg in prgs {
				if let startDate = prg.startDate,
				   let endDate = prg.endDate,
				   now.timeIntervalSinceReferenceDate > startDate.timeIntervalSinceReferenceDate &&
				   now.timeIntervalSinceReferenceDate < endDate.timeIntervalSinceReferenceDate
				{
					currentPrg = prg
				}
			}

			channelPrograms.append(LiveTVChannelProgram(channel: channel, currentProgram: currentPrg, programs: prgs))
		}
		return channelPrograms
	}

	func startScheduleCheckTimer() {
		let date = Date()
		let calendar = Calendar.current
		var components = calendar.dateComponents([.era, .year, .month, .day, .hour, .minute], from: date)

		// Run on 10th min of every hour
		guard let minute = components.minute else { return }
		components.second = 0
		components.minute = minute + (10 - (minute % 10))

		guard let nextMinute = calendar.date(from: components) else { return }

		if let existingTimer = timer {
			existingTimer.invalidate()
		}
		timer = Timer(fire: nextMinute, interval: 60 * 10, repeats: true) { [weak self] _ in
			guard let self = self else { return }
			LogManager.shared.log.debug("LiveTVChannels schedule check...")
			DispatchQueue.global(qos: .background).async {
				let newChanPrgs = self.processChannelPrograms()
				DispatchQueue.main.async {
					self.channelPrograms = newChanPrgs
				}
			}
		}
		if let timer = timer {
			RunLoop.main.add(timer, forMode: .default)
		}
	}

	func stopScheduleCheckTimer() {
		timer?.invalidate()
	}

	func fetchVideoPlayerViewModel(item: BaseItemDto, completion: @escaping (VideoPlayerViewModel) -> Void) {
		item.createLiveTVVideoPlayerViewModel()
			.sink { completion in
				self.handleAPIRequestError(completion: completion)
			} receiveValue: { videoPlayerViewModels in
				if let viewModel = videoPlayerViewModels.first {
					completion(viewModel)
				}
			}
			.store(in: &self.cancellables)
	}
}

extension Array {
	func chunked(into size: Int) -> [[Element]] {
		stride(from: 0, to: count, by: size).map {
			Array(self[$0 ..< Swift.min($0 + size, count)])
		}
	}
}

extension Date {
	func addComponentsToDate(seconds sec: Int? = nil, minutes min: Int? = nil, hours hrs: Int? = nil, days d: Int? = nil) -> Date {
		var dc = DateComponents()
		if let sec = sec {
			dc.second = sec
		}
		if let min = min {
			dc.minute = min
		}
		if let hrs = hrs {
			dc.hour = hrs
		}
		if let d = d {
			dc.day = d
		}
		return Calendar.current.date(byAdding: dc, to: self)!
	}

	func midnightUTCDate() -> Date {
		var dc: DateComponents = Calendar.current.dateComponents([.year, .month, .day], from: self)
		dc.hour = 0
		dc.minute = 0
		dc.second = 0
		dc.nanosecond = 0
		dc.timeZone = TimeZone(secondsFromGMT: 0)
		return Calendar.current.date(from: dc)!
	}
}
