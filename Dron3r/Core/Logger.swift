//
//  Logger.swift
//  Dron3r
//
//  Copyright © 2019 R&F Consulting, Inc. All rights reserved.
//

import os

// use Apple unified logging system, for client (iOS) and server (macOS) compatiblity

enum Logger
{
	enum Severity
	{
		case debug, error

		fileprivate var osLogType: OSLogType // an implementation detail, available only on the file scope
		{
			switch self
			{
				case .debug: return .debug
				case .error: return .error
			}
		}
	}

	static func log(_ message: String, severity: Severity)
	{
		os_log("%@", log: OSLog.default, type: /* map userland to system */ severity.osLogType, message)
	}
}
