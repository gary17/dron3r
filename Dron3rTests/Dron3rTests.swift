//
//  Dron3rTests.swift
//  Dron3rTests
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import XCTest

import Dron3r

// a sample set of functional test cases

class Dron3rTests: XCTestCase {
    
    override func setUp()
    {
        super.setUp()
		
		// called before the invocation of each test method in the class
    }
    
    override func tearDown()
    {
        // called after the invocation of each test method in the class

        super.tearDown()
    }
    
    func testOfEncoding001()
    {
		let testCases: [Double] = [ Double.greatestFiniteMagnitude * -1, -1, 0, 1, Double.greatestFiniteMagnitude ]
		let testUUID = UUID()

		var data = Data()

		// in
		
		for testCase in testCases
		{
			// 1 of 2: encode
			
			do
			{
				let lhs = testCase
				XCTAssertNoThrow(try BinaryCoder.encode(payload: lhs, into: &data))
			}
			
			// 2 of 2: alternate with a UUID

			do
			{
				XCTAssertNoThrow(try BinaryCoder.encode(payload: testUUID.uuid, into: &data))
			}
		}
		
		// out

		var offset: Int = 0
		
		for testCase in testCases
		{
			// 1 of 2: decode
			
			do
			{
				// returns a random Double between 0.0 and 1.0
				var rhs = drand48()
				
				var byteCountOut: Int!
				XCTAssertNoThrow(byteCountOut = try BinaryCoder.decode(data, at: offset, into: &rhs))

				// using XCTAssert and related functions to verify your tests produce the correct results

				XCTAssert(byteCountOut > 0)
				offset = offset + byteCountOut

				XCTAssertEqual(rhs, testCase)
			}
			
			// 2 of 2: decode as string
			
			do
			{
				var rhs: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
				
				var byteCountOut: Int!
				XCTAssertNoThrow(byteCountOut = try BinaryCoder.decode(data, at: offset, into: &rhs))
				
				XCTAssert(byteCountOut > 0)
				offset = offset + byteCountOut

				XCTAssertEqual(UUID(uuid: rhs), testUUID)
			}
		}
    }
	
    func testOfEncoding002()
    {
		let drone: RemoteDrone = {
		
			let location = Location(
				coordinate: Coordinate(latitude: Config.Debug.Latitude, longitude: Config.Debug.Longitude),
					altitude: Config.Debug.Altitude)

			// returns a random Double between 0.0 and 1.0
			let speed = Speed(drand48() * Config.Debug.MaxDroneSpeed.metersPerSecond, in: .metersPerSecond)
			
			return RemoteDrone(identifier: UUID.new(), location: location, speed: speed)
		}()
		
		// in
		
		// a Memento makes >>A COPY<< of the current state of a Drone, since it might change soon
		let lhs = Memento(of: drone, at: Timestamp.now())

		let data = lhs.data()
		XCTAssert(data != nil)
		
		if let data = data
		{
			// out

			let rhs = Memento(decoding: data)
			XCTAssert(rhs != nil)
			
			if let rhs = rhs
			{
				// FIXME: see comments for Equatable in Memento
				XCTAssert(rhs == lhs)
			}
		}
    }
	
    func testOfLog001()
    {
		let message = "1, 2, 3... this is only a test"
		Logger.log(message, severity: .debug)
    }
	
    func testOfObjectStore001()
    {
		#if SEPARATE_APPS_FOR_SERVER_AND_CLIENTS // see comments for the ObjectStore class
			let store = ObjectStore.sharedInstance
		#else
			let store = ObjectStore()
		#endif
		
		let testDrone: RemoteDrone = {
		
			let location = Location(
				coordinate: Coordinate(latitude: Config.Debug.Latitude, longitude: Config.Debug.Longitude),
					altitude: Config.Debug.Altitude)

			// returns a random Double between 0.0 and 1.0
			let speed = Speed(drand48() * Config.Debug.MaxDroneSpeed.metersPerSecond, in: .metersPerSecond)
			
			return RemoteDrone(identifier: UUID.new(), location: location, speed: speed)
		}()
		
		// test empty
		
		XCTAssertEqual(store.drones.count, 0)
		XCTAssert(store.find(through: testDrone.identifier) == nil)

		// test insert(new:)

		XCTAssertNoThrow(try store.insert(new: testDrone))
		
		// test non-empty
		
		XCTAssertEqual(store.drones.count, 1)
		XCTAssert(store.find(through: testDrone.identifier) != nil)
		
		// test find(through:)
		
		if let knownDrone = store.find(through: testDrone.identifier)
		{
			// what we put in must be what we got out
			XCTAssertEqual(knownDrone.identifier, testDrone.identifier)
		}
		
		// test delete(known:)

		XCTAssertNoThrow(try store.delete(known: testDrone))

		// test empty
		
		XCTAssertEqual(store.drones.count, 0)
		XCTAssert(store.find(through: testDrone.identifier) == nil)
		
		// TODO: expand object store test set to use multiple objects
    }
}
