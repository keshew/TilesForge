import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class TileForgeAppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var switchboard = Switchboard(host: self)

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        switchboard.dispatch(.wake)

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            switchboard.dispatch(.page(remote))
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        switchboard.dispatch(.enrol(deviceToken))
    }




    @objc private func onActivation() {
        switchboard.dispatch(.beat)
    }
}

extension TileForgeAppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { [weak self] token, err in
            guard err == nil, let token else { return }
            self?.switchboard.dispatch(.token(token))
        }
    }
}

extension TileForgeAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        switchboard.dispatch(.page(notification.request.content.userInfo))
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        switchboard.dispatch(.page(response.notification.request.content.userInfo))
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        switchboard.dispatch(.page(userInfo))
        completionHandler(.newData)
    }
}

extension TileForgeAppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        switchboard.dispatch(.pulse(data))
    }

    func onConversionDataFail(_ error: Error) {
        switchboard.dispatch(.pulse([
            "error": true,
            "error_desc": error.localizedDescription
        ]))
    }

    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        switchboard.dispatch(.traces(link.clickEvent))
    }
}

enum BoardSignal {
    case wake
    case beat
    case enrol(Data)
    case token(String)
    case pulse([AnyHashable: Any])
    case traces([AnyHashable: Any])
    case page([AnyHashable: Any])
}

final class Switchboard {

    private weak var host: TileForgeAppDelegate?
    private let splice = Splice()
    private let intake = Intake()

    init(host: TileForgeAppDelegate) {
        self.host = host
    }

    func dispatch(_ signal: BoardSignal) {
        switch signal {
        case .wake:
            bringUp()
        case .beat:
            quicken()
        case .enrol(let token):
            Messaging.messaging().apnsToken = token
        case .token(let token):
            UserDefaults.standard.set(token, forKey: TilesKey.fcm)
            UserDefaults.standard.set(token, forKey: TilesKey.push)
            UserDefaults(suiteName: TilesVitals.suiteMonitor)?.set(token, forKey: "shared_fcm")
        case .pulse(let data):
            splice.takePulse(data)
        case .traces(let data):
            splice.takeTraces(data)
        case .page(let payload):
            intake.absorb(payload)
        }
    }

    private func bringUp() {
        FirebaseApp.configure()

        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = TilesVitals.leadKey
        sdk.appleAppID = TilesVitals.appCode
        sdk.delegate = host
        sdk.deepLinkDelegate = host
        sdk.isDebug = false

        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
        UNUserNotificationCenter.current().delegate = host
    }

    private func quicken() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

final class Splice {

    private var pulseBuffer: [AnyHashable: Any] = [:]
    private var traceBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: DispatchSourceTimer?

    func takePulse(_ data: [AnyHashable: Any]) {
        pulseBuffer = data
        armFuse()
        if !traceBuffer.isEmpty { weld() }
    }

    func takeTraces(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: TilesKey.primed) else { return }
        traceBuffer = data
        NotificationCenter.default.post(
            name: .tracesArrived,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        fuseTimer?.cancel()
        if !pulseBuffer.isEmpty { weld() }
    }

    private func armFuse() {
        fuseTimer?.cancel()
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + 2.5)
        timer.setEventHandler { [weak self] in self?.weld() }
        fuseTimer = timer
        timer.resume()
    }

    private func weld() {
        fuseTimer?.cancel()
        fuseTimer = nil

        var merged = pulseBuffer
        for (k, v) in traceBuffer {
            let tag = "deep_\(k)"
            if merged[tag] == nil { merged[tag] = v }
        }

        NotificationCenter.default.post(
            name: .pulseArrived,
            object: nil,
            userInfo: ["conversionData": merged]
        )
    }
}

final class Intake {

    func absorb(_ payload: [AnyHashable: Any]) {
        guard let url = sniff(payload) else { return }
        UserDefaults.standard.set(url, forKey: TilesKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .scopeReload,
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }

    private func sniff(_ payload: [AnyHashable: Any]) -> String? {
        func dig(_ node: [AnyHashable: Any], _ keys: ArraySlice<String>) -> String? {
            guard let head = keys.first else { return nil }
            if keys.count == 1 { return node[head] as? String }
            guard let child = node[head] as? [AnyHashable: Any] else { return nil }
            return dig(child, keys.dropFirst())
        }

        let trails: [[String]] = [["url"], ["data", "url"], ["aps", "data", "url"], ["custom", "url"]]
        return trails.compactMap { dig(payload, $0[...]) }.first
    }
}
