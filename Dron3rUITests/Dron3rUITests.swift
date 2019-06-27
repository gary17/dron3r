//
//  Dron3rUITests.swift
//  Dron3rUITests
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import XCTest

import Dron3r

class Dron3rUITests: XCTestCase
{
	override func setUp()
	{
		super.setUp()

		// this method is called before the invocation of each test method in the class

		// in UI tests it is usually best to stop immediately when a failure occurs
		continueAfterFailure = false

		// UI tests must launch the application that they test, happens for each test method separately
		XCUIApplication().launch()
	}

	override func tearDown()
	{
		// this method is called after the invocation of each test method in the class
		super.tearDown()
	}

	func testOfAppLaunch001()
	{
		// reflect the table UI widget for a list of active drones
		let table = XCUIApplication().tables.element
		
	#if NOPE_123
		// confirm there are initially no known drones
		XCTAssert(table.cells.count == 0)
	#endif
	
		// wait for a few (simulated) GPS update cycles
		sleep(/* in seconds */ 5)

		// confirm drones have successfully reported-in (client/server communitation)
		XCTAssert(table.cells.count > 0)
		
		// TRICKY: the DashboardViewController changes an "accessibility label" for an image in a table cell based on drone status
		// TRICKY: the XCUI subsystem automatically maps a UI widget accessibility label into a XCUIElement label
		//
		XCTAssertEqual(table.cells.matching(NSPredicate(format: "label == 'moving-drone'")).count, table.cells.count)

	#if DEBUG_TRACE
		// dump out XCUI structure
		print(table.debugDescription)
	#endif

		// confirm all drones are funcioning properly
		XCTAssert(table.cells.matching(NSPredicate(format: "label == 'immobile-drone'")).count == 0)
		
		// SPEC: "visually highlight the drones that have not been moving for more than 10 seconds"
		sleep(/* in seconds */ 10 + /* a breather */ 5)

		// confirm drones have been highlighted as broken
		XCTAssert(table.cells.matching(NSPredicate(format: "label == 'immobile-drone'")).count > 0)
	}
}
