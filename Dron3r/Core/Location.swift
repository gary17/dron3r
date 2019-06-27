//
//  Location.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import Foundation

struct Location // a pass-by-value type
{
	// interface through iOS CLLocationCoordinate2D, CLLocationDistance, but enforce location of a flying object in 3D

	let coordinate: Coordinate
	let altitude: Altitude
	
	// Swift could generate a mandatory initializer, but it would be "internal"
	init(coordinate: Coordinate, altitude: Altitude)
	{
		self.coordinate = coordinate
		self.altitude = altitude
	}
}

// style, keep an assignment of a protocol with an implementation of that protocol

extension Location: Equatable
{
	// check if a particular geo-location has changed in 3 dimensions

	static func ==(lhs: Location, rhs: Location) -> Bool
	{
		return
			lhs.coordinate.latitude == rhs.coordinate.latitude &&
				lhs.coordinate.longitude == rhs.coordinate.longitude &&
					lhs.altitude == rhs.altitude
	}
}
