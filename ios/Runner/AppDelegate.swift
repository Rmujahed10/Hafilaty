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
    GMSServices.provideAPIKey("AIzaSyASw9kOAjo6lWB5OX7oFFGU40CCGFPVJYY")
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}