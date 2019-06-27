//
//  Altitude.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import CoreLocation

// the  default access level is internal (to a module)

struct Altitude // a pass-by-value type
{
	enum Unit { case meters }
	
	init(_ altitude: Double, in unit: Unit)
	{
		// already in base meters, no conversion required
		self.altitude = altitude
	}
	
	var meters: Double
	{
		get
		{
			// already in base meters, no conversion required
			return altitude
		}
	}
	
	// MARK: - private
	
	// express the fact that we interface with the iOS GPS subsystem through CoreLocation CLLocationDistance
	private var altitude: CLLocationDistance // in meters
}

extension Altitude: Equatable
{
	static func ==(lhs: Altitude, rhs: Altitude) -> Bool
	{
		return lhs.altitude == rhs.altitude
	}
}
