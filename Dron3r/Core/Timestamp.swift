//
//  Timestamp.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import Foundation

// express the fact that we accept iOS Date as a high-precision timestamp
typealias Timestamp = Date

extension Timestamp
{
	// convenience/clarity
	
	static func now() -> Timestamp
	{
		return Date()
	}
}
