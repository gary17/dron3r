//
//  RemoteDrone.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import Foundation

// represents a drone maintained by a server or a dashboard in its list of active drones, allows manual drone status updates

class RemoteDrone: Drone
{
	// SPEC: "visually highlight the drones that have not been moving for more than 10 seconds"
	//
	// implement this functionality on the server-side, will likely be needed by all clients on all platforms
	private(set) var timeOfLastKnownMovement: Timestamp?

	func update(to location: Location?, with speed: Speed?, at timestamp: Timestamp)
	{
		if /* known */ let location = location
		{
			if /* initial update */ self.location == nil ? true : /* variation */ self.location! != location
			{
				timeOfLastKnownMovement = timestamp
			}
		}
		
		self.location = location
		self.speed = speed
	}
}
