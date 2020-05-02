//
//  Server.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

// https://github.com/swiftsocket/SwiftSocket
// provides as easy to use interface for socket based connections
//
import SwiftSocket

// https://github.com/httpswift/swifter
// Tiny http server engine written in Swift programming language
//
import Swifter

// a network server, connectionless, ping/pong-less UDP (User Datagram Protocol)

class Server // a pass-by-reference type
{
	// WebSocket commands are transmitted in on the text band, payload gets transmitted out on the binary band
	enum Command: String { case subscribe, unsubscribe }
	
	init(address: String, /* UDP */ inPort: UInt16, /* WebSockets */ outPort: UInt16, using objectStore: ObjectStore)
	{
		services = [ InService(address: address, port: inPort), OutService(address: address, port: outPort) ]
		
		self.objectStore = objectStore
		
		(services.first(where: { $0 is InService }) as? InService)?.handler = inHandler
	}

	func start(priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.background) throws
	{
		for service in services
		{
			try service.start(priority: priority)
		}
	}
	
	func stop()
	{
		for service in services
		{
			service.stop()
		}
	}
	
	// MARK: - private
	
	private let services: [Service]
	private let objectStore: ObjectStore

	// Swift's low-overhead thread synchronization primitive
	private let threadQueue = DispatchQueue(label: "Server.objectStore.queue")
	
	//
	
	private func inHandler(data: [UInt8], address: String, port: UInt16)
	{
		guard let memento = Memento(decoding: Data(data)) else
		{
			// TODO: request a specification on how to report server-side errors
			
			let message = "server: drone report receive failure from \(address):\(port)"
			Logger.log(message, severity: .error)
			
			return
		}

		// SPEC: "the system's dashboard will only display the last location of the drones"
		// SPEC: "the backend doesn't need to worry about the history"

		// 1 of 2: reflect the change locally (server object store)

		if let drone = objectStore.find(through: memento.droneIdentifier)
		{
			// a known drone, update in the Object Store

			threadQueue.sync
			{
				// WARNING: the Server.swift source file should be in a different build module for internal(set) isolation to work
				drone.update(to: memento.location, with: memento.speed, at: memento.timestamp)
			}
		}
		else
		{
			// an unknown (yet unseen) drone, add to the Object Store
			
			let drone = RemoteDrone(identifier: memento.droneIdentifier,
				location: memento.location, speed: memento.speed)

			threadQueue.sync
			{
				do
				{
					try objectStore.insert(new: drone)
				}
				catch // any Error
				{
					// TODO: request a specification on how to report server-side errors
					
					let message = "server: cannot store data for drone reported from \(address):\(port), error \(error)"
					Logger.log(message, severity: .error)
				}
			}
		}

		// 2 of 2: reflect the change remotely (remote clients)

		(services.first(where: { $0 is OutService }) as? OutService)?.send(data)
	}
	
	// UDP
	
	private class InService: Service
	{
		// this is an internal representation of a service, use a closure as opposed to an API-style protocol (interface)
		typealias Handler = ([UInt8], String, UInt16) -> Void
		
		var handler: Handler?
		
		init(address: String, port: UInt16)
		{
			self.server = UDPServer(address: address, port: Int32(port))
		}
		
		func start(priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.background) throws
		{
			guard keepRunning == false else { /* noop */ return }

			DispatchQueue.global(qos: priority).async
			{
				// pass a weak reference to a parent to avoid a circular reference
				[weak self] in

				// ensure self, the app delegate, still exists - the app has not been shut down
				guard let self_s = self else { return }

				self_s.threadQueue.sync
				{
					self_s.keepRunning = true
				}

				while self_s.keepRunning
				{
					let (raw, sender, port) = self_s.server.recv(Memento.ENCODED_BYTE_COUNT)

					// TODO: authentication, a secret cookie, electronic signing, IP range filtering, etc.
				
					guard let data = raw else
					{
						// TODO: request a specification on how to report server-side errors
					
						let message = "server: cannot receive data from \(sender):\(port)"
						Logger.log(message, severity: .error)
						
						return
					}

					// hand the data off
					self_s.handler?(data, sender, UInt16(port))
				}
			}
		}
		
		func stop()
		{
			// most likely will be called from a different thread than synchronous Server.start()

			threadQueue.sync
			{
				keepRunning = false
			}
		}
		
		//
		
		private let server: UDPServer

		// Swift's low-overhead thread synchronization primitive
		private let threadQueue = DispatchQueue(label: "InService.keepRunning.queue")

		private var keepRunning = false
	}
	
	// WebSockets

	private class OutService: Service
	{
		init(address: String, port: UInt16)
		{
			server = HttpServer()
			
			server.listenAddressIPv4 = address
			self.port = port
			
			server["/"] = websocket(/* text */ {
			
				(session, text) in
			
				// WebSocket commands are transmitted in on the text band

				if text == Server.Command.subscribe.rawValue
				{
					// KISS: only one session at at time

					guard self.session == nil else
					{
						// TODO: request a specification on how to report server-side errors
						
						let message = "server: WebSocket service over capacity, incoming session ignored"
						Logger.log(message, severity: .error)

						return
					}
					
					self.session = session
				}
				else if text == Server.Command.unsubscribe.rawValue
				{
					self.session = nil
				}
				else
				{
					// TODO: request a specification on how to report server-side errors

					let message = "server: invalid WebSocket command [\(text)]"
					Logger.log(message, severity: .error)
				}
			},
			/* binary */ nil,
			/* pong */ nil)
		}
		
		func start(priority: DispatchQoS.QoSClass = DispatchQoS.QoSClass.background) throws
		{
			try server.start(port, forceIPv4: true, priority: priority)
		}
		
		func stop()
		{
			server.stop()
		}
		
		func send(_ data: [UInt8])
		{
			// WebSocket payload gets transmitted out on the binary band

			session?.writeBinary(data)
		}

		private let server: HttpServer
		private let port: UInt16

		private var session: WebSocketSession?
	}
}

fileprivate protocol Service
{
	func start(priority: DispatchQoS.QoSClass) throws
	func stop()
}
