//
//  EquipmentStatus.swift
//  myUBC
//
//  Created by myUBC on 2020-01-20.
//

import Foundation

class EquipmentStatus: NSObject, NSCoding, Codable {
    private enum CodingKeys: String, CodingKey {
        case isAvailable, referenceNo, date, note
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isAvailable = try container.decode(Bool.self, forKey: .isAvailable)
        referenceNo = try container.decodeIfPresent(String.self, forKey: .referenceNo)
        date = try container.decodeIfPresent(Date.self, forKey: .date)
        note = try container.decode(String.self, forKey: .note)
        super.init()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isAvailable, forKey: .isAvailable)
        try container.encode(referenceNo, forKey: .referenceNo)
        try container.encode(date, forKey: .date)
        try container.encode(note, forKey: .note)
    }

    func encode(with coder: NSCoder) {
        coder.encode(isAvailable, forKey: "isAvailable")
        coder.encode(referenceNo, forKey: "referenceNo")
        coder.encode(date, forKey: "date")
        coder.encode(note, forKey: "note")
    }

    required convenience init?(coder: NSCoder) {
        self.init(isAvailable: false, referenceNo: "", date: nil, note: "")
        if
            let refNo = coder.decodeObject(forKey: "referenceNo") as? String,
            let date = coder.decodeObject(forKey: "date") as? Date,
            let notes = coder.decodeObject(forKey: "note") as? String
        {
            isAvailable = coder.decodeBool(forKey: "isAvailable")
            referenceNo = refNo
            self.date = date
            note = notes
        } else {
            isAvailable = coder.decodeBool(forKey: "isAvailable")
            referenceNo = "-"
        }
    }

    var isAvailable: Bool
    var referenceNo: String?
    var date: Date?
    var note: String

    init(isAvailable: Bool, referenceNo: String?, date: Date?, note: String) {
        self.isAvailable = isAvailable
        self.referenceNo = referenceNo
        self.date = date
        self.note = note
    }
}
