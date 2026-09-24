//
// Created by Rui Ma on 24 Sep. 2026.
//

import Foundation
import OSLog

final class TimeMachineLogReader {

    static let completedBackupNotification = Notification.Name(
        "ie.brianhenryie.timemachinelog.aftercompletedbackup"
    )

    static let thinningNotification = Notification.Name(
        "ie.brianhenryie.timemachinelog.afterthinning"
    )

    private let queue = DispatchQueue(
        label: "UnmountVolumeAfterTimeMachine.timeMachineLogReader"
    )

    private var timer: DispatchSourceTimer?
    private var lastReadDate = Date().addingTimeInterval(-2)
    private var processedEntryKeys = [String: Date]()
    private let processor = TimeMachineLogProcessor()

    init() {
        queue.async { [weak self] in
            self?.startPolling()
        }
    }

    deinit {
        timer?.cancel()
    }

    private func startPolling() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(
            deadline: .now(),
            repeating: .seconds(1),
            leeway: .milliseconds(200)
        )
        timer.setEventHandler { [weak self] in
            self?.poll()
        }

        self.timer = timer
        timer.resume()

        os_log("Time Machine OSLogStore reader started")
    }

    private func poll() {
        do {
            let store = try OSLogStore(scope: .system)
            let position = store.position(
                date: lastReadDate.addingTimeInterval(-2)
            )
            let predicate = NSPredicate(
                format: "subsystem == %@",
                "com.apple.TimeMachine"
            )
            let entries = try store.getEntries(
                with: [],
                at: position,
                matching: predicate
            )

            for entry in entries {
                guard let logEntry = entry as? OSLogEntryLog else {
                    continue
                }

                let entryKey = [
                    String(logEntry.date.timeIntervalSince1970),
                    logEntry.process,
                    logEntry.category,
                    logEntry.composedMessage
                ].joined(separator: "|")

                guard processedEntryKeys.updateValue(logEntry.date, forKey: entryKey) == nil else {
                    continue
                }

                let entry = TimeMachineLogEntry(
                    message: logEntry.composedMessage,
                    isInfo: logEntry.level == .info
                )
                if let event = processor.process(entry) {
                    post(event: event)
                }
                lastReadDate = max(lastReadDate, logEntry.date)
            }

            // Keep a small overlap so entries written during a query are read again.
            lastReadDate = max(lastReadDate, Date().addingTimeInterval(-2))

            let processedEntryCutoffDate = Date().addingTimeInterval(-5)
            processedEntryKeys = processedEntryKeys.filter { _, entryDate in
                entryDate >= processedEntryCutoffDate
            }
        } catch {
            // Keep the timer alive so a transient OSLogStore failure can recover.
            os_log(
                .error,
                "Failed to read the system unified log store: %{public}@",
                error.localizedDescription
            )
        }
    }

    private func post(event: TimeMachineLogEvent) {
        switch event {
        case let .completedBackup(message):
            post(notification: Self.completedBackupNotification, message: message)
        case let .thinning(message):
            post(notification: Self.thinningNotification, message: message)
        }
    }

    private func post(notification: Notification.Name, message: String) {
        NotificationCenter.default.post(
            name: notification,
            object: self,
            userInfo: ["message": message]
        )
    }
}
