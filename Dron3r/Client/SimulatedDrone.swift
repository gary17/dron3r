//
//  SimulatedDrone.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

// https://github.com/swiftsocket/SwiftSocket
// provides as easy to use interface for socket based connections
import SwiftSocket

// represents a simulated hardware drone that receives GPS updates, does NOT allow manual drone status updates

#if DEBUG
// yes, indeed, inheritance in a Swift app - Swift's "default implementation
// in a protocol (interface) extension" is an abomination ;)

class SimulatedDrone: RemoteDrone, ClientDrone
{
	// a SimulatedDrone, as opposed to a Drone, allows for direct setting of location, altitude and speed
	//
	// WARNING: DO NOT USE IN PRODUCTION CODE
	
	var gpsAutoUpdateInterval: TimeInterval /* seconds */ = 0.3
	
	// "consumer drones can reach perfectly respectable speeds of 40 mph" (64 km/h, 17 meters/second) [Google]
	var maxDroneSpeed: Speed = Speed(17, in: .metersPerSecond)

	//
	
	init(identifier: UUID, address: String, port: UInt16)
	{
		client = UDPClient(address: address, port: Int32(port))
		
		super.init(identifier: identifier)
	}
	
	init(identifier: UUID, address: String, port: UInt16, location: Location?, speed: Speed?)
	{
		client = UDPClient(address: address, port: Int32(port))
		
		super.init(identifier: identifier, location: location, speed: speed)
	}

	func fly()
	{
		guard timer == nil else { /* noop */ return }

		DispatchQueue.main.async // WARNING: Timer scheduling must be executed on the main thread
		{
			// pass a weak reference to a parent to avoid a circular reference
			[weak self] in

			// ensure self, the app delegate, still exists - the app has not been shut down
			guard let self_s = self else { return }
			
			// simulate a GPS hardware callback on a background thread
			// the timer will repeatedly reschedule itself until invalidated

			let delay = /* seconds */ self_s.gpsAutoUpdateInterval
			
			self_s.timer = Timer.scheduledTimer(timeInterval: delay,
				target: self_s, selector: #selector(self_s.tick), userInfo: nil,
					repeats: true)
		}
	}
	
	func halt()
	{
		timer?.invalidate()
		timer = nil
	}
	
	func relocate()
	{
		// WARNING: since out GPS seems broken, perhaps fly off, but do not change internal object state
		guard let location = location else { return }

		// calculate a new location based on random speed

		// returns a random Double between 0.0 and 1.0
		let randomSpeed = Speed(drand48() * maxDroneSpeed.metersPerSecond, in: .metersPerSecond)

		let time = gpsAutoUpdateInterval // in seconds
		let distanceInMeters = /* seconds */ time * randomSpeed.metersPerSecond

		let distanceInDegrees = distanceInMeters * SimulatedDrone.DEGREES_OF_DISPLACEMENT_FOR_ONE_METER

		let newLocation = Location(

			// WARNING: a huge guess-estimate
			coordinate: Coordinate(
				latitude: location.coordinate.latitude + distanceInDegrees,
				longitude: location.coordinate.longitude + distanceInDegrees
			),
			
			// WARNING: a huge guess-estimate
			// WARNING: always flying upwards
			altitude: Altitude(location.altitude.meters + distanceInMeters, in: .meters)
		)

		// change the current location
		update(to: newLocation, with: randomSpeed, at: Timestamp.now())
	}

	// MARK: - private
	
	internal let client: UDPClient
	
	private var timer: Timer?

	@objc
	private func tick(timer: Timer)
	{
		relocate()

		// SPEC: "should report its geo-location coordinates to the central server in real-time"
		// report back to a central serever immediately when a drone's position changes
		//
		// TODO: resilience/performance, consider a separate thread for UDP subsmission
		//
		reportIn()
	}
	
	// each degree of latitude is approximately 69 miles (111 kilometers) apart
	// https://www.colorado.edu/geography/gcraft/warmup/aquifer/html/distance.html
	//
	static private let DEGREES_OF_DISPLACEMENT_FOR_ONE_METER = Double(1) / (111 /* km */ * 1000 /* m */)
}
#endif // DEBUG
