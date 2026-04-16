import Flutter
import UIKit
import GoogleMaps // 1. Add this line

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 2. Add this line with your actual API Key
    GMSServices.provideAPIKey("AIzaSyAjpBaL8BbBpYOcHdYePptrrVq6ipux-hc")

    GMSServices.provideAPIKey("AIzaSyCMOPv3-LdcAPUteoIZIE1jnePnP6oLPi8")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}