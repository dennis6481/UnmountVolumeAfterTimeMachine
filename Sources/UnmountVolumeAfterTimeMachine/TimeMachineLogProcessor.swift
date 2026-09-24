//
// TimeMachineLogProcessor.swift
//
// Modified by Rui Ma on 24 Sep. 2026.
//

import Foundation

struct TimeMachineLogEntry {
    let message: String
    let isInfo: Bool

    init(message: String, isInfo: Bool = true) {
        self.message = message
        self.isInfo = isInfo
    }
}

enum TimeMachineLogEvent: Equatable {
    case completedBackup(message: String)
    case thinning(message: String)
    case completedBackupWithoutThinning(message: String)
}

final class TimeMachineLogProcessor {
    private var previousInfoMessage: String?

    func process(_ logEntry: TimeMachineLogEntry) -> TimeMachineLogEvent? {
        let message = logEntry.message

        guard message.range(
            of: #"Mountpoint '(/Volumes/.*?)' is still valid"#,
            options: .regularExpression
        ) != nil else {
            if logEntry.isInfo {
                previousInfoMessage = message
            }
            return nil
        }

        let completedBackupDetected = previousInfoMessage?.contains("Completed backup") == true
            || previousInfoMessage?.contains("Successfully completed backing up") == true
        let thinningDetected = previousInfoMessage?.starts(with: "Thinning") == true

        let event: TimeMachineLogEvent?
        if completedBackupDetected {
            event = .completedBackup(message: message)
        } else if thinningDetected {
            event = .thinning(message: message)
        } else if message.starts(with: "Mountpoint") && thinningDetected {
            event = .completedBackupWithoutThinning(message: message)
        } else {
            event = nil
        }

        if logEntry.isInfo {
            previousInfoMessage = message
        }

        return event
    }
}
