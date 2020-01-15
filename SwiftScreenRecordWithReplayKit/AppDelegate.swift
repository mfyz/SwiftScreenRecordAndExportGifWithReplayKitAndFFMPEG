//
//  AppDelegate.swift
//  SwiftScreenRecordWithReplayKit
//
//  Created by Mehmet Fatih YILDIZ on 1/14/20.
//  Copyright © 2020 Mehmet Fatih YILDIZ. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		window = UIWindow(frame: UIScreen.main.bounds)
		
		let homeViewController = HomeViewController()
		let navigation = UINavigationController(rootViewController: homeViewController)
		window!.rootViewController = navigation
		window!.makeKeyAndVisible()

		return true
	}

}

