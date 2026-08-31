//
//  AppDelegate.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//  Updated on 8/26/26: data loading now happens on demand via the repository.
//

import UIKit

/// The app's `UIApplicationDelegate`. All actual UI setup happens in
/// `SceneDelegate` — this type only implements the delegate methods UIKit
/// requires, with no additional app-level state of its own.
@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    // MARK: UISceneSession Lifecycle

    /// Supplies the scene configuration used when a new scene session connects.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    /// Called when the user discards a scene session; there are no
    /// scene-specific resources for this app to release here.
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    }
}
