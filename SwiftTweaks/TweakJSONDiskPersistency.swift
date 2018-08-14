//
//  TweakJSONDiskPersistency.swift
//  SwiftTweaks
//
//  Created by Jayson Rhynas on 2018-07-31.
//  Copyright © 2018 Khan Academy. All rights reserved.
//

import UIKit

internal final class TweakJSONDiskPersistency: TweakDiskPersistency {
	private let fileURL: URL
	
	private let queue = DispatchQueue(label: "org.khanacademy.swift_tweaks.json_disk_persistency", attributes: [])
	
	convenience init(identifier: String) {
		self.init(fileURL: TweakJSONDiskPersistency.fileURLForIdentifier(identifier, extension: "json"))
	}
	
	init(fileURL: URL) {
		self.fileURL = fileURL
		self.ensureDirectoryExists()
	}
	
	private func ensureDirectoryExists() {
		self.queue.async {
			try! FileManager.default.createDirectory(at: self.fileURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
		}
	}
	
	func loadFromDisk() -> TweakCache {
		let decoder = JSONDecoder()
		
		return self.queue.sync {
			(try? Data(contentsOf: self.fileURL))
				.flatMap { try? decoder.decode(TweakJSONCache.self, from: $0) }
				.flatMap { $0.cache }
				?? [:]
		}
	}
	
	func saveToDisk(_ cache: TweakCache) {
		let encoder = JSONEncoder()
		
		self.queue.async {
			let _ = (try? encoder.encode(TweakJSONCache(cache)))
				.flatMap { try? $0.write(to: self.fileURL) }
		}
	}
}

private struct TweakJSONCache: Codable {
	let cache: TweakCache
	
	init(_ cache: TweakCache) {
		self.cache = cache
	}
	
	struct TweakNameKeys: CodingKey {
		let stringValue: String
		init?(stringValue: String) {
			self.stringValue = stringValue
		}
		
		private(set) var intValue: Int?
		init?(intValue: Int) {
			self.init(stringValue: "\(intValue)")
			self.intValue = intValue
		}
	}

	init(from decoder: Decoder) throws {
		var cache: TweakCache = [:]
		
		let container = try decoder.container(keyedBy: TweakNameKeys.self)
		
		for key in container.allKeys {
			guard let value = try? container.decodeTweakViewDataType(forKey: key) else {
				continue
			}
			
			cache[key.stringValue] = value
		}
		
		self.cache = cache
	}
	
	
	func encode(to encoder: Encoder) throws {
		
	}
}

private extension KeyedDecodingContainer {
	func decodeTweakViewDataType(forKey key: Key) throws -> TweakableType {
		if let bool = try? self.decode(Bool.self, forKey: key) {
			return bool
		} else if let int = try? self.decode(Int.self, forKey: key) {
			return int
		} else if let cgFloat = try? self.decode(CGFloat.self, forKey: key) {
			return cgFloat
		} else if let double = try? self.decode(Double.self, forKey: key) {
			return double
		} else if let uiColor = try? self.decode(UIColor.self, forKey: key) {
			return uiColor
		} else if let string = try? self.decode(String.self, forKey: key) {
			return string
		}
	}
	
	func decode(_ type: UIColor.Type, forKey key: KeyedDecodingContainer<K>.Key) throws -> UIColor {
		let hex = self.decode(String.self, forKey: )
	}
}

private extension TweakViewDataType {
	var typeName: String {
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
	var value: Codable {
		switch type(of: self).tweakViewDataType {
		case .boolean: return self as! Bool
		case .integer: return self as! Int
		case .cgFloat: return self as! CGFloat
		case .double: return self as! Double
		case .uiColor: return self as! UIColor
		case .string: return self as! String
		case .stringList: return (self as! StringOption).value
		}
	}
}
