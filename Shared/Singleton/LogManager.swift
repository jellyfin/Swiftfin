//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import Puppy

class LogManager {

	static let log = Puppy()

	static func setup() {

		let logsDirectory = getDocumentsDirectory().appendingPathComponent("logs", isDirectory: true)

		do {
			try FileManager.default.createDirectory(atPath: logsDirectory.path,
			                                        withIntermediateDirectories: true,
			                                        attributes: nil)
		} catch {
			// logs directory already created
		}

		let logFileURL = logsDirectory.appendingPathComponent("swiftfin_log.log")

		let fileRotationLogger = try! FileRotationLogger("org.jellyfin.swiftfin.logger.file-rotation",
		                                                 fileURL: logFileURL)
		fileRotationLogger.format = LogFormatter()

		let consoleLogger = ConsoleLogger("org.jellyfin.swiftfin.logger.console")
		consoleLogger.format = LogFormatter()

		log.add(fileRotationLogger, withLevel: .debug)
		log.add(consoleLogger, withLevel: .debug)
	}

	private static func getDocumentsDirectory() -> URL {
		// find all possible documents directories for this user
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)

		// just send back the first one, which ought to be the only one
		return paths[0]
	}
}

class LogFormatter: LogFormattable {
	func formatMessage(_ level: LogLevel, message: String, tag: String, function: String,
	                   file: String, line: UInt, swiftLogInfo: [String: String],
	                   label: String, date: Date, threadID: UInt64) -> String
	{
		let file = shortFileName(file).replacingOccurrences(of: ".swift", with: "")
		return " [\(level.emoji) \(level)] \(file)#\(line):\(function) \(message)"
	}
}
