//
//  TweakNSCodingDiskPersistency.swift
//  SwiftTweaks
//
//  Created by Jayson Rhynas on 2018-07-31.
//  Copyright © 2018 Khan Academy. All rights reserved.
//

import UIKit

/// Persists a TweakCache on disk using NSCoding
internal final class TweakNSCodingDiskPersistency: TweakDiskPersistency {
	private let fileURL: URL

	private static func fileURLForIdentifier(_ identifier: String) -> URL {
		return TweakNSCodingDiskPersistency.fileURLForIdentifier(identifier, extension: "db")
	}

	private let queue = DispatchQueue(label: "org.khanacademy.swift_tweaks.nscoding_disk_persistency", attributes: [])

	private static let dataClassName = "TweakDiskPersistency.Data"

	init(identifier: String) {
		NSKeyedUnarchiver.setClass(TweakNSCodingDiskPersistency.Data.self, forClassName: TweakNSCodingDiskPersistency.dataClassName)
		NSKeyedArchiver.setClassName(TweakNSCodingDiskPersistency.dataClassName, for: TweakNSCodingDiskPersistency.Data.self)

		self.fileURL = TweakNSCodingDiskPersistency.fileURLForIdentifier(identifier)
		self.ensureDirectoryExists()
	}

	/// Creates a directory (if needed) for our persisted TweakCache on disk
	private func ensureDirectoryExists() {
		self.queue.async {
			try! FileManager.default.createDirectory(at: self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		}
	}

	func loadFromDisk() -> TweakCache {
		var result: TweakCache!

		self.queue.sync {
			result = (try? Foundation.Data(contentsOf: self.fileURL))
				.flatMap(NSKeyedUnarchiver.unarchiveObject(with:))
				.flatMap { $0 as? Data }
				.map { $0.cache }
				?? [:]
		}

		return result
	}

	func saveToDisk(_ data: TweakCache) {
		self.queue.async {
			let nsData = NSKeyedArchiver.archivedData(withRootObject: Data(cache: data))
			try! nsData.write(to: self.fileURL, options: [.atomic])
		}
	}

	/// Implements NSCoding for TweakCache.
	/// TweakCache a flat dictionary: [String: TweakableType].
	/// However, because re-hydrating TweakableType from its underlying NSNumber gets Bool & Int mixed up, we have to persist a different structure on disk: [TweakViewDataType: [String: AnyObject]]
	/// This ensures that if something was saved as a Bool, it's read back as a Bool.
	// NOTE (bryanjclark): The long string here is to preserve backwards-compatibility with pre-Swift4 SwiftTweaks archives.
	@objc(_TtCC11SwiftTweaksP33_9992646B9FE5A082B6B2A55DA4E653F420TweakDiskPersistency4Data) private final class Data: NSObject, NSCoding {
		let cache: TweakCache

		init(cache: TweakCache) {
			self.cache = cache
		}

		@objc convenience init?(coder aDecoder: NSCoder) {
			var cache: TweakCache = [:]

			// Read through each TweakViewDataType...
			for dataType in TweakViewDataType.allTypes {
				// If a sub-dictionary exists for that type,
				if let dataTypeDictionary = aDecoder.decodeObject(forKey: dataType.nsCodingKey) as? Dictionary<String, AnyObject> {
					// Read through each entry and populate the cache
					for (key, value) in dataTypeDictionary {
						if let value = Data.tweakableTypeWithAnyObject(value, withType: dataType) {
							cache[key] = value
						}
					}
				}
			}

			self.init(cache: cache)
		}

		@objc fileprivate func encode(with aCoder: NSCoder) {

			// Our "dictionary of dictionaries" that is persisted on disk
			var diskPersistedDictionary: [TweakViewDataType : [String: AnyObject]] = [:]

			// For each thing in our TweakCache,
			for (key, value) in cache {
				let dataType = type(of: value).tweakViewDataType

				// ... create the "sub-dictionary" if it doesn't already exist for a particular TweakViewDataType
				if diskPersistedDictionary[dataType] == nil {
					diskPersistedDictionary[dataType] = [:]
				}

				// ... and set the cached value inside the sub-dictionary.
				diskPersistedDictionary[dataType]![key] = value.nsCoding
			}

			// Now we persist the "dictionary of dictionaries" on disk!
			for (key, value) in diskPersistedDictionary {
				aCoder.encode(value, forKey: key.nsCodingKey)
			}
		}

		// Reads from the cache, casting to the appropriate TweakViewDataType
		private static func tweakableTypeWithAnyObject(_ anyObject: AnyObject, withType type: TweakViewDataType) -> TweakableType? {
			switch type {
			case .integer: return anyObject as? Int
			case .boolean: return anyObject as? Bool
			case .cgFloat: return anyObject as? CGFloat
			case .double: return anyObject as? Double
			case .uiColor: return anyObject as? UIColor
			case .string: return anyObject as? String
			case .stringList:
				guard let stringOptionString = anyObject as? String else {
					return nil
				}
				return StringOption(value: stringOptionString)
			}
		}
	}
}

private extension TweakViewDataType {
	/// Identifies our TweakViewDataType when in NSCoding. See implementation of TweakDiskPersistency.Data
	var nsCodingKey: String {
		switch self {
		case .boolean: return "boolean"
		case .integer: return "integer"
		case .cgFloat: return "cgfloat"
		case .double: return "double"
		case .uiColor: return "uicolor"
		case .string: return "string"
		case .stringList: return "stringlist"
		}
	}
}

private extension TweakableType {
	/// Gets the underlying value from a Tweakable Type
	var nsCoding: AnyObject {
		switch type(of: self).tweakViewDataType {
			case .boolean: return self as! Bool as AnyObject
			case .integer: return self as! Int as AnyObject
			case .cgFloat: return self as! CGFloat as AnyObject
			case .double: return self as! Double as AnyObject
			case .uiColor: return self as! UIColor
			case .string: return self as! NSString
			case .stringList: return (self as! StringOption).value as AnyObject
		}
	}
}
