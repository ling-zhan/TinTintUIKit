//
//  AppDelegate.swift
//  TinTintUIKit
//
//  Created by Ling Zhan on 2024/12/16.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.toHomeViewController()
        return true
    }
    
    func toHomeViewController() {
        let homeViewController = HomeViewController()
        window?.rootViewController = UINavigationController(rootViewController: homeViewController)
        window?.makeKeyAndVisible()
    }

}

