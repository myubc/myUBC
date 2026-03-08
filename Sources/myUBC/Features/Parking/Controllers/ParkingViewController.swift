//
//  ParkingViewController.swift
//  myUBC
//
//  Created by myUBC on 2022-01-17.
//

import MapKit
import UIKit

@MainActor
class ParkingViewController: UIViewController, AppContainerInjectable {
    @IBOutlet var shadowView: UIView!
    @IBOutlet var mapView: MKMapView!
    @IBOutlet var tableView: UITableView!

    @IBOutlet var navigationBtn: UIButton!
    @IBOutlet var navigateBtnConstraint: NSLayoutConstraint!

    var container: AppContainer?
    private var viewModel: ParkingViewModel?

    var selectedPin: ParkingAnnotation?
    private var parkingData: [ParkingAnnotation] = []

    var gradientLayer: CAGradientLayer?
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        if let container = container {
            viewModel = ParkingViewModel(service: container.parkingService)
        }
        setupShadow()
        setupMap()
        // setupTable()
        navigationBtn.accessibilityLabel = "Open directions"
        mapView.accessibilityLabel = "Parking map"
        setupLoadingIndicator()
        getModel()
    }

    /* func setupTable() {
         tableView.delegate = self
         tableView.dataSource = self
         tableView.register(UINib(nibName: ParkingTableViewCell.nib, bundle: nil),
                            forCellReuseIdentifier: ParkingTableViewCell.nib)
         tableView?.rowHeight = UITableView.automaticDimension
     } */

    func getModel() {
        showLoading()
        Task { [weak self] in
            guard let self else { return }
            guard let viewModel = viewModel else { return }
            let result = await viewModel.load()
            await MainActor.run {
                switch result {
                case .success:
                    self.parkingData = viewModel.lots
                    if let banner = viewModel.banner {
                        // self.showStatusBanner(message: banner.message, style: banner.style)
                    } else {
                        self.hideStatusBanner()
                    }
                    self.dismissLoading { [weak self] in
                        self?.renderData(animateCamera: true)
                    }
                case let .failure(error):
                    self.dismissLoading()
                    self.presentError(error)
                }
            }
        }
    }

    func showLoading() {
        if loadingIndicator.superview == nil {
            setupLoadingIndicator()
        }
        loadingIndicator.startAnimating()
        loadingIndicator.isHidden = false
        view.isUserInteractionEnabled = false
    }

    func dismissLoading(completion: (() -> Void)? = nil) {
        loadingIndicator.stopAnimating()
        loadingIndicator.isHidden = true
        view.isUserInteractionEnabled = true
        completion?()
    }

    @IBAction func showInfo(_ sender: Any) {
        let alert = UIAlertController(
            title: NSLocalizedString("alert.details.title", comment: ""),
            message: NSLocalizedString("parking.details", comment: ""),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: NSLocalizedString("alert.ok", comment: ""), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @IBAction func didNavigateBtn(_ sender: Any) {
        guard let selectedPin = selectedPin else {
            navigationBtn.isHidden = true
            shadowView.isHidden = true
            return
        }

        let location = selectedPin.coordinate
        let launchOptions = [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ]
        let mkPlace = MKPlacemark(coordinate: location)
        let destination = MKMapItem(placemark: mkPlace)
        destination.name = selectedPin.lotName.rawValue + " Parkade"
        MKMapItem.openMaps(with: [MKMapItem.forCurrentLocation(), destination], launchOptions: launchOptions)
    }

    func renderData(animateCamera shouldAnimateCamera: Bool = false) {
        let existing = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(existing)
        for location in parkingData {
            // for screenshot or screen-recording demos
            /* if location.lotName == .north {
                 location.status = [.limited, .full]
             } else if location.lotName == .west {
                 location.status = [.limited, .limited]
             } else if location.lotName == .fraser {
                 location.status = [.full, .good]
             } else if location.lotName == .thunder {
                 location.status = [.good, .full]
             } */
            mapView.addAnnotation(location)
        }
        guard shouldAnimateCamera else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.animateCamera()
        }
    }

    @IBAction func didTapClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

    func setupMap() {
        guard let mapContentView = mapView else {
            return
        }
        let location = IrvingKBarberLearningCentre.coordinate
        mapContentView.pointOfInterestFilter = .excludingAll
        mapContentView.delegate = self
        mapContentView.showsCompass = false

        // Start from a wide, neutral camera, then animate into the angled target camera.
        let startCamera = MKMapCamera(
            lookingAtCenter: CLLocationCoordinate2D(latitude: 49.2490, longitude: -123.2390),
            fromDistance: 6200,
            pitch: 0,
            heading: 0
        )
        mapContentView.setCamera(startCamera, animated: false)
        mapContentView.setRegion(
            MKCoordinateRegion(
                center: location,
                latitudinalMeters: 2200,
                longitudinalMeters: 2200
            ),
            animated: false
        )
    }

    private func setupLoadingIndicator() {
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.isHidden = true
        loadingIndicator.accessibilityIdentifier = "parking.loading"
        view.addSubview(loadingIndicator)

        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    func animateCamera() {
        let location = CLLocationCoordinate2D(latitude: 49.265022, longitude: -123.252082)
        let mapCamera = MKMapCamera(
            lookingAtCenter: location,
            fromEyeCoordinate: CLLocationCoordinate2D(latitude: 49.249722, longitude: -123.238567),
            eyeAltitude: 3000.0
        )
        mapCamera.heading = CLLocationDirection(329.0)
        mapView.setCamera(mapCamera, animated: true)
    }

    func setupShadow() {
        // UIScreen.main.bounds.width
        let view = UIView(frame: CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: mapView.frame.height
        ))

        gradientLayer = CAGradientLayer()
        gradientLayer?.colors = [
            UIColor.systemGroupedBackground.withAlphaComponent(1).cgColor,
            UIColor.systemGroupedBackground.withAlphaComponent(0).cgColor
        ]
        let viewEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let effectView = UIVisualEffectView(effect: viewEffect)
        effectView.frame = CGRect(
            x: 0,
            y: 0,
            width: UIScreen.main.bounds.width,
            height: mapView.frame.height * 0.2
        )
        gradientLayer?.frame = effectView.bounds
        gradientLayer?.locations = [0.0, 1.0]
        effectView.autoresizingMask = [.flexibleHeight]
        effectView.layer.mask = gradientLayer
        effectView.isUserInteractionEnabled = false // Use this to pass touches under this blur effect
        view.addSubview(effectView)

        view.isUserInteractionEnabled = false
        mapView.addSubview(view)
        mapView.bringSubviewToFront(view)
        navigationBtn.isHidden = true
        shadowView.isHidden = true
        shadowView.layer.cornerRadius = 8.0
        shadowView.backgroundColor = UIColor.lightGray // navigationBtn.backgroundColor
        shadowView.alpha = 0.1
        shadowView.layer.shadowColor = UIColor.darkGray.cgColor
        shadowView.layer.shadowOffset = CGSize(width: 0, height: 8)
        shadowView.layer.shadowOpacity = 0.6
        shadowView.layer.shadowRadius = 8.0
        shadowView.layer.masksToBounds = false
        navigationBtn.layer.masksToBounds = true
        navigationBtn.layer.cornerRadius = 8.0
    }
}

