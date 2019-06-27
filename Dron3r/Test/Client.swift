//
//  Client.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

// a network client, connectionless, ping/pong-less UDP, a bunch of simulated drones pseudo-flying around

import Foundation

#if DEBUG
class Client // a pass-by-reference type
{
	init()
	{
		for index in 0 ..< Config.Debug.DroneCount
		{
			// a SimulatedDrone, as opposed to a Drone, allows for direct setting of location, altitude and speed
			//
			// WARNING: DO NOT USE IN PRODUCTION CODE
			
			// a hardware-based drone has to be SOMEWHERE
			
			// start in a test location
			let location = Location(
				coordinate: Coordinate(latitude: Config.Debug.Latitude, longitude: Config.Debug.Longitude),
					altitude: Config.Debug.Altitude)

			// start motionless
			let speed = Speed.zero()

			let drone =
				// every 5th drone is broken and will cease to fly after some time
				// ("Tell me this isn't a government operation." - "Apollo 13", 1995)
				//
				index % 5 == 0 ?
					BrokenDrone(identifier: UUID.new(), address: Config.Server.Address, port: Config.Server.InPort,
						location: location, speed: speed) :
					SimulatedDrone(identifier: UUID.new(), address: Config.Server.Address, port: Config.Server.InPort,
						location: location, speed: speed)
			
			drones.append(drone)
		}
	}
	
	func fly()
	{
		for drone in drones
		{
			drone.fly()
		}
	}
	
	func halt()
	{
		for drone in drones
		{
			drone.halt()
		}
	}
	
	// MARK: - private
	
	// an aray of drones
	private var drones = [SimulatedDrone]()
}
#endif // DEBUG
