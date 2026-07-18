//
//  GureumAppDelegate.swift
//  Gureum
//
//  Created by 혜원 on 2018. 8. 27..
//  Copyright © 2018 youknowone.org. All rights reserved.
//

import Cocoa
import Firebase
import Foundation
import GureumCore
import Hangul

class NotificationCenterDelegate: NSObject, NSUserNotificationCenterDelegate {
  static let appDefault = NotificationCenterDelegate()

  func userNotificationCenter(
    _: NSUserNotificationCenter, didActivate notification: NSUserNotification
  ) {
    guard let userInfo = notification.userInfo else {
      return
    }
    guard let download = userInfo["url"] as? String else {
      return
    }
    var updating = false
    switch notification.activationType {
    case .actionButtonClicked, .contentsClicked:
      updating = true
    default:
      break
    }
    if updating, let url = URL(string: download) {
      NSWorkspace.shared.open(url)
    }
    answers.logUpdateNotification(updating: updating)
  }
}

class GureumAppDelegate: NSObject, NSApplicationDelegate, GureumApplicationDelegate {
  @IBOutlet var menu: NSMenu!

  let configuration = Configuration.shared
  let notificationCenterDelegate = NotificationCenterDelegate()

  func applicationDidFinishLaunching(_: Notification) {
    FirebaseApp.configure()
    UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])

    NSUserNotificationCenter.default.delegate = notificationCenterDelegate
    let notificationCenter = NSUserNotificationCenter.default
    #if DEBUG
      let notification = NSUserNotification()
      notification.title = "디버그 빌드 알림"
      notification.hasActionButton = false
      notification.hasReplyButton = false
      notification.informativeText = "이 버전은 디버그 빌드입니다. 키 입력이 로그로 남을 수 있어 안전하지 않습니다."
      notificationCenter.deliver(notification)
      // Fabric.with([Answers.self])
      preferencesWindow.showWindow(nil)
    #else
      // Fabric.with([Crashlytics.self, Answers.self])
    #endif

    UpdateManager.shared.notifyUpdateIfNeeded()

    // 입력 모니터링 권한 요청
    if #available(macOS 10.15, *) {
      IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
    }

    // IMKServer를 띄워야만 입력기가 동작한다
    _ = InputMethodServer.shared

    // Fabric/Answers 제거 후 AnswersHelper는 no-op stub. 매시간 uptime 타이머·launch 로깅 제거.
    // (잔여 answers.logMenu / logUpdateNotification 및 AnswersHelper.swift 전면 삭제는 후속 정리)

    watcher.reloadConfiguration()
  }
}
