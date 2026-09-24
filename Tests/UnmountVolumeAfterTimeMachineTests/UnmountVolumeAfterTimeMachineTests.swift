// Modified by Rui Ma on 24 Sep. 2026.

import XCTest
@testable import UnmountVolumeAfterTimeMachine

final class UnmountVolumeAfterTimeMachineTests: XCTestCase {
    func testApplicationText() {
        XCTAssertEqual(
            UnmountVolumeAfterTimeMachine().text,
            "UnmountVolumeAfterTimeMachine started!"
        )
    }

    func testMountpointWithoutPrecedingCompletionOrThinningDoesNotProduceAnEvent() {
        let processor = TimeMachineLogProcessor()

        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(message: "Mountpoint '/Volumes/TestBackup' is still valid")
            )
        )
    }

    func testMountpointOutsideVolumesDoesNotProduceAnEvent() {
        let processor = TimeMachineLogProcessor()

        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(
                    message: "Completed backup"
                )
            )
        )
        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(
                    message: "Mountpoint '/System/Volumes/Backup' is still valid"
                )
            )
        )
    }

    func testNonInfoMessageDoesNotBecomePreviousInfoMessage() {
        let processor = TimeMachineLogProcessor()

        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(
                    message: "Successfully completed backing up 2.83 GB to '/Volumes/TestBackup'",
                    isInfo: false
                )
            )
        )
        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(message: "Mountpoint '/Volumes/TestBackup' is still valid")
            )
        )
    }

    func testInterveningInfoMessageClearsThinningMatch() {
        let processor = TimeMachineLogProcessor()

        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(
                    message: "Thinning 1 backups"
                )
            )
        )
        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(message: "Another Time Machine info message")
            )
        )
        XCTAssertNil(
            processor.process(
                TimeMachineLogEntry(
                    message: "Mountpoint '/Volumes/TestBackup' is still valid"
                )
            )
        )
    }

    private func fixtureEntries() throws -> [TimeMachineLogEntry] {
        let url = try XCTUnwrap(
            Bundle.module.url(
                forResource: "TimeMachineKeyLogs",
                withExtension: "txt",
                subdirectory: "Fixtures"
            )
        )
        let fixture = try String(contentsOf: url, encoding: .utf8)

        return fixture
            .split(whereSeparator: \.isNewline)
            .compactMap { line in
                guard line.hasPrefix("message: ") else {
                    return nil
                }
                return TimeMachineLogEntry(message: String(line.dropFirst("message: ".count)))
            }
    }
}
