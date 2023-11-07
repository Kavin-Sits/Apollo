//
//  UpdateLocationView.swift
//  Apollo
//
//  Created by Srihari Manoj on 11/7/23.
//

import SwiftUI
import CoreLocation
import MapKit
import FirebaseAuth
import FirebaseFirestore

struct UpdateLocationView: View {
    @StateObject private var locationPermission: LocationPermission = LocationPermission()

    var body: some View {
        VStack {
            switch locationPermission.authorizationStatus {
            case .notDetermined:
                Text("Location access not determined")
                Button {
                    locationPermission.requestLocationPermission()
                } label: {
                    Text("Allow Location Access")
                        .padding()
                }
            case .restricted:
                Text("Location access restricted")
            case .denied:
                Text("Location access denied")
            case .authorizedWhenInUse, .authorizedAlways:
                MapView(coordinate: locationPermission.coordinates)
                if let placemark = locationPermission.placemark {
                    Text("City: \(placemark.locality ?? "N/A")")
                    Text("Country: \(placemark.country ?? "N/A")")
                }
            default:
                Text("Location access not authorized")
            }
        }
        .buttonStyle(.bordered)
        .background(Color(red: 0.58135551552097409, green: 0.67444031521406167, blue: 1))
    }
}

class LocationPermission:NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus : CLAuthorizationStatus = .notDetermined
    private let locationManager = CLLocationManager()
    @Published var coordinates : CLLocationCoordinate2D?
    @Published var placemark: CLPlacemark?
    
    override init() {
        super.init()
        locationManager.delegate=self
        locationManager.desiredAccuracy=kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
    }
    
    func requestLocationPermission()  {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        coordinates = location.coordinate
        
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let placemark = placemarks?.first {
                self.placemark = placemark
                Firestore.firestore().collection("users").document(Auth.auth().currentUser?.email ?? "").setData(["location": placemark.locality!], merge: true)
            }
        }
    }
    
    
}

struct MapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let coordinate = coordinate {
            let region = MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
            uiView.setRegion(region, animated: true)
        }
    }
}

//#Preview {
//    UpdateLocationView()
//}
