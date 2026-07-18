//
//  UpdateManager.swift
//  OSX
//
//  Created by Jeong YunWon on 01/01/2019.
//  Copyright © 2019 youknowone.org. All rights reserved.
//

import Alamofire
import Foundation
import GureumCore

class UpdateManager {
  static let shared = UpdateManager()

  struct UpdateInfo: Decodable {
    let version: String
    let description: String
    let url: String

    enum CodingKeys: String, CodingKey {
      case version
      case description
      case url
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      version = try container.decode(String.self, forKey: .version)
      description = try container.decode(String.self, forKey: .description)
      let urlString = try container.decode(String.self, forKey: .url)
      // Defense-in-depth: only allow web schemes before any NSWorkspace.open.
      guard let parsed = URL(string: urlString),
        let scheme = parsed.scheme?.lowercased(),
        scheme == "http" || scheme == "https"
      else {
        throw DecodingError.dataCorruptedError(
          forKey: .url,
          in: container,
          debugDescription: "Update URL must use http or https scheme"
        )
      }
      url = urlString
    }
  }

  struct VersionInfo {
    let current: String? = Bundle.main.version
    let update: UpdateInfo
    let experimental: Bool
  }

  func requestVersionInfo(mode: UpdateMode, _ done: @escaping ((VersionInfo?) -> Void)) {
    let url: URL
    switch mode {
    case .stable:
      url = URL(string: "https://gureum.io/version.json")!
    case .experimental:
      url = URL(string: "https://gureum.io/version-experimental.json")!
    }
    var urlRequest = URLRequest(url: url)
    urlRequest.timeoutInterval = 15.0
    urlRequest.cachePolicy = .reloadIgnoringCacheData

    let request = AF.request(urlRequest)
    //        request.responseJSON {
    //            data in
    //            print("data!", data)
    //        }
    request.validate().responseDecodable(of: UpdateInfo.self) { response in
      guard let update = response.value else { return done(nil) }
      let version = VersionInfo(update: update, experimental: mode == .experimental)
      done(version)
    }
  }

  func requestAutoUpdateVersionInfo(_ done: @escaping ((VersionInfo?) -> Void)) {
    guard let mode = Configuration.shared.updateMode else {
      done(nil)
      return
    }
    requestVersionInfo(mode: mode, done)
  }

  class func notifyUpdate(info: VersionInfo) {
    let notification = NSUserNotification()
    var title = "구름 입력기 업데이트 알림"
    if info.experimental {
      title += " (실험 버전)"
    }
    notification.title = title
    notification.hasActionButton = true
    notification.hasReplyButton = false
    notification.actionButtonTitle = "업데이트"
    notification.otherButtonTitle = "취소"
    notification.informativeText =
      "최신 버전: \(info.update.version) 현재 버전: \(info.current ?? "-")\n\(info.update.description)"
    notification.userInfo = ["url": info.update.url]

    NSUserNotificationCenter.default.deliver(notification)
  }

  func notifyUpdateIfNeeded() {
    requestAutoUpdateVersionInfo { info in
      guard let info = info else {
        return
      }
      // CFBundleVersion is dotted (e.g. 1.13.2); ignore -experimental/-rc for ordering.
      // Notify only when remote is newer — inequality alone false-notifies on older remotes/dev builds.
      if let current = info.current {
        let remoteCore = String(info.update.version.prefix(while: { $0 != "-" }))
        let currentCore = String(current.prefix(while: { $0 != "-" }))
        guard remoteCore.compare(currentCore, options: .numeric) == .orderedDescending else {
          return
        }
      }
      UpdateManager.notifyUpdate(info: info)
    }
  }
}
