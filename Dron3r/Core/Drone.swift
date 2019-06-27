//
//  Drone.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import Foundation

// represents an abstract piece of hardware, with Location, Speed, etc.

class Drone // a pass-by-reference type
{
	// each instance will likely be a target of a GPS subsystem -driven callback

	let identifier: UUID
	
	// optional values ("?"), might be NULL (not yet known)
	// public read access; internal write access, allow mutation only in self and derivations (see SimulatedDrone)
	//
	internal(set) var location: Location?
	internal(set) var speed: Speed?
	
	init(identifier: UUID)
	{
		self.identifier = identifier
	}
	
	init(identifier: UUID, location: Location?, speed: Speed?)
	{
		self.identifier = identifier
		
		self.location = location
		self.speed = speed
	}
}
