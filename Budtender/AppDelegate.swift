//
//  AppDelegate.swift
//  Budtender
//
//  Created by raptor on 20/01/2018.
//  Copyright © 2018 raptor. All rights reserved.
//

import UIKit
import UserNotifications
import IQKeyboardManagerSwift
import Firebase
import GoogleSignIn
import FacebookCore
import Fabric
import Crashlytics

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        // keyboard manager
        IQKeyboardManager.shared.enable = true

        // fabric
        Fabric.with([Crashlytics.self, Answers.self])

        // firebase
        FirebaseApp.configure()
        GADMobileAds.configure(withApplicationID: "ca-app-pub-7651655738979324~1823222953")

        // facebook
        AppEventsLogger.activate(application)

        // push notification
        UNUserNotificationCenter.current().delegate = self
        registerForPushNotifications()

        // launch from notificaiton
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let _ = launchOptions?[.remoteNotification] as? [String: Any],
            let nav = storyboard.instantiateInitialViewController() as? UINavigationController,
            let start = nav.viewControllers.first as? StartVC {
            start.directMainVC = true
            window?.rootViewController = nav
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
        print("Device token for push notification >>> \(deviceTokenString) <<<")

        // upload to server
        UserDefaults.standard.set(true, forKey: StoreKey.refreshDeviceToken.rawValue)
        UserDefaults.standard.set(deviceTokenString, forKey: StoreKey.deviceToken.rawValue)
    }
}

// helper
extension AppDelegate {
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
            print("Notification request authorization permission >>> \(granted)")

            guard granted else { return }
            self.getNotificationSettings()
        }
    }

    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            print("Notification settings >>> \(settings)")

            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        print("Notification received >>> \(userInfo)")
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.sound, .alert, .badge])
    }
}
