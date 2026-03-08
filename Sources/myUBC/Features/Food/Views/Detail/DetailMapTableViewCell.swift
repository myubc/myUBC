//
//  DetailMapTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-10-21.
//

import MapKit
import UIKit

class DetailMapTableViewCell: UITableViewCell, MKMapViewDelegate {
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var addressLabel: UILabel!
    @IBOutlet var navigationBtn: UIButton!
    @IBOutlet var detailLocationLabel: UILabel!
    @IBOutlet var baseView: UIView!

    static var nib: String {
        return "DetailMapTableViewCell"
    }

    weak var foodProtocol: FoodDetailProtocol?
    private var searchAddress: String?

    override func awakeFromNib() {
        super.awakeFromNib()
        baseView.layer.cornerRadius = 8
    }

    func setupLocation(address: String) {
        let normalizedAddress = address.replacingOccurrences(of: "\\n", with: "\n")
        let locations = normalizedAddress.split(whereSeparator: \.isNewline)
        if let general = locations.first {
            addressLabel.text = String(general)
        }
        if locations.count >= 2 {
            detailLocationLabel.text = String(locations.last ?? "")
        } else {
            detailLocationLabel.text = normalizedAddress
        }

        let normalized = normalizedAddress
            .replacingOccurrences(of: "\n", with: ", ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        searchAddress = normalized + ", UBC, Vancouver, BC, Canada"
    }

    @IBAction func navigateTo(_ sender: Any) {
        foodProtocol?.navigationMap()
    }

    func setupMap() {
        guard
            let mapContentView = mapView,
            let location = searchAddress
        else {
            return
        }

        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(location) { placemarks, _ in
            if
                let placemark = placemarks?.first,
                let location = placemark.location
            {
                mapContentView.pointOfInterestFilter = .includingAll
                mapContentView.delegate = self
                let pin = MKPointAnnotation()
                pin.coordinate = location.coordinate
                mapContentView.addAnnotation(pin)
                mapContentView.setRegion(MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1200, longitudinalMeters: 1200), animated: true)
            }
        }
    }
}
