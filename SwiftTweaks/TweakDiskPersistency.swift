//
//  TweakDiskPersistency.swift
//  SwiftTweaks
//
//  Created by Jayson Rhynas on 2018-07-31.
//  Copyright © 2018 Khan Academy. All rights reserved.
//

import Foundation

internal typealias TweakCache = [String: TweakableType]

internal protocol TweakDiskPersistency {
	func loadFromDisk() -> TweakCache
	func saveToDisk(_ cache: TweakCache)
}

extension TweakDiskPersistency {
	static func fileURLForIdentifier(_ identifier: String, extension ext: String) -> URL {
		return try! FileManager().url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
			.appendingPathComponent("SwiftTweaks")
			.appendingPathComponent("\(identifier)")
			.appendingPathExtension(ext)
	}
}
