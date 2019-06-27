//
//  ViewController.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import UIKit

// https://github.com/daltoniam/Starscream
// Websockets [client] in Swift for iOS and OSX
//
import Starscream

// SPEC: "the dashboard should be a simple single-page application displaying the list of active drones"

// TODO: migrate to RxSwift (RxTableViewSectionedReloadDataSource), ReactiveX for Swift, https://github.com/ReactiveX/RxSwift

class DashboardViewController: UITableViewController, WebSocketDelegate
{
	// dependency inversion, set externally, e.g. in application(_:didFinishLaunchingWithOptions:),
	// also possible in: prepare(for segue: UIStoryboardSegue, sender: Any?)
	//
	// WARNING: this should be implemented with WebSockets callbacks, not direct object sharing
	// effectively, the UI client implements the pull paradigm vs. an Observer pattern, etc.
	//
	var objectStore: ObjectStore!

	override func viewDidLoad()
	{
		super.viewDidLoad()

		guard objectStore != nil else { fatalError("internal error: unbootstrapped object store") }
		
		do
		{
			socket.delegate = self

			socket.connect()
		}
	}

	override func viewWillDisappear(_ animated: Bool)
	{
		super.viewWillDisappear(animated)
		
		// cease automatic object store updates
		
		if socket.isConnected
		{
			// WebSocket commands are transmitted on the text band
			socket.write(string: Server.Command.unsubscribe.rawValue)
		}
		
		// cease automatic UI updates

		timer?.invalidate()
		timer = nil
	}

	override func viewWillAppear(_ animated: Bool)
	{
		super.viewWillAppear(animated)

		// start/resume automatic object store updates
		
		if socket.isConnected
		{
			// WebSocket commands are transmitted on the text band
			socket.write(string: Server.Command.subscribe.rawValue)
		}
		
		// start/resume automatic UI updates

		timer = scheduleUIUpdateTimer()
	}

	override func didReceiveMemoryWarning()
	{
		super.didReceiveMemoryWarning()
		
		// CRITICAL: uphold the iOS tradition of always properly remembering about the
		// existence of a memory warning, but doing absolutely nothing about it ;)
	}
	
	// MARK: - UITableViewDataSource

	override func numberOfSections(in tableView: UITableView) -> Int
	{
		return 1
	}

	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
	{
		return objectStore.drones.count
	}

	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
	{
		// get a new or recycled cell
		let cell = tableView.dequeueReusableCell(withIdentifier: "DashboardDroneCell", for: indexPath)
		
		do
		{
			let origImage = cell.imageView?.image
			let tintedImage = origImage?.withRenderingMode(.alwaysTemplate)

			cell.imageView?.image = tintedImage
		}

		return cell
	}
	
	override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
	{
		let drone = objectStore.drones[indexPath.row]
	
	#if DEBUG
		// TRICKY: necessary for automated UI testing through XCUI, see "Dron3rUITests.swift"
		cell.accessibilityLabel = drone.isImmobile() ? "immobile-drone" : "moving-drone"
	#endif

		do
		{
			// SPEC: "visually highlight the drones that have not been moving for more than 10 seconds"
			cell.imageView?.tintColor = drone.isImmobile() ? UIColor.red : UIColor.lightGray
		}
		
		// SPEC: [display] "by their unique identifiers, along with their current speed"

		do
		{
			cell.textLabel?.text = drone.identifier.uuidString
		}

		do
		{
			// unused (see SPEC above)
			_ = drone.location

			let speed: String = {
			
				if let speed = drone.speed
				{
					let numberFormatter: NumberFormatter = {
					
						let nf = NumberFormatter()

						nf.numberStyle = .decimal
						nf.minimumFractionDigits = 0
						nf.maximumFractionDigits = 2 // display only two decimal places in the UI

						return nf
					}()

					let formatted = numberFormatter.string(from: NSNumber(value: speed.metersPerSecond))
					return "\(formatted ?? /* failsafe */ String(speed.metersPerSecond)) meters/second"
				}
				else
				{
					return "unknown"
				}

			}()

			cell.detailTextLabel?.text = speed
			cell.detailTextLabel?.textColor = Config.UI.AuxTextColor
		}
	}
	
	// MARK: - WebSocketDelegate
	
	func websocketDidConnect(socket: WebSocketClient)
	{
		// WebSocket commands are transmitted on the text band
		socket.write(string: Server.Command.subscribe.rawValue)
	}
	
	func websocketDidDisconnect(socket: WebSocketClient, error: Error?)
	{
	}
	
