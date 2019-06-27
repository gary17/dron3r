//
//  BrokenDrone.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

// represents a simulated hardware drone that will break after some ticks (GPS update cycles) and no longer relocate

class BrokenDrone: SimulatedDrone
{
	override func relocate()
	{
		if ticks < Config.Debug.BrokenDroneTickCount
		{
			// work
			
			super.relocate()
			
			ticks = ticks + 1
		}
		else
		{
			// break - noop
		}
	}
	
	// MARK: - private
	
	private var ticks: UInt8 = 0
}
