//
//  ParkingAnnotation.swift
//  myUBC
//
//  Created by myUBC on 2022-04-20.
//

import MapKit

class ParkingAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = .init(latitude: 0, longitude: 0)
    var lotName: ParkingNames
    var status: [ParkingStatus]

    init(
        lotName: ParkingNames,
        status: [ParkingStatus]
    ) {
        self.lotName = lotName
        self.status = status
        super.init()
        coordinate = getCoord(parkingName: lotName)
    }

    private func getCoord(parkingName: ParkingNames) -> CLLocationCoordinate2D {
        switch parkingName {
        case .north:
            return CLLocationCoordinate2D(latitude: 49.269016, longitude: -123.250916)
        case .west:
            return CLLocationCoordinate2D(latitude: 49.262561, longitude: -123.255036)
        case .fraser:
            return CLLocationCoordinate2D(latitude: 49.266047, longitude: -123.258061)
        case .health:
            return CLLocationCoordinate2D(latitude: 49.263345, longitude: -123.247848)
        case .thunder:
            return CLLocationCoordinate2D(latitude: 49.261608, longitude: -123.243084)
        case .rose:
            return CLLocationCoordinate2D(latitude: 49.269669, longitude: -123.256729)
        case .unknown:
            return CLLocationCoordinate2D(latitude: 0, longitude: 0)
        }
    }
}

enum ParkingStatus: String, Codable {
    case good, limited, full, unkown
}

enum ParkingNames: String, Codable {
    case north = "North"
    case west = "West"
    case rose = "Rose Garden"
    case health = "Health Science"
    case fraser = "Fraser River"
    case thunder = "Thunderbird"
    case unknown
}
