import Foundation

protocol Records {
    func file(_ log: StripLog)
    func markFeed(url: String, mode: String)
    func raisePrimedFlag()
    func pull() -> StripLog
}

final class WardRecords: Records {

    private let fm = FileManager.default
    private let vaultDir: URL
    private let homeStore: UserDefaults
    private let suiteStore: UserDefaults

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.vaultDir = docs.appendingPathComponent(TilesVitals.monitorVault, isDirectory: true)
        if !fm.fileExists(atPath: vaultDir.path) {
            try? fm.createDirectory(at: vaultDir, withIntermediateDirectories: true)
        }
        self.homeStore = UserDefaults.standard
        self.suiteStore = UserDefaults(suiteName: TilesVitals.suiteMonitor) ?? .standard
    }

    private var stripURL: URL {
        vaultDir.appendingPathComponent(TilesVitals.stripFile)
    }

    func file(_ log: StripLog) {
        let noisy = NoisyLog(
            pulse: noiseMap(log.pulse),
            traces: noiseMap(log.traces),
            feedURL: log.feedURL,
            feedMode: log.feedMode,
            resting: log.resting,
            consentPaced: log.consentPaced,
            consentFlat: log.consentFlat,
            consentTapAt: log.consentTapAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970

        do {
            let data = try encoder.encode(noisy)
            try data.write(to: stripURL, options: .atomic)
        } catch {
            print("\(TilesVitals.logMark) Records file failed: \(error)")
        }

        for store in [suiteStore, homeStore] {
            store.set(log.consentPaced, forKey: TilesKey.consentPaced)
            store.set(log.consentFlat, forKey: TilesKey.consentFlat)
            if let date = log.consentTapAt {
                store.set(date.timeIntervalSince1970, forKey: TilesKey.consentTapAt)
            }
        }
    }

    func markFeed(url: String, mode: String) {
        suiteStore.set(url, forKey: TilesKey.feedURL)
        homeStore.set(url, forKey: TilesKey.feedURL)
        suiteStore.set(mode, forKey: TilesKey.feedMode)
    }

    func raisePrimedFlag() {
        suiteStore.set(true, forKey: TilesKey.primed)
        homeStore.set(true, forKey: TilesKey.primed)
    }

    func pull() -> StripLog {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970

        if fm.fileExists(atPath: stripURL.path),
           let data = try? Data(contentsOf: stripURL),
           let noisy = try? decoder.decode(NoisyLog.self, from: data) {
            return StripLog(
                pulse: cleanMap(noisy.pulse),
                traces: cleanMap(noisy.traces),
                feedURL: noisy.feedURL,
                feedMode: noisy.feedMode,
                resting: noisy.resting,
                consentPaced: noisy.consentPaced,
                consentFlat: noisy.consentFlat,
                consentTapAt: noisy.consentTapAt
            )
        }

        return pullFromMirror()
    }

    private func pullFromMirror() -> StripLog {
        let feedURL = homeStore.string(forKey: TilesKey.feedURL)
            ?? suiteStore.string(forKey: TilesKey.feedURL)
        let feedMode = suiteStore.string(forKey: TilesKey.feedMode)
        let primed = suiteStore.bool(forKey: TilesKey.primed)

        let paced = suiteStore.bool(forKey: TilesKey.consentPaced)
            || homeStore.bool(forKey: TilesKey.consentPaced)
        let flat = suiteStore.bool(forKey: TilesKey.consentFlat)
            || homeStore.bool(forKey: TilesKey.consentFlat)
        let tapTs = suiteStore.double(forKey: TilesKey.consentTapAt)
        let tapAt: Date? = tapTs > 0 ? Date(timeIntervalSince1970: tapTs) : nil

        return StripLog(
            pulse: [:],
            traces: [:],
            feedURL: feedURL,
            feedMode: feedMode,
            resting: !primed,
            consentPaced: paced,
            consentFlat: flat,
            consentTapAt: tapAt
        )
    }

    private func noiseMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = addNoise(pair.value) }
    }

    private func cleanMap(_ dict: [String: String]) -> [String: String] {
        dict.reduce(into: [:]) { acc, pair in acc[pair.key] = clean(pair.value) ?? pair.value }
    }

    private func addNoise(_ input: String) -> String {
        Data(input.utf8).base64EncodedString()
            .replacingOccurrences(of: "+", with: "%")
            .replacingOccurrences(of: "/", with: ".")
    }

    private func clean(_ input: String) -> String? {
        let restored = input
            .replacingOccurrences(of: "%", with: "+")
            .replacingOccurrences(of: ".", with: "/")
        guard let data = Data(base64Encoded: restored),
              let text = String(data: data, encoding: .utf8) else { return nil }
        return text
    }
}

struct NoisyLog: Codable {
    let pulse: [String: String]
    let traces: [String: String]
    let feedURL: String?
    let feedMode: String?
    let resting: Bool
    let consentPaced: Bool
    let consentFlat: Bool
    let consentTapAt: Date?
}
