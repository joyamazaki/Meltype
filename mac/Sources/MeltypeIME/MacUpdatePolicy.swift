// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 joyamazaki

import Foundation

struct MacUpdatePolicy {
    static let feedURL = "https://github.com/yksr-melt/Meltype/releases/latest/download/appcast.xml"

    static func isConfigured(feed: String?, publicKey: String?) -> Bool {
        guard let feed, let url = URL(string: feed), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil,
              let publicKey, Data(base64Encoded: publicKey)?.count == 32 else { return false }
        return true
    }

    static func isInstalled(_ app: URL, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> Bool {
        let parent = app.standardizedFileURL.resolvingSymlinksInPath().deletingLastPathComponent()
        return [home.appendingPathComponent("Library/Input Methods"), URL(fileURLWithPath: "/Library/Input Methods")]
            .map { $0.standardizedFileURL.resolvingSymlinksInPath().path }.contains(parent.path)
    }
}

/// Keep the install continuation pending until the active input client has committed its text.
final class UpdateRelaunchGate {
    private var continuation: (() -> Void)?
    var isPending: Bool { continuation != nil }

    func postpone(ready: Bool, continuation: @escaping () -> Void) -> Bool {
        guard !ready else { return false }
        self.continuation = continuation
        return true
    }

    func resumeIfReady(_ ready: Bool) {
        guard ready, let resume = continuation else { return }
        continuation = nil
        resume()
    }

    func cancel() { continuation = nil }
}
