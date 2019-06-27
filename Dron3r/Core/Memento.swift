//
//  Memento.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import Foundation
import Compression

// represents a particular state of a client/server drone, can be binary encoded/decoded

struct Memento // a pass-by-value type
{
	let timestamp: Timestamp
	let droneIdentifier: UUID

	let location: Location?
	let speed: Speed?
	
	init(of drone: Drone, at timestamp: Timestamp)
	{
		// Date in Swift is a struct, not a class - a value type
		self.timestamp = timestamp
		
		// UUID in Swift is a struct, not a class - a value type
		self.droneIdentifier = drone.identifier

		// a Memento makes >>A COPY<< of the current state of a Drone, since it might change soon

		self.location = drone.location
		self.speed = drone.speed
	}
	
	init?(decoding data: Data)
	{
		// a failable initializer, might return nil indicating decoding failure
		
		do // with catch
		{
			var offset: Int = 0
		
			do
			{
				var rhs: Double = 0
				
				let byteCount = try BinaryCoder.decode(data, at: offset, into: &rhs)
				offset = offset + byteCount
				
				if UInt8(rhs) != version
				{
					// CRITICAL: we don't know how to handle the version of this encoding
					return nil
				}
			}
			
			do
			{
				var rhs: Double = 0
				
				let byteCount = try BinaryCoder.decode(data, at: offset, into: &rhs)
				offset = offset + byteCount
				
				timestamp = Timestamp(timeIntervalSince1970: rhs)
			}

			do
			{
				var rhs: uuid_t = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
				
				let byteCount = try BinaryCoder.decode(data, at: offset, into: &rhs)
				offset = offset + byteCount
				
				droneIdentifier = UUID(uuid: rhs)
			}

			// mundane, but easy ;)

			do
			{
				var latitude: Double = 0, longitude: Double = 0, altitude: Double = 0
				
				var byteCount = try BinaryCoder.decode(data, at: offset, into: &latitude)
				offset = offset + byteCount
				
				byteCount = try BinaryCoder.decode(data, at: offset, into: &longitude)
				offset = offset + byteCount
				
				byteCount = try BinaryCoder.decode(data, at: offset, into: &altitude)
				offset = offset + byteCount
				
				// if decoded a special value, ass-u-me ("The Silence of the Lambs", 1991) the location is unknown
				if
					latitude == Memento.MAGIC_VALUE_UNKNOWN ||
						longitude == Memento.MAGIC_VALUE_UNKNOWN ||
							altitude == Memento.MAGIC_VALUE_UNKNOWN
				{
					location = nil
				}
				else
				{
					location = Location(
						coordinate: Coordinate(latitude: latitude, longitude: longitude),
							altitude: Altitude(altitude, in: .meters))
				}
			}

			do
			{
				var rhs: Double = 0
				
				let byteCount = try BinaryCoder.decode(data, at: offset, into: &rhs)
				offset = offset + byteCount
				
				if rhs == Memento.MAGIC_VALUE_UNKNOWN
				{
					speed = nil
				}
				else
				{
					speed = Speed(rhs, in: .metersPerSecond)
				}
			}
		}
		catch // any Error
		{
			// unused
			_ = error

			return nil
		}

		// TODO: rollout a fully-fledged, Codable, iterative coder/decoder
	}
	
	func data() -> Data?
	{
		// there is no negative latitude, longitude, altitude, speed, ...
		assert(Memento.MAGIC_VALUE_UNKNOWN < 0)
		
		do // with catch
		{
			var data = Data()
			
			// CRITICAL: the version (the layout used) of this particular encoding
			let version = Double(self.version)

			try BinaryCoder.encode(payload: version, into: &data)

			try BinaryCoder.encode(payload: timestamp.timeIntervalSince1970, into: &data)
			try BinaryCoder.encode(payload: droneIdentifier.uuid, into: &data)

			// if the location is unknown, encode a special value
			try BinaryCoder.encode(payload: location?.coordinate.latitude ?? Memento.MAGIC_VALUE_UNKNOWN, into: &data)

			try BinaryCoder.encode(payload: location?.coordinate.longitude ?? Memento.MAGIC_VALUE_UNKNOWN, into: &data)
			try BinaryCoder.encode(payload: location?.altitude.meters ?? Memento.MAGIC_VALUE_UNKNOWN, into: &data)

			try BinaryCoder.encode(payload: speed?.metersPerSecond ?? Memento.MAGIC_VALUE_UNKNOWN, into: &data)
			
			// sanity
			assert(data.count == Memento.ENCODED_BYTE_COUNT)
			
		#if RESEARCH
			var dataOut = Data(count: /* over-buffer */ data.count * 10)
			var byteCount: Int!
			
			data.withUnsafeBytes {(fromBytes: UnsafePointer<UInt8>) -> Void in
				dataOut.withUnsafeMutableBytes {(toBytes: UnsafeMutablePointer<UInt8>) -> Void in
					byteCount = compression_encode_buffer(toBytes, dataOut.count, fromBytes, data.count, nil, COMPRESSION_LZFSE)
				}
			}
			
			_ = byteCount
			
			// WARNING: compression of very small buffers is impractical
			//
			// LZ4 compresses 64 bytes into 76 bytes
			// ZLIB compresses 64 bytes into 62 bytes
			// LZMA compresses 64 bytes into 112 bytes
			// LZ4_RAW compresses 64 bytes into 66 bytes
			// LZFSE compresses 64 bytes into 76 bytes
		#endif

			return data
		}
		catch // any Error
		{
			// unused
			_ = error

			return nil
		}
	}

	static let ENCODED_BYTE_COUNT: Int = 64
	
	// MARK: - private
	
	private let version: UInt8 = 1

	private static let MAGIC_VALUE_UNKNOWN = Double.greatestFiniteMagnitude * -1
}

extension Memento: Equatable
{
	// a simple generic to allow for predictable handling of a mix of optionals
	// FIXME: there must be some more elegant way to do this

	static func areEqual<T: /* require */ Equatable>(lhs: T?, rhs: T?) -> Bool
	{
		// either both LHS and RHS must be nil, or both must be non-nil (no mixing)

		if ((lhs != nil && rhs != nil) || (lhs == nil && rhs == nil)) == false
		{
			return false
		}
		else if let lhsUnwrapped = lhs, let rhsUnwrapped = rhs
		{
			// unwrap and compare by value

			return lhsUnwrapped == rhsUnwrapped
		}
		
		return true
	}

	static func ==(lhs: Memento, rhs: Memento) -> Bool
	{
		// FIXME: investigate occasional Swift Double precision inconsistencies for Date.timeIntervalSinceReferenceDate

		return
			// non-optionals
			lhs.timestamp == rhs.timestamp &&
			lhs.droneIdentifier == rhs.droneIdentifier &&
			
			// WARNING: optionals are compared by reference, not by value
			areEqual(lhs: lhs.location, rhs: rhs.location) &&
			areEqual(lhs: lhs.speed, rhs: rhs.speed)
	}
}
