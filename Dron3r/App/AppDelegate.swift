//
//  AppDelegate.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate
{
	var window: UIWindow?

	override init()
	{
		// seed drand48(), so it generates different random numbers on different app runs
		srand48(time(nil))

		do
		{
			// give the server layer access to a Domain Model

		#if SEPARATE_APPS_FOR_SERVER_AND_CLIENTS // see comments for the ObjectStore class
			let objectStore = ObjectStore.sharedInstance
		#else
			let objectStore = ObjectStore()
		#endif

			server = Server(address: Config.Server.Address,
				/* UDP */ inPort: Config.Server.InPort, /* WebSockets */ outPort: Config.Server.OutPort,
					using: objectStore)
		}
		
	#if DEBUG
		// a SimulatedDrone, as opposed to a Drone, allows for direct setting of location, altitude and speed
		//
		// WARNING: DO NOT USE IN PRODUCTION CODE
		//
		drones = Client()
	#endif
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool
	{
		// override point for customization after application launch
		
		do
		{
			// just traversing some uninteresting iOS app structure, a DashboardViewController inside a UINavigationController
			
			let navigationController = window!.rootViewController as! UINavigationController
			
			let injectedViewController =
				navigationController.viewControllers.filter { $0 is DashboardViewController }.first!
					as! DashboardViewController

			// dependency inversion, set externally, e.g. in application(_:didFinishLaunchingWithOptions:),
			// also possible in: prepare(for segue: UIStoryboardSegue, sender: Any?)

			// give the UI layer access to a Domain Model
			
		#if SEPARATE_APPS_FOR_SERVER_AND_CLIENTS // see comments for the ObjectStore class
			let objectStore = ObjectStore.sharedInstance
		#else
			let objectStore = ObjectStore()
		#endif

			injectedViewController.objectStore = objectStore
		}
		
		do
		{
			// start the server on a background thread
			try server.start(priority: .background)
			
			// start the client (a set of simulated drones)
			drones.fly()
		}
		catch // any Error
		{
			let message = "app: could not start the server [\(error)]"
			Logger.log(message, severity: .error)

			// even if the server does not start successfully, present app UI (and a debug console) anyway
		}
		
		return true
	}

	func applicationWillResignActive(_ application: UIApplication)
	{
	}

	func applicationDidEnterBackground(_ application: UIApplication)
	{
	}

	func applicationWillEnterForeground(_ application: UIApplication)
	{
	}

	func applicationDidBecomeActive(_ application: UIApplication)
	{
	}

	func applicationWillTerminate(_ application: UIApplication)
	{
		// called when the application is about to terminate

		drones.halt()
		server.stop()
	}

	// MARK: - private
	
	private let server: Server
	
#if DEBUG
	// a SimulatedDrone, as opposed to a Drone, allows for direct setting of location, altitude and speed
	//
	// WARNING: DO NOT USE IN PRODUCTION CODE
	//
	private let drones: Client
#endif
}
