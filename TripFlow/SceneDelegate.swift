//
//  SceneDelegate.swift
//  TripFlow
//
//  Created by Tanish Aggarwal on 2026-07-28.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = SceneDelegate.makeRootTabBarController()
        window.makeKeyAndVisible()
        self.window = window
    }

    /// Root UITabBarController with 4 tabs, each wrapped in its own UINavigationController
    /// and pointing at the correct member storyboard reference.
    private static func makeRootTabBarController() -> UITabBarController {
        let tripsNav = navigationController(storyboardName: "TanishTrips", title: "My Trips", systemImageName: "list.bullet")
        let mapNav = navigationController(storyboardName: "NeelMapSettings", title: "Map", systemImageName: "map")
        let exploreNav = navigationController(storyboardName: "PrathamDetailExplore", title: "Explore", systemImageName: "safari")
        let settingsNav = navigationController(storyboardName: "NeelMapSettings", storyboardIdentifier: "SettingsVC", title: "Settings", systemImageName: "gearshape")

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [tripsNav, mapNav, exploreNav, settingsNav]
        return tabBarController
    }

    private static func navigationController(storyboardName: String, storyboardIdentifier: String? = nil, title: String, systemImageName: String) -> UINavigationController {
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        let rootViewController: UIViewController
        if let storyboardIdentifier {
            rootViewController = storyboard.instantiateViewController(withIdentifier: storyboardIdentifier)
        } else {
            rootViewController = storyboard.instantiateInitialViewController()!
        }

        let navigationController = UINavigationController(rootViewController: rootViewController)
        navigationController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: systemImageName), selectedImage: nil)
        return navigationController
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }


}
