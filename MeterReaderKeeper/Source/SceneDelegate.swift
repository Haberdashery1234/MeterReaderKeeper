//
//  SceneDelegate.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//  Updated to wire up MeterRepositoryProtocol on 8/26/26.
//  Switched from Core Data to SwiftData on 8/26/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?
    
    /// The app's single repository instance, owning the SwiftData stack.
    ///
    /// Backed by an in-memory store instead of the real on-disk one when
    /// launched with `UITestAppLauncher.inMemoryStoreLaunchArgument` (see
    /// `MeterReaderKeeperUITests/TestSupport/UITestAppLauncher.swift`) —
    /// this is how the UI test target gets a guaranteed-empty database on
    /// every launch instead of accumulating state in the real store run
    /// over run. `#if DEBUG`-gated so a stray launch argument could never
    /// affect a release build.
    private let repository: MeterRepositoryProtocol = SceneDelegate.makeRepository()

    private static func makeRepository() -> MeterRepositoryProtocol {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestInMemoryStore") {
            return SwiftDataMeterRepository(inMemory: true)
        }
        #endif
        return SwiftDataMeterRepository()
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Setup coordinator pattern for navigation
        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true
        
        appCoordinator = AppCoordinator(navigationController: navigationController, repository: repository)
        appCoordinator?.start()
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Save data and release shared resources.
    }
}
