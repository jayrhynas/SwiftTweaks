//
//  TweakGroup.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/10/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import Foundation

/// A collection of Tweak<T>
/// These are represented in the UI as a UITableView section,
/// and can be "floated" onscreen as a group.
internal struct TweakGroup {
	let title: String
    let index: Int
	var tweaks: [String: AnyTweak] = [:]

    init(title: String, index: Int) {
		self.title = title
        self.index = index
	}
}

extension TweakGroup {
	internal var sortedTweaks: [AnyTweak] {
		return tweaks
			.sorted { lhs, rhs in
                if lhs.value.index == rhs.value.index {
                    return lhs.key < rhs.key
                } else {
                    return lhs.value.index < rhs.value.index
                }
            }
			.map { return $0.1 }
	}
}

