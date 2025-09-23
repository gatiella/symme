// ios/Runner/AppDelegate.swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    private var blurEffectView: UIVisualEffectView?
    
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let screenProtectionChannel = FlutterMethodChannel(name: "com.gatiella.symmeapp/screen_protection",
                                                          binaryMessenger: controller.binaryMessenger)
        
        screenProtectionChannel.setMethodCallHandler({
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            switch call.method {
            case "enableScreenProtection":
                self.enableScreenProtection()
                result("Screen protection enabled")
            case "disableScreenProtection":
                self.disableScreenProtection()
                result("Screen protection disabled")
            default:
                result(FlutterMethodNotImplemented)
            }
        })
        
        // Enable screen protection by default
        enableScreenProtection()
        
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    private func enableScreenProtection() {
        // Prevent screenshots
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillResignActive),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        // Detect screen recording
        if #available(iOS 11.0, *) {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(screenCaptureDidChange),
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
        }
    }
    
    private func disableScreenProtection() {
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        
        if #available(iOS 11.0, *) {
            NotificationCenter.default.removeObserver(
                self,
                name: UIScreen.capturedDidChangeNotification,
                object: nil
            )
        }
        
        removeBlurEffect()
    }
    
    @objc private func applicationWillResignActive() {
        addBlurEffect()
    }
    
    @objc private func applicationDidBecomeActive() {
        removeBlurEffect()
    }
    
    @available(iOS 11.0, *)
    @objc private func screenCaptureDidChange() {
        if UIScreen.main.isCaptured {
            // Screen recording detected - show warning or blur screen
            addBlurEffect()
        } else {
            removeBlurEffect()
        }
    }
    
    private func addBlurEffect() {
        guard blurEffectView == nil else { return }
        
        let blurEffect = UIBlurEffect(style: .dark)
        blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView?.frame = window?.bounds ?? CGRect.zero
        blurEffectView?.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        if let blurView = blurEffectView {
            window?.addSubview(blurView)
        }
    }
    
    private func removeBlurEffect() {
        blurEffectView?.removeFromSuperview()
        blurEffectView = nil
    }
    
    override func applicationDidBecomeActive(_ application: UIApplication) {
        super.applicationDidBecomeActive(application)
        removeBlurEffect()
    }
}