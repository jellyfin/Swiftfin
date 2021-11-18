//
 /*
  * SwiftFin is subject to the terms of the Mozilla Public
  * License, v2.0. If a copy of the MPL was not distributed with this
  * file, you can obtain one at https://mozilla.org/MPL/2.0/.
  *
  * Copyright 2021 Aiden Vigue & Jellyfin Contributors
  */

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
    let program: BaseItemDto?
}

final class LiveTVChannelsViewModel: ViewModel {
    
    @Published var channels = [BaseItemDto]()
    @Published var channelPrograms = [LiveTVChannelProgram]() {
        didSet {
            rows = []
            let rowChannels = channelPrograms.chunked(into: 4)
            for (index, rowChans) in rowChannels.enumerated() {
                rows.append(LiveTVChannelRow(section: index, items: rowChans.map { LiveTVChannelRowCell(item: $0) }))
            }
        }
    }
    @Published var rows = [LiveTVChannelRow]()
    private var programs = [BaseItemDto]()
    private var channelProgramsList = [BaseItemDto: [BaseItemDto]]()
    
    override init() {
        super.init()
        
        getChannels()
    }
    
    private func getGuideInfo() {
        LiveTvAPI.getGuideInfo()
            .trackActivity(loading)
            .sink(receiveCompletion: { [weak self] completion in
                self?.handleAPIRequestError(completion: completion)
            }, receiveValue: { [weak self] response in
                LogManager.shared.log.debug("Received Guide Info")
                guard let self = self else { return }
                self.getChannels()
            })
            .store(in: &cancellables)
    }
    
    private func getChannels() {
        LiveTvAPI.getLiveTvChannels(
            userId: SessionManager.main.currentLogin.user.id,
            startIndex: 0,
            limit: 500,
            enableImageTypes: [.primary],
            enableUserData: false,
            enableFavoriteSorting: true
        )
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
        guard channels.count > 0 else {
            LogManager.shared.log.debug("Cannot get programs, channels list empty. ")
            return
        }
        let channelIds = channels.compactMap { $0.id }
        
        let minEndDate = Date.now.addComponentsToDate(hours: -1)
        let maxStartDate = minEndDate.addComponentsToDate(days: 1)
        
        NSLog("*** maxStartDate: \(maxStartDate)")
        NSLog("*** minEndDate: \(minEndDate)")
        
        let getProgramsDto = GetProgramsDto(
            channelIds: channelIds,
            userId: SessionManager.main.currentLogin.user.id,
            maxStartDate: maxStartDate,
            minEndDate: minEndDate,
            sortBy: ["StartDate"],
            enableImages: true,
            enableTotalRecordCount: false,
            imageTypeLimit: 1,
            enableImageTypes: [.primary],
            enableUserData: false
        )
        
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
        let df = DateFormatter()
        df.dateFormat = "MM/dd h:mm ZZZ"
        for channel in self.channels {
           // NSLog("\n\(channel.name)")
            let prgs = self.programs.filter { item in
                item.channelId == channel.id
            }
            channelProgramsList[channel] = prgs
            
            var currentPrg: BaseItemDto?
            for prg in prgs {
                var startString = ""
                var endString = ""
                if let start = prg.startDate?.toLocalTime() {
                    startString = df.string(from: start)
                }
                if let end = prg.endDate?.toLocalTime() {
                    endString = df.string(from: end)
                }
                //NSLog("\(prg.name) - \(startString) to \(endString)")
                if let startDate = prg.startDate?.toLocalTime()		,
                   let endDate = prg.endDate?.toLocalTime(),
                   now.timeIntervalSinceReferenceDate > startDate.timeIntervalSinceReferenceDate &&
                    now.timeIntervalSinceReferenceDate < endDate.timeIntervalSinceReferenceDate {
                    currentPrg = prg
                }
            }
            
            channelPrograms.append(LiveTVChannelProgram(channel: channel, program: currentPrg))
        }
        return channelPrograms
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
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
    
    func toLocalTime() -> Date {
        let timezoneOffset = TimeZone.current.secondsFromGMT()
        let epochDate = self.timeIntervalSince1970
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        return Date(timeIntervalSince1970: timezoneEpochOffset)
    }
}
