import SwiftUI
import GoogleMaps

struct GoogleMapView: UIViewRepresentable {
    var courses: [Course]
    @Binding var selectedCourse: Course?

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        
        // Default coordinates (UCSB fallback) if no courses
        let camera = GMSCameraPosition.camera(withLatitude: 34.4140, longitude: -119.8489, zoom: 10.0)
        options.camera = camera
        
        let mapView = GMSMapView(options: options)
        mapView.delegate = context.coordinator
        
        // Add rounded corners to blend with Golfr app aesthetics
        mapView.layer.cornerRadius = 16
        mapView.clipsToBounds = true
        
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {
        uiView.clear()
        
        var bounds = GMSCoordinateBounds()
        var hasValidCoordinates = false
        
        for course in courses {
            if let lat = course.latitude, let lng = course.longitude {
                let marker = GMSMarker()
                let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                marker.position = position
                marker.title = course.name
                marker.snippet = course.location
                marker.userData = course
                
                // Optional: Customize marker appearance to match app theme
                // marker.icon = GMSMarker.markerImage(with: UIColor(GolfrColors.primary))
                
                marker.map = uiView
                bounds = bounds.includingCoordinate(position)
                hasValidCoordinates = true
            }
        }
        
        if hasValidCoordinates {
            let update = GMSCameraUpdate.fit(bounds, withPadding: 50.0)
            uiView.animate(with: update)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapView
        
        init(_ parent: GoogleMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
            if let course = marker.userData as? Course {
                parent.selectedCourse = course
                
                // Show info window
                mapView.selectedMarker = marker
            }
            return true
        }
    }
}
