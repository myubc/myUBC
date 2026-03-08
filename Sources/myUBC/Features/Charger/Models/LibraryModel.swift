//
//  LibraryModel.swift
//  myUBC
//
//  Created by myUBC on 2020-01-20.
//

import Contacts
import CoreLocation
import Foundation

class LibraryModel: NSObject, NSCoding, Codable {
    private enum CodingKeys: String, CodingKey {
        case iphones1, iphones2, andriods1, andriods2, macs1, macs2
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        iphones1 = try container.decode([Equipment].self, forKey: .iphones1)
        iphones2 = try container.decode([Equipment].self, forKey: .iphones2)
        andriods1 = try container.decode([Equipment].self, forKey: .andriods1)
        andriods2 = try container.decode([Equipment].self, forKey: .andriods2)
        macs1 = try container.decode([Equipment].self, forKey: .macs1)
        macs2 = try container.decode([Equipment].self, forKey: .macs2)
        super.init()
    }

    override init() {
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(iphones1, forKey: .iphones1)
        try container.encode(iphones2, forKey: .iphones2)
        try container.encode(andriods1, forKey: .andriods1)
        try container.encode(andriods2, forKey: .andriods2)
        try container.encode(macs1, forKey: .macs1)
        try container.encode(macs2, forKey: .macs2)
    }

    func encode(with coder: NSCoder) {
        coder.encode(iphones1, forKey: "iphones1")
        coder.encode(iphones2, forKey: "iphones2")
        coder.encode(andriods1, forKey: "andriods1")
        coder.encode(andriods2, forKey: "andriods2")
        coder.encode(macs1, forKey: "macs1")
        coder.encode(macs2, forKey: "macs2")
    }

    required convenience init?(coder: NSCoder) {
        self.init()
        if
            let ip1 = coder.decodeObject(forKey: "iphones1") as? [Equipment],
            let ip2 = coder.decodeObject(forKey: "iphones2") as? [Equipment],
            let an1 = coder.decodeObject(forKey: "andriods1") as? [Equipment],
            let an2 = coder.decodeObject(forKey: "andriods2") as? [Equipment],
            let mac1 = coder.decodeObject(forKey: "macs1") as? [Equipment],
            let mac2 = coder.decodeObject(forKey: "macs2") as? [Equipment]
        {
            iphones1 = ip1
            iphones2 = ip2
            andriods1 = an1
            andriods2 = an2
            macs1 = mac1
            macs2 = mac2
        }
    }

    var iphones1 = [Equipment]()
    var iphones2 = [Equipment]()
    var andriods1 = [Equipment]()
    var andriods2 = [Equipment]()
    var macs1 = [Equipment]()
    var macs2 = [Equipment]()
}

enum Device: Int, Codable {
    case IPhone1
    case IPhone2
    case Andriod1
    case Andriod2
    case Mac1
    case Mac2
    case Unknown
}

enum IrvingKBarberLearningCentre {
    static let description = "IKB Learning Learning Commons"
    static let fullAddress = "1961 E Mall, Vancouver, BC V6T 1Z1"
    static let coordinate = CLLocationCoordinate2D(
        latitude: 49.267851,
        longitude: -123.253087
    )
    static let contact = [
        CNPostalAddressStreetKey: "1961 E Mall",
        CNPostalAddressCityKey: "Vancouver",
        CNPostalAddressPostalCodeKey: "V6T 1Z1",
        CNPostalAddressISOCountryCodeKey: "CA"
    ]
}

enum DavidLamLibrary {
    static let description = "Canaccord Learning Commons"
    static let fullAddress = "2033 Main Mall, Vancouver, BC V6T 1Z2"
    static let coordinate = CLLocationCoordinate2D(
        latitude: 49.265826,
        longitude: -123.254586
    )
    static let contact = [
        CNPostalAddressStreetKey: "2033 Main Mall",
        CNPostalAddressCityKey: "Vancouver",
        CNPostalAddressPostalCodeKey: "V6T 1Z2",
        CNPostalAddressISOCountryCodeKey: "CA"
    ]
}

class Equipment: NSObject, NSCoding, Codable {
    private enum CodingKeys: String, CodingKey {
        case type, name, location, total, details
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(Device.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        location = try container.decode(String.self, forKey: .location)
        total = try container.decode(String.self, forKey: .total)
        details = try container.decode([EquipmentStatus].self, forKey: .details)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(location, forKey: .location)
        try container.encode(total, forKey: .total)
        try container.encode(details, forKey: .details)
    }

    func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "device")
        coder.encode(name, forKey: "name")
        coder.encode(location, forKey: "location")
        coder.encode(total, forKey: "total")
        coder.encode(details, forKey: "details")
    }

    required convenience init?(coder: NSCoder) {
        self.init(type: .IPhone1, name: "", location: "", total: "", details: [])
        if
            let name = coder.decodeObject(forKey: "name") as? String,
            let location = coder.decodeObject(forKey: "location") as? String,
            let total = coder.decodeObject(forKey: "total") as? String,
            let details = coder.decodeObject(forKey: "details") as? [EquipmentStatus]
        {
            self.name = name
            type = Device(rawValue: coder.decodeInteger(forKey: "device")) ?? .Unknown
            self.location = location
            self.total = total
            self.details = details
        }
    }

    var type: Device
    var name: String
    var location: String
    var total: String
    var details: [EquipmentStatus]
    override var description: String {
        return "\(String(describing: type)): \(name)"
    }

    init(type: Device, name: String, location: String, total: String, details: [EquipmentStatus]) {
        self.name = name
        self.location = location
        self.total = total
        self.details = details
        self.type = type
    }
}
