import SwiftUI
import MapKit
import AuthenticationServices

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @State private var showingAuthSheet = false
    @State private var selectedCollection: PropertyCollection?

    var body: some View {
        ZStack {
            // Map View (Always visible)
            MapView(region: $viewModel.region, properties: viewModel.visibleProperties)
                .ignoresSafeArea()

            // Bottom Sheet
            VStack {
                Spacer()
                BottomSheetView(
                    collections: PropertyCollection.defaultCollections,
                    properties: viewModel.visibleProperties,
                    savedCount: viewModel.savedProperties.count,
                    onCollectionTap: { collection in
                        selectedCollection = collection
                        viewModel.filterByCollection(collection)
                    },
                    onPropertySave: { property in
                        viewModel.saveProperty(property)
                        checkForAuthGate()
                    },
                    onPropertyPass: { property in
                        viewModel.passProperty(property)
                    },
                    onPropertyMessage: { property in
                        // Hard gate - require auth for messaging
                        if !viewModel.isAuthenticated {
                            showingAuthSheet = true
                        } else {
                            // Navigate to message composer
                        }
                    }
                )
            }

            // Top Bar
            VStack {
                HStack {
                    Image("AppLogo")
                        .resizable()
                        .frame(width: 32, height: 32)

                    Spacer()

                    Button(action: {}) {
                        HStack {
                            Image(systemName: "heart.fill")
                            Text("\(viewModel.savedProperties.count)")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                    }
                }
                .padding()

                // Header Text
                if !viewModel.hasInteracted {
                    VStack(spacing: 4) {
                        Text("Private Florida Opportunities")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Curated homes. Real guidance.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showingAuthSheet) {
            AuthenticationView(onComplete: { user in
                viewModel.authenticateUser(user)
                showingAuthSheet = false
            })
        }
    }

    private func checkForAuthGate() {
        // Soft auth gate triggers
        let shouldShowAuth = !viewModel.isAuthenticated && (
            viewModel.savedProperties.count >= 2 ||
            viewModel.sessionDuration > 60 ||
            viewModel.detailViewCount >= 2
        )

        if shouldShowAuth {
            showingAuthSheet = true
        }
    }
}

// MARK: - Map View
struct MapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let properties: [Property]

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.mapType = .standard
        mapView.showsUserLocation = false
        mapView.isRotateEnabled = false
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Update annotations
        mapView.removeAnnotations(mapView.annotations)
        let annotations = properties.map { PropertyAnnotation(property: $0) }
        mapView.addAnnotations(annotations)

        // Update region if needed
        if mapView.region.center.latitude != region.center.latitude ||
           mapView.region.center.longitude != region.center.longitude {
            mapView.setRegion(region, animated: true)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let propertyAnnotation = annotation as? PropertyAnnotation else { return nil }

            let identifier = "PropertyPin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView

            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            } else {
                annotationView?.annotation = annotation
            }

            annotationView?.glyphText = propertyAnnotation.property.formattedPrice
            annotationView?.markerTintColor = .systemBlue

            return annotationView
        }
    }
}

// MARK: - Property Annotation
class PropertyAnnotation: NSObject, MKAnnotation {
    let property: Property
    let coordinate: CLLocationCoordinate2D

    init(property: Property) {
        self.property = property
        self.coordinate = property.coordinates.location
        super.init()
    }

    var title: String? {
        property.formattedPrice
    }

    var subtitle: String? {
        "\(property.bedrooms) bed • \(property.city)"
    }
}

// MARK: - Bottom Sheet
struct BottomSheetView: View {
    let collections: [PropertyCollection]
    let properties: [Property]
    let savedCount: Int
    let onCollectionTap: (PropertyCollection) -> Void
    let onPropertySave: (Property) -> Void
    let onPropertyPass: (Property) -> Void
    let onPropertyMessage: (Property) -> Void

    @State private var sheetHeight: CGFloat = 300
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)

            // Collections Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(collections) { collection in
                        CollectionChip(collection: collection) {
                            onCollectionTap(collection)
                        }
                    }
                }
                .padding()
            }

            // Property Feed
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(properties) { property in
                        PropertyCard(
                            property: property,
                            onSave: { onPropertySave(property) },
                            onPass: { onPropertyPass(property) },
                            onMessage: { onPropertyMessage(property) }
                        )
                    }
                }
                .padding()
            }
        }
        .frame(height: isExpanded ? UIScreen.main.bounds.height * 0.7 : sheetHeight)
        .background(.regularMaterial)
        .cornerRadius(20, corners: [.topLeft, .topRight])
        .shadow(radius: 10)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.height < -50 {
                        withAnimation { isExpanded = true }
                    } else if value.translation.height > 50 {
                        withAnimation { isExpanded = false }
                    }
                }
        )
    }
}

// MARK: - Collection Chip
struct CollectionChip: View {
    let collection: PropertyCollection
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: collection.icon)
                    Text(collection.title)
                        .fontWeight(.medium)
                }

                if let subtitle = collection.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("\(collection.propertyCount) homes")
                    Spacer()
                    Text(collection.updatedText)
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
            .padding()
            .frame(width: 200)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Corner radius extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}