//
//  Settings.swift
//  Swifty
//
//  Created by Vadim Pavlov on 10/20/17.
//  Copyright © 2017 Vadym Pavlov. All rights reserved.
//

import Foundation

public protocol SettingKey {
    init?(rawValue: String)
    var rawValue: String { get }

    static var clearKeys: [Self] { get }
}

public protocol SettingValue {}
public protocol URLValue {}

extension Bool: SettingValue {}
extension String: SettingValue {}
extension NSString: SettingValue {}

extension Data: SettingValue {}
extension NSData: SettingValue {}
extension Date: SettingValue {}
extension NSDate: SettingValue {}

extension Int: SettingValue {}
extension Float: SettingValue {}
extension Double: SettingValue {}
extension NSNumber: SettingValue {}

extension Array: SettingValue where Element: SettingValue {}
extension Dictionary: SettingValue where Value: SettingValue {}

extension URL: URLValue {}
extension NSURL: URLValue {}

open class Settings<Key: SettingKey> {

    public let prefix: String
    public let defaults: UserDefaults

    public init(prefix: String = "", defaults: UserDefaults) {
        self.prefix = prefix
        self.defaults = defaults
    }

    public func clearAll() {
        Key.clearKeys.forEach {
            self.set(value: nil, forKey: $0)
        }
    }

    public func clear(_ key: Key) {
        self.set(value: nil, forKey: key)
    }
    
    public subscript<Value: SettingValue>(key: Key) -> Value? {
        set { self.set(value: newValue, forKey: key) }
        get { return self.get(key: key) as? Value }
    }

    public subscript<U: URLValue>(key: Key) -> U? {
        set { defaults.set(newValue as? URL, forKey: prefix + key.rawValue) }
        get { return defaults.url(forKey: prefix + key.rawValue) as? U }
    }

    public subscript<E: RawRepresentable>(key: Key) -> E? {
        set { self.set(value: newValue?.rawValue, forKey: key) }
        get {
            let raw = self.get(key: key) as? E.RawValue
            return raw.flatMap(E.init)
        }
    }

    // MARK: - Objects
    public enum CodingType {
        case json
        case plist
    }

    public func set<Object: Codable>(_ object: Object?, key: Key, type: CodingType = .plist) {
        if let object = object {
            let data: Data?
            switch type {
            case .json:
                let encoder = JSONEncoder()
                data = try? encoder.encode(object)
            case .plist:
                let encoder = PropertyListEncoder()
                data = try? encoder.encode(object)
            }
            self.set(value: data, forKey: key)
        } else {
            self.set(value: nil, forKey: key)
        }
    }

    public func object<Object: Codable>(_ key: Key, type: CodingType = .plist) -> Object? {

        guard let data = self.get(key: key) as? Data else { return nil }
        switch type {
        case .json:
            let decoder = JSONDecoder()
            return try? decoder.decode(Object.self, from: data)
        case .plist:
            let decoder = PropertyListDecoder()
            return try? decoder.decode(Object.self, from: data)
        }
    }


    /*
    public subscript<Object: Codable>(key: Key) -> Object? {
        set {
            if let value = newValue as? SettingValue {
                self.set(value: value, forKey: key)
            } else if let object = newValue {
                let encoder = PropertyListEncoder()
                let data = try? encoder.encode(object)
                self.set(value: data, forKey: key)
            } else {
                self.set(value: newValue, forKey: key)
            }
        }
        get {
            let decoder = PropertyListDecoder()
            let data = self.get(key: key) as? Data
            let object = data.flatMap { try? decoder.decode(Object.self, from: $0) }
            return object
        }
    }
    */
}

private extension Settings {
    func set(value: Any?, forKey settingKey: Key) {
        let key = prefix + settingKey.rawValue
        if let newValue = value {
            defaults.set(newValue, forKey: key)
        } else {
            defaults.removeObject(forKey: key)
        }
    }
    
    func get(key settingKey: Key) -> Any? {
        let key = prefix + settingKey.rawValue
        return defaults.object(forKey: key)
    }
}
