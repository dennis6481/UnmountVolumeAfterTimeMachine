// Modified by Rui Ma on 24 Sep. 2026.

import XCTest
@testable import UnmountVolumeAfterTimeMachine

final class UnmountVolumeAfterTimeMachineTests: XCTestCase {

    // Verifies that the macOS 27-style fixture remains a supported real-log sample.
    func testMacOS27FixtureProducesTheExpectedCompletionEvent() throws {
        let processor = TimeMachineLogProcessor()
        let events = try fixtureEntries().compactMap { processor.process($0) }

        XCTAssertEqual(
            events,
            [.completedBackup(message: "Mountpoint '/Volumes/TestBackup' is still valid")]
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
