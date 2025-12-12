import Foundation
import SwiftUI

protocol NetworkError: LocalizedError, Displayable, SystemImageable {
    var statusCode: Int? { get }
    var isRetryable: Bool { get }
    var retryAfter: TimeInterval? { get }
}
