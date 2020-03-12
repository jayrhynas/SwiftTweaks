//
//  TweakCollection.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/10/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import Foundation

/// A collection of TweakGroups; used in the root level of the Tweaks UI.
internal struct TweakCollection {
	let title: String
    let index: Int
	var tweakGroups: [String: TweakGroup] = [:]

    init(title: String, index: Int) {
		self.title = title
        self.index = index
	}
}

extension TweakCollection {
	/// The child TweakGroups, sorted alphabetically.
	internal var sortedTweakGroups: [TweakGroup] {
		return tweakGroups
			.sorted { lhs, rhs in
                if lhs.value.index == rhs.value.index {
                    return lhs.key < rhs.key
                } else {
                    return lhs.value.index < rhs.value.index
                }
            }
			.map { return $0.1 }
	}

	/// The total number of Tweaks in a TweakCollection.
	internal var numberOfTweaks: Int {
		return tweakGroups.values.reduce(0) { $0 + $1.tweaks.count }
	}

	/// A flat list of all the tweaks in a TweakCollection. 
	/// Used for sharing out the contents of a TweakStore.
	internal var allTweaks: [AnyTweak] {
		return sortedTweakGroups.reduce([]) {
			$0 + $1.sortedTweaks
		}
	}
}
