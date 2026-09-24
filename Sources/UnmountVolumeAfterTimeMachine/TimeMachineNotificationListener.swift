//
// Created by Brian Henry on 6/9/23.
//
// Modified by Rui Ma on 24 Sep. 2026.
//
// TODO: It always starts with "Could not parse line:"
//

import Foundation
import OSLog
import SwiftTimeMachine

final class TimeMachineNotificationListener {

  private let logReader: TimeMachineLogReader
  let unmounter: Unmounter

  init(
    logReader: TimeMachineLogReader = TimeMachineLogReader(),
    unmounter: Unmounter = Unmounter()
  ) {
    self.logReader = logReader
    self.unmounter = unmounter

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(unmountVolume),
      name: TimeMachineLogReader.thinningNotification,
      object: logReader
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(unmountVolume),
      name: TimeMachineLogReader.completedBackupNotification,
      object: logReader
    )

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(unmountVolume),
      name: TimeMachineLogReader.completedBackupWithoutThinningNotification,
      object: logReader
    )
  }

  deinit {
    NotificationCenter.default.removeObserver(
      self,
      name: TimeMachineLogReader.thinningNotification,
      object: logReader
    )

    NotificationCenter.default.removeObserver(
      self,
      name: TimeMachineLogReader.completedBackupNotification,
      object: logReader
    )

    NotificationCenter.default.removeObserver(
      self,
      name: TimeMachineLogReader.completedBackupWithoutThinningNotification,
      object: logReader
    )
  }

  @objc func unmountVolume(notification: Notification) {
    guard notification.object as? TimeMachineLogReader != nil else {
      return
    }

    os_log("new Time Machine notification received")

    if let message = notification.userInfo?["message"] as? String {
      os_log("TimeMachine notification message: %{public}@", message)
    }

    os_log("Pausing 10 seconds")

    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
      let tmUtil = TmUtil()

      if tmUtil.status()?.running != false {
        os_log("failed to confirm backup is not still running (via tmUtil.status())")
        return
      }

      guard let destinationInfo = tmUtil.destinationInfo() else {
        os_log("failed to get tmUtil.destinationInfo() ")
        return
      }

      // Filter to only local destinations.
      // TODO: This should really be captured from the notification, not guessed from tmutil.
      let localDestinations = destinationInfo.destinations.filter { $0.kind == .local }

      guard let destinationMountPoint = localDestinations.first?.mountPoint else {
        os_log("failed to get destinationInfo.destinations.first?.mountPoint")
        return
      }

      self.unmounter.unmount(volume: destinationMountPoint)
    }
  }
}
