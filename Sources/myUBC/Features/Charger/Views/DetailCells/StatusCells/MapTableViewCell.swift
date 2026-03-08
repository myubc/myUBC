//
//  MapTableViewCell.swift
//  myUBC
//
//  Created by myUBC on 2020-02-08.
//

import CoreMotion
import MapKit
import UIKit

class MapTableViewCell: UITableViewCell, MKMapViewDelegate {
    private var location: CLLocation?
    @IBOutlet var mapView: MKMapView?
    private let motionManager = CMMotionManager()
    @IBOutlet var baseView: UIView!
    @IBOutlet var addressBar: UIView!
    @IBOutlet var shadowView: UIView!
    @IBOutlet var shadowViewAddressBar: UIView!

    @IBOutlet var locationTitle: UILabel!
    @IBOutlet var locationDetailAddress: UILabel!
    var isInIKB: Bool = false {
        didSet {
            updateMap()
            updateBar()
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        baseView.clipsToBounds = true
        baseView.layer.cornerRadius = 12
        shadowView.layer.cornerRadius = 12
        addressBar.layer.cornerRadius = 12
    }

    func setupShadow() {
        setupShadow(forView: shadowView)
    }

    func setupShadow(forView shadowView: UIView) {
        var width: CGFloat = 0.0, height: CGFloat = 5.0
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.02
            motionManager.startDeviceMotionUpdates(to: .main, withHandler: { motion, _ in
                if let motion = motion {
                    let pitch = motion.attitude.pitch * 10 // x-axis
                    let roll = motion.attitude.roll * 10 // y-axis
                    width = CGFloat(roll)
                    height = CGFloat(pitch)
                }
            })
        }

        let shadowPath = UIBezierPath(
            roundedRect:
            shadowView.bounds,
            cornerRadius: 14.0
        )
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowRadius = 8.0
        shadowView.layer.shadowColor = UIColor.darkGray.cgColor
        shadowView.layer.shadowOffset = CGSize(width: width, height: height)
        shadowView.layer.shadowOpacity = 0.35
        shadowView.layer.shadowPath = shadowPath.cgPath
        selectionStyle = .none
    }

    @IBAction func didRequestMap(_ sender: Any) {
        let placemark = MKPlacemark(
            coordinate: isInIKB ? IrvingKBarberLearningCentre.coordinate : DavidLamLibrary.coordinate,
            addressDictionary: isInIKB ? IrvingKBarberLearningCentre.contact : DavidLamLibrary.contact
        )

        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking
        ]

        let destination = MKMapItem(placemark: placemark)
        destination.name = isInIKB ? "Irving K Barber Learning Centre" : "David Lam Library"

        MKMapItem.openMaps(with: [MKMapItem.forCurrentLocation(), destination], launchOptions: launchOptions)
    }

    func updateMap() {
        guard let mapContentView = mapView else {
            return
        }

        mapContentView.pointOfInterestFilter = .includingAll // .some(
        // MKPointOfInterestFilter(including: [.cafe, .library, .park, .publicTransport,
        // .postOffice, .museum, .bank, .bakery, .hospital, .fitnessCenter]))
        mapContentView.delegate = self
        let location = isInIKB ? IrvingKBarberLearningCentre.coordinate : DavidLamLibrary.coordinate
        let pin = MKPointAnnotation()
        let mapCamera = MKMapCamera(
            lookingAtCenter: location,
            fromEyeCoordinate: isInIKB ? DavidLamLibrary.coordinate : IrvingKBarberLearningCentre.coordinate,
            eyeAltitude: 200.0
        )
        pin.coordinate = location
        mapContentView.addAnnotation(pin)
        mapContentView.setRegion(MKCoordinateRegion(center: location, latitudinalMeters: 1200, longitudinalMeters: 1200), animated: true)
        mapContentView.setCamera(mapCamera, animated: true)
    }

    func updateBar() {
        locationTitle.text = isInIKB ? IrvingKBarberLearningCentre.description : DavidLamLibrary.description
        locationDetailAddress.text = isInIKB ? IrvingKBarberLearningCentre.fullAddress : DavidLamLibrary.fullAddress
    }
}