	func websocketDidReceiveMessage(socket: WebSocketClient, text: String)
	{
		let message = "dashboard: unexpected message [\(text)] received from WebSocket on the command band"
		Logger.log(message, severity: .debug)
	}
	
	func websocketDidReceiveData(socket: WebSocketClient, data: Data)
	{
		// WebSocket payload gets transmitted on the binary band

		if let memento = Memento(decoding: data)
		{
			// TODO: figure out some power consumption -sensible UI update strategy: only every 1/2 second, etc.
			
			// SPEC: "the system's dashboard will only display the last location of the drones"
			// SPEC: "the backend doesn't need to worry about the history"

			if let drone = objectStore.find(through: memento.droneIdentifier)
			{
				// a known drone, update in the Object Store and the UI
				
				threadQueue.sync
				{
					// WARNING: the Server.swift source file should be in a different build module for internal(set) isolation to work
					drone.update(to: memento.location, with: memento.speed, at: memento.timestamp)
				}

				// CRITICAL: iOS UI cannot be updated in real-time, the main app thread will not take more
				// than a few dozens of updates per second before losing smoothness and appear locked up
			}
			else
			{
				// an unknown (yet unseen) drone, add to the Object Store and the UI
				
				let drone = RemoteDrone(identifier: memento.droneIdentifier,
					location: memento.location, speed: memento.speed)

				threadQueue.sync
				{
					do
					{
						try objectStore.insert(new: drone)
					}
					catch // any Error
					{
						// TODO: request a specification on how to report server-side errors
						
						let message = "dashboard: cannot store data for drone \(memento.droneIdentifier), error \(error)"
						Logger.log(message, severity: .error)
					}
				}
				
				// CRITICAL: iOS UI cannot be updated in real-time, the main app thread will not take more
				// than a few dozens of updates per second before losing smoothness and appear locked up
			}
		}
		else
		{
			// TODO: request a specification on how to report dashboard errors
			
			let message = "dashboard: cannot decode data for drone"
			Logger.log(message, severity: .error)
		}
	}

	//
	
	// MARK: - private
	
	private let socket =
		WebSocket(url: URL(string: "ws://\(Config.Server.Address):\(Config.Server.OutPort)/")!)

	private func scheduleUIUpdateTimer() -> Timer
	{
		let delay = /* seconds */ Config.UI.UIAutoUpdateInterval

		// WARNING: Timer scheduling must be executed on the main thread
		assert(Thread.isMainThread)
		
		return Timer.scheduledTimer(timeInterval: delay,
			target: self, selector: #selector(self.updateUI), userInfo: nil,
				repeats: true)
	}

	private var timer: Timer?

	@objc
	private func updateUI(timer: Timer)
	{
		// WARNING: this simple differential cell update strategy assumes there have been no cell deletions/displacements
		
		tableView.beginUpdates()
		
			// update all currently visible cells
		
			if let indexPathsForVisibleRows = tableView.indexPathsForVisibleRows
			{
				for indexPathForVisibleRow in indexPathsForVisibleRows
				{
					if let visibleCell = tableView.cellForRow(at: indexPathForVisibleRow)
					{
						// performance: reuse the built-in iOS callback to repaint a cell without recreating it
						tableView(tableView, willDisplay: visibleCell, forRowAt: indexPathForVisibleRow)
					}
				}
			}

			// insert all new cells so a user can scroll down properly
		
			let numberOfRows = tableView.numberOfRows(inSection: 0) // cached, in other words: last known
		
			if numberOfRows < objectStore.drones.count
			{
				let indexRange = numberOfRows ..< /* excluding */ objectStore.drones.count
				
				// for each index in a range, create a new IndexPath
				let indexPaths = indexRange.map { IndexPath(row: $0, section: 0) }

				tableView.insertRows(at: indexPaths, with: /* animation */ .none)
			}
		
		tableView.endUpdates()
	}
	
	// Swift's low-overhead thread synchronization primitive
	private let threadQueue = DispatchQueue(label: "DashboardViewController.objectStore.queue")
}

extension RemoteDrone
{
	// a small extension to the server-side drone abstract to detect (probably) broken drones

	func isImmobile() -> Bool
	{
		// check if the time of the last known movement of a drone exceeds a certain threshold
		
		if let timeOfLastKnownMovement = self.timeOfLastKnownMovement
		{
			let elapsed = Date.now().timeIntervalSince(timeOfLastKnownMovement) // in seconds
			
			if elapsed > Config.UI.MotionlessDroneHighlightInterval
			{
				return true
			}
		}

		return false
	}
}
