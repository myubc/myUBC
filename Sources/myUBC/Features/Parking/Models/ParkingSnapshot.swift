//
//  ParkingSnapshot.swift
//  myUBC
//
//  Created by myUBC on 2025-11-07.
//

import Foundation

struct ParkingLotSnapshot: Codable, Hashable {
    let lotName: ParkingNames
    let status: [ParkingStatus]
}

extension ParkingAnnotation {
    convenience init(snapshot: ParkingLotSnapshot) {
        self.init(lotName: snapshot.lotName, status: snapshot.status)
    }
}
