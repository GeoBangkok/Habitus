import SwiftUI
import MapKit

struct BrowseModeView: View {
    @StateObject private var viewModel = BrowseModeViewModel()
    @State private var showingFilters = false
    @State private var selectedProperty: Property?
    @State private var mapRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 27.8006, longitude: -82.7946),
        span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
    )
    @State private var viewMode: ViewMode = .split

    enum ViewMode: String, CaseIterable {
        case map = "Map"
        case grid = "Grid"
        case split = "Split"

        var icon: String {
            switch self {
            case .map: return "map"
            case .grid: return "square.grid.2x2"
            case .split: return "rectangle.split.2x1"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Bar
            HStack {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)

                    Text(viewModel.searchText.isEmpty ? "Search city, ZIP, address..." : viewModel.searchText)
                        .foregroundColor(viewModel.searchText.isEmpty ? .gray : .primary)

                    Spacer()

                    Button(action: { showingFilters = true }) {
                        Label("Filters", systemImage: "slider.horizontal.3")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(viewModel.hasActiveFilters ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(viewModel.hasActiveFilters ? .white : .primary)
                            .cornerRadius(6)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)

                // View Mode Toggle
                Picker("View", selection: $viewMode) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Image(systemName: mode.icon)
                            .tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 120)
            }
            .padding()

            // Sort Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        SortChip(
                            option: option,
                            isSelected: viewModel.sortOption == option,
                            action: { viewModel.sortOption = option }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 8)

            // Main Content
            GeometryReader { geometry in
                switch viewMode {
                case .map:
                    MapViewFull(
                        region: $mapRegion,
                        properties: viewModel.properties,
                        selectedProperty: $selectedProperty
                    )

                case .grid:
                    GridView(
                        properties: viewModel.properties,
                        selectedProperty: $selectedProperty
                    )

                case .split:
                    HSplitView {
                        MapViewFull(
                            region: $mapRegion,
                            properties: viewModel.properties,
                            selectedProperty: $selectedProperty
                        )
                        .frame(width: geometry.size.width * 0.5)

                        GridView(
                            properties: viewModel.properties,
                            selectedProperty: $selectedProperty
                        )
                        .frame(width: geometry.size.width * 0.5)
                    }
                }
            }

            // Results Count Bar
            HStack {
                Text("\(viewModel.properties.count) homes")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.gray.opacity(0.05))
        }
        .sheet(isPresented: $showingFilters) {
            FiltersView(filters: $viewModel.filters)
        }
        .sheet(item: $selectedProperty) { property in
            PropertyDetailView(property: property)
        }
        .onAppear {
            viewModel.loadProperties()
        }
    }
}

// MARK: - Map View
struct MapViewFull: View {
    @Binding var region: MKCoordinateRegion
    let properties: [Property]
    @Binding var selectedProperty: Property?

    var body: some View {
        Map(coordinateRegion: $region, annotationItems: properties) { property in
            MapAnnotation(coordinate: property.coordinates.location) {
                PropertyMapPin(
                    property: property,
                    isSelected: selectedProperty?.id == property.id,
                    action: { selectedProperty = property }
                )
            }
        }
    }
}

struct PropertyMapPin: View {
    let property: Property
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Text(property.formattedPrice)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isSelected ? Color.blue : Color.white)
                    .foregroundColor(isSelected ? .white : .primary)
                    .cornerRadius(6)
                    .shadow(radius: 2)

                Image(systemName: "triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(isSelected ? .blue : .white)
                    .offset(y: -1)
            }
        }
        .scaleEffect(isSelected ? 1.2 : 1.0)
        .animation(.spring(response: 0.3), value: isSelected)
    }
}

// MARK: - Grid View
struct GridView: View {
    let properties: [Property]
    @Binding var selectedProperty: Property?

    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(properties) { property in
                    PropertyGridCard(
                        property: property,
                        action: { selectedProperty = property }
                    )
                }
            }
            .padding()
        }
    }
}

struct PropertyGridCard: View {
    let property: Property
    let action: () -> Void
    @State private var isSaved = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Image
                ZStack(alignment: .topTrailing) {
                    if let imageUrl = property.mainImageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 140)
                                .clipped()
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 140)
                                .overlay(ProgressView())
                        }
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 140)
                    }

                    // Save Button
                    Button(action: {
                        withAnimation(.spring()) {
                            isSaved.toggle()
                            if isSaved {
                                AppState.shared.savedProperties.append(property)
                            } else {
                                AppState.shared.savedProperties.removeAll { $0.id == property.id }
                            }
                        }
                    }) {
                        Image(systemName: isSaved ? "heart.fill" : "heart")
                            .font(.title3)
                            .foregroundColor(isSaved ? .red : .white)
                            .padding(8)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.formattedPrice)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Text("\(property.bedrooms) bed")
                        Text("•")
                        Text(String(format: "%.1f bath", property.bathrooms))
                        if let sqft = property.squareFeet {
                            Text("•")
                            Text("\(sqft) sqft")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    Text(property.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    // Badges
                    if !property.badges.isEmpty {
                        HStack(spacing: 4) {
                            ForEach(property.badges.prefix(2).indices, id: \.self) { index in
                                Text(property.badges[index].text)
                                    .font(.system(size: 10))
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(10)
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            isSaved = AppState.shared.savedProperties.contains { $0.id == property.id }
        }
    }
}

// MARK: - Sort Options
enum SortOption: String, CaseIterable {
    case newest = "Newest"
    case priceLow = "Price (Low)"
    case priceHigh = "Price (High)"
    case dealScore = "Best Deals"
    case size = "Size"
    case daysOnMarket = "Days Listed"
}

struct SortChip: View {
    let option: SortOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(option.rawValue)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
    }
}

// MARK: - View Model
class BrowseModeViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var searchText = ""
    @Published var filters = PropertyFilters()
    @Published var sortOption: SortOption = .newest
    @Published var isLoading = false

    var hasActiveFilters: Bool {
        filters.priceMin != nil ||
        filters.priceMax != nil ||
        filters.bedroomsMin > 1 ||
        !filters.cities.isEmpty
    }

    func loadProperties() {
        isLoading = true

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.properties = MockData.sampleProperties + MockData.sampleProperties
            self.sortProperties()
            self.isLoading = false
        }
    }

    private func sortProperties() {
        switch sortOption {
        case .newest:
            properties.sort { $0.daysOnMarket < $1.daysOnMarket }
        case .priceLow:
            properties.sort { $0.price < $1.price }
        case .priceHigh:
            properties.sort { $0.price > $1.price }
        case .dealScore:
            properties.sort { ($0.dealScore ?? 0) > ($1.dealScore ?? 0) }
        case .size:
            properties.sort { ($0.squareFeet ?? 0) > ($1.squareFeet ?? 0) }
        case .daysOnMarket:
            properties.sort { $0.daysOnMarket < $1.daysOnMarket }
        }
    }
}

#Preview {
    BrowseModeView()
}