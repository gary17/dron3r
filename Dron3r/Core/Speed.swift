//
//  Speed.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import CoreLocation

struct Speed // a pass-by-value type
{
	enum Unit { case metersPerSecond }
	
	init(_ speed: Double, in unit: Unit)
	{
		// already in base meters per second, no conversion required
		self.speed = speed
	}
	
	var metersPerSecond: Double
	{
		get
		{
			// already in base meters per second, no conversion required
			return speed
		}
	}
	
	// MARK: - private
	
	// express the fact that we interface with the iOS GPS subsystem through CoreLocation CLLocationSpeed
	private var speed: CLLocationSpeed // in meters per second
}

extension Speed
{
	// convenience
	
	static func zero() -> Speed
	{
		// keep symmetric to Timestamp.now() (re-created on demand), thus static func vs. static let
		return Speed(0, in: .metersPerSecond)
	}
}

extension Speed: Equatable
{
	static func ==(lhs: Speed, rhs: Speed) -> Bool
	{
		return lhs.speed == rhs.speed
	}
}
