//
//  ClientDrone.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

// https://github.com/swiftsocket/SwiftSocket
// provides as easy to use interface for socket based connections
import SwiftSocket

// represents a network-enabled piece of hardware (as opposed to a server-side drone dashboard)

internal protocol ClientDrone
{
	var client: UDPClient { get }
}

extension ClientDrone where Self: Drone
{
	internal func reportIn()
	{
		// TODO: consider what to do when location and/or speed are unknown for a period of time, perhaps report-in as broken?

		// a Memento makes >>A COPY<< of the current state of a Drone, since it might change soon
		let memento = Memento(of: self, at: Timestamp.now())
		
		// UDP, connectionless, ping/pong-less
		
		// serialize and stream-up
		if let data = memento.data()
		{
			switch client.send(data: data)
			{
			  case .success:
				break
				
			  case .failure(let error):
			  	do
			  	{
					// TODO: request a specification on how to report client-side errors
					
					let message = "drone: UDP send failure [\(error)]"
					Logger.log(message, severity: .error)
				}
			}
		}
	}
}
