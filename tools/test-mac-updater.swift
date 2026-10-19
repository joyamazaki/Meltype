// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 joyamazaki
import Foundation
@main struct Tests {
    static func main() {
        let key = Data(repeating: 1, count: 32).base64EncodedString()
        assert(MacUpdatePolicy.isConfigured(feed: MacUpdatePolicy.feedURL, publicKey: key))
        for feed in [nil, "http://example.com/feed", "https://user:pass@example.com/feed", "file:///tmp/feed"] as [String?] {
            assert(!MacUpdatePolicy.isConfigured(feed: feed, publicKey: key))
        }
        for bad in [nil, "", "invalid", Data(repeating: 0, count: 31).base64EncodedString()] as [String?] {
            assert(!MacUpdatePolicy.isConfigured(feed: MacUpdatePolicy.feedURL, publicKey: bad))
        }
        let home = URL(fileURLWithPath: "/tmp/test-home")
        assert(MacUpdatePolicy.isInstalled(home.appendingPathComponent("Library/Input Methods/Meltype.app"), home: home))
        assert(MacUpdatePolicy.isInstalled(URL(fileURLWithPath: "/Library/Input Methods/Meltype.app"), home: home))
        assert(!MacUpdatePolicy.isInstalled(home.appendingPathComponent("Downloads/Meltype.app"), home: home))
        let gate = UpdateRelaunchGate()
        var count = 0
        assert(!gate.postpone(ready: true) { count += 1 })
        assert(count == 0 && !gate.isPending)
        assert(gate.postpone(ready: false) { count += 1; gate.resumeIfReady(true) })
        gate.resumeIfReady(false)
        assert(count == 0 && gate.isPending)
        gate.resumeIfReady(true)
        gate.resumeIfReady(true)
        assert(count == 1 && !gate.isPending)
        assert(gate.postpone(ready: false) { count += 1 })
        gate.cancel()
        gate.resumeIfReady(true)
        assert(count == 1 && !gate.isPending)
        print("Update policy and deferred installation checks passed")
    }
}
