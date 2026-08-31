//
//  SceneDelegate.swift
//  MeterReaderKeeper
//
//  Created by Christian Grise on 4/30/21.
//  Updated to wire up MeterRepositoryProtocol on 8/26/26.
//  Migrated to SwiftData on 8/26/26.
//

import UIKit

/// The app's single `UIWindowSceneDelegate`. Owns the app's window and
/// repository instance, and starts the `AppCoordinator` that drives all
/// navigation.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    /// The app's single window, created when the scene connects.
    var window: UIWindow?
    /// The root coordinator, started in `scene(_:willConnectTo:options:)`.
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

    /// Builds the app's repository — an in-memory `SwiftDataMeterRepository`
    /// when launched with the `-UITestInMemoryStore` launch argument (see
    /// `MeterReaderKeeperUITests/TestSupport/UITestAppLauncher.swift`), so UI
    /// tests always start from an empty database instead of accumulating
    /// state in the real on-disk store run over run; the real on-disk store
    /// otherwise. The launch-argument check is `#if DEBUG`-gated so it can
    /// never affect a release build.
    private static func makeRepository() -> MeterRepositoryProtocol {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-UITestInMemoryStore") {
            return SwiftDataMeterRepository(inMemory: true)
        }
        #endif
        return SwiftDataMeterRepository()
    }

    /// Creates the app's window and navigation controller, then starts the
    /// `AppCoordinator` that drives all navigation from there.
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        let navigationController = UINavigationController()
        navigationController.navigationBar.prefersLargeTitles = true

        appCoordinator = AppCoordinator(navigationController: navigationController, repository: repository)
        appCoordinator?.start()

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // No scene-specific resources to release.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // No work needed on activation.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // No work needed on deactivation.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // No work needed on foregrounding.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // No work needed on backgrounding — SwiftData saves happen
        // explicitly per repository call, not on a scene-lifecycle hook.
    }
}