/*
 extension ParkingViewController: UITableViewDelegate, UITableViewDataSource {

     func numberOfSections(in tableView: UITableView) -> Int {
         return 1
     }

     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return 3
     }

     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

         guard let cell = tableView.dequeueReusableCell(withIdentifier: ParkingTableViewCell.nib, for: indexPath) as? ParkingTableViewCell else {
             return UITableViewCell()
         }

         return cell
     }

     func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
         return UITableView.automaticDimension
     }
 }*/

extension ParkingViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let model = annotation as? ParkingAnnotation else {
            return nil
        }

        let reuseID = "ParkingMarker"
        let annot = (mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKMarkerAnnotationView)
            ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
        annot.annotation = annotation
        if model.status.first == .full {
            annot.glyphText = "!"
            annot.clusteringIdentifier = "1"
            annot.markerTintColor = #colorLiteral(red: 0.6754626632, green: 0, blue: 0, alpha: 1)
        } else if model.status.first == .limited {
            annot.glyphText = "!"
            annot.clusteringIdentifier = "1"
            annot.markerTintColor = #colorLiteral(red: 0.8681644797, green: 0.6292878985, blue: 0.1429967284, alpha: 1)
        } else {
            annot.glyphText = "✓"
            annot.clusteringIdentifier = "1"
            annot.markerTintColor = #colorLiteral(red: 0.06666666667, green: 0.4980392157, blue: 0, alpha: 1)
        }

        annot.animatesWhenAdded = true

        guard let view = Bundle.main.loadNibNamed("ParkingAnnotationCallout", owner: self)?.first as? ParkingAnnotationCallout else {
            return annot
        }
        view.parkingLotStatus = model.status.first ?? .unkown
        view.evStatus = model.status.last ?? .unkown

        view.parkadeName.text = model.lotName.rawValue
        annot.detailCalloutAccessoryView = view
        annot.canShowCallout = true
        return annot
    }

    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let calloutView = view.detailCalloutAccessoryView as? ParkingAnnotationCallout else {
            return
        }

        selectedPin = parkingData.filter {
            $0.lotName.rawValue == calloutView.parkadeName.text
        }.first

        navigationBtn.alpha = 0
        shadowView.alpha = 0
        navigationBtn.isHidden = false
        shadowView.isHidden = false

        if selectedPin != nil {
            UIView.animate(withDuration: 0.3, animations: { () in
                self.navigationBtn.alpha = 1
                self.shadowView.alpha = 1
            }, completion: nil)
        }
    }

    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        selectedPin = nil
        navigationBtn.isHidden = true
        shadowView.isHidden = true
    }
}
