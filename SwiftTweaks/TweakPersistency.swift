//
//  TweakPersistency.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/16/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import UIKit

/// Identifies tweaks in TweakPersistency
internal protocol TweakIdentifiable {
	var persistenceIdentifier: String { get }
}

/// Persists state for tweaks in a TweakCache
internal final class TweakPersistency {
	private let diskPersistency: TweakDiskPersistency

	private var tweakCache: TweakCache = [:]

	init(identifier: String) {
		self.diskPersistency = TweakNSCodingDiskPersistency(identifier: identifier)
		self.tweakCache = self.diskPersistency.loadFromDisk()
	}

	internal func currentValueForTweak<T>(_ tweak: Tweak<T>) -> T? {
		return persistedValueForTweakIdentifiable(AnyTweak(tweak: tweak)) as? T
	}

	internal func currentValueForTweak<T>(_ tweak: Tweak<T>) -> T? where T: Comparable {
		if let currentValue = persistedValueForTweakIdentifiable(AnyTweak(tweak: tweak)) as? T {
				// If the tweak can be clipped, then we'll need to clip it - because
				// the tweak might've been persisted without a min / max, but then you changed the tweak definition.
				// example: you tweaked it to 11, then set a max of 10 - the persisted value is still 11!
				return clip(currentValue, tweak.minimumValue, tweak.maximumValue)
		}

		return nil
	}

	internal func persistedValueForTweakIdentifiable(_ tweakID: TweakIdentifiable) -> TweakableType? {
		return tweakCache[tweakID.persistenceIdentifier]
	}

	internal func setValue(_ value: TweakableType?,  forTweakIdentifiable tweakID: TweakIdentifiable) {
		tweakCache[tweakID.persistenceIdentifier] = value
		self.diskPersistency.saveToDisk(tweakCache)
	}

	internal func clearAllData() {
		tweakCache = [:]
		self.diskPersistency.saveToDisk(tweakCache)
	}
}
