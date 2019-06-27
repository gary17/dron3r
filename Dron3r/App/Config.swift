//
//  Config.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import UIKit

enum Config
{
	enum Server
	{
		static let Address = "127.0.0.1"
		
		// "The range 49152–65535 (215 + 214 to 216 − 1) contains dynamic or private ports that cannot be registered with IANA"
		// https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
		
		// an incoming report UDP server
		static let InPort: UInt16 = 50000
		
		// an outgoing report WebSockets server
		static let OutPort: UInt16 = 60000
	}
	
	enum App
	{
		// assume GPS hardware is capable of reporting changes in location every, say, 1/3 second
		static let GPSAutoUpdateInterval: TimeInterval = 0.3 // in seconds
	}

	enum Debug
	{
		static let DroneCount: UInt = 5
		static let BrokenDroneTickCount = UInt(5 /* seconds */ / Config.App.GPSAutoUpdateInterval)

		// a s3kr1t test location
		static let Latitude: Degrees = 37.234332396
		static let Longitude: Degrees = -115.80666344
		
		// the joys of a slightly confused Swift compiler... "Variable used within its own initial value"
		typealias AltitudeType = Altitude
		static let Altitude = AltitudeType(/* over a building */ 25, in: .meters)
		
		// "consumer drones can reach perfectly respectable speeds of 40 mph" (64 km/h, 17 meters/second) [Google]
		static let MaxDroneSpeed: Speed = Speed(17, in: .metersPerSecond)
	}

	enum UI
	{
		static let UIAutoUpdateInterval: TimeInterval = max(Config.App.GPSAutoUpdateInterval, 0.3) // in seconds
		
		// SPEC: "visually highlight the drones that have not been moving for more than 10 seconds"
		static let MotionlessDroneHighlightInterval: TimeInterval = 10 // in seconds

		// the sexy Xcode 8 deep blue
		static let AuxTextColor = UIColor(red: 65/255, green: 111/255, blue: 166/255, alpha: 1)
	}
}
