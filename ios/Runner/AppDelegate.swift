import UIKit
import Flutter
import Stripe
import Firebase

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Firebase
    FirebaseApp.configure()

    // Stripe
    if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let publishableKey = plist["StripePublishableKey"] as? String {
      StripeAPI.defaultPublishableKey = publishableKey
    }

    GeneratedPluginRegistrant.register(with: self)

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Deep linking para Stripe
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {

    let stripeHandled = StripeAPI.handleURLCallback(with: url)

    if (stripeHandled) {
      return true
    } else {
      return super.application(app, open: url, options: options)
    }
  }

  // Push notifications
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    // Handle Firebase push notification
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
  }
}