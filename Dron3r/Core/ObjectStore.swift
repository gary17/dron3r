//
//  ObjectStore.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import Foundation

// a memory-based object store, shared by a network server and a UI client (a dashboard)

class ObjectStore
{
	// SPEC: "the backend doesn't need to worry about the history"
	// SPEC: "store the state of the application in-memory for simplicity reasons"

#if SEPARATE_APPS_FOR_SERVER_AND_CLIENTS
	// a singleton
	static let sharedInstance = ObjectStore()
#endif

	enum StorageError: Error
	{
		case nonUniqueIdentifier, unknownObject
	}
	
	// SPEC: "store the state of the application in-memory for simplicity reasons"
	//
	// private(set) forces container mutation (add/delete) through the object store (Domain Model),
	// allowing for domain-defined handling of object cross-dependencies, observer support, etc.
	//
	// use an array in order to be able to define ORDERING of drone display
	//
	private(set) var drones = [RemoteDrone]()

	func insert(new object: RemoteDrone) throws
	{
		guard identifierMap[object.identifier] == nil else { throw StorageError.nonUniqueIdentifier }
		
		// at the end of the array
		drones.append(object)

		let indexOfLast = drones.count - 1
		assert(drones[indexOfLast].identifier == object.identifier)

		identifierMap[object.identifier] = indexOfLast
	}
	
	// WARNING: update() perfomed inline, on an object returned by reference from an Array (Apple Core Data -style)

	func delete(known object: RemoteDrone) throws
	{
		guard let index = identifierMap[object.identifier] else { throw StorageError.unknownObject }

		drones.remove(at: index)

		identifierMap.removeValue(forKey: object.identifier)
	}
	
	// MARK: - auxiliary
	
	func index(of identifier: UUID) -> Array<RemoteDrone>.Index?
	{
		// (!) drone reports get processed by the server based on drone identifiers - must be as fast as possible
		
	#if COUNTER_SAMPLE
		guard let index = drones.index(where: { $0.identifier == identifier }) else { return nil }
	#endif

		return identifierMap[identifier]
	}

	func find(through identifier: UUID) -> RemoteDrone?
	{
		// (!) drone reports get processed by the server based on drone identifiers - must be as fast as possible
		
		guard let index = identifierMap[identifier] else { return nil }
		return drones[index]
	}

	// MARK: - private

	/*
	
	TRICKY:
	
	- normally, an app should have only a single instance of an Object Store - implemented, say, through the Singleton pattern
	- practically, an app should be either a client or a server, but not both at the same time
	- however, this sample is a client and a server all rolled into a single compilation unit (a single app)
	- nevertheless, both of those subsystems must maintain their own, separate Object Store instances to mirror practical reality
	
	*/
	
#if SEPARATE_APPS_FOR_SERVER_AND_CLIENTS
	// a singleton, prevent others from using the default '()' initializer for this class
	private init()
	{
	}
#else
	// Swift could generate a mandatory initializer, but it would be "internal"
	init()
	{
	}
#endif

	// practical, there will be no more than a few tens of thousands of drones
	
	private typealias ObjectIdentifier = UUID
	private typealias ObjectIndex = Array<RemoteDrone>.Index
	
	private var identifierMap: [ObjectIdentifier: ObjectIndex] = [:]
}
