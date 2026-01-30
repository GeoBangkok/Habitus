import SwiftUI
import MapKit

struct PropertyDetailView: View {
    let property: Property
    @StateObject private var chatGPT = ChatGPTService.shared
    @State private var aiInsight: String?
    @State private var showingMessageComposer = false
    @State private var showingTourRequest = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Image Gallery
                    TabView {
                        ForEach(property.imageUrls, id: \.self) { imageUrl in
                            AsyncImage(url: URL(string: imageUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.2))
                            }
                        }
                    }
                    .frame(height: 300)
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))

                    VStack(alignment: .leading, spacing: 16) {
                        // Price and Address
                        VStack(alignment: .leading, spacing: 8) {
                            Text(property.formattedPrice)
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text(property.address)
                                .font(.title3)

                            Text("\(property.city), \(property.state) \(property.zipCode)")
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        // Key Details
                        HStack(spacing: 20) {
                            DetailItem(icon: "bed.double", value: "\(property.bedrooms) bed")
                            DetailItem(icon: "drop", value: "\(property.bathrooms, specifier: "%.1f") bath")
                            if let sqft = property.squareFeet {
                                DetailItem(icon: "square", value: "\(sqft) sqft")
                            }
                            if let yearBuilt = property.yearBuilt {
                                DetailItem(icon: "calendar", value: "\(yearBuilt)")
                            }
                        }
                        .padding(.horizontal)

                        // Badges
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(property.badges.indices, id: \.self) { index in
                                    PropertyBadgeView(badge: property.badges[index])
                                }
                            }
                            .padding(.horizontal)
                        }

                        Divider()

                        // AI Insight
                        if let insight = aiInsight ?? property.aiInsight {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("DreamHomes OS Insight", systemImage: "sparkles")
                                    .font(.headline)
                                    .foregroundColor(.blue)

                                Text(insight)
                                    .font(.body)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }

                        // Description
                        if let description = property.description {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("About this property")
                                    .font(.headline)
                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }

                        // Map
                        Map(coordinateRegion: .constant(
                            MKCoordinateRegion(
                                center: property.coordinates.location,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            )
                        ), annotationItems: [property]) { prop in
                            MapMarker(coordinate: prop.coordinates.location, tint: .blue)
                        }
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(.horizontal)

                        // Additional Details
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Property Details")
                                .font(.headline)

                            DetailRow(label: "Type", value: property.propertyType.displayName)
                            DetailRow(label: "Status", value: property.listingStatus.rawValue.capitalized)
                            DetailRow(label: "Days on Market", value: "\(property.daysOnMarket)")
                            if let mlsNumber = property.mlsNumber {
                                DetailRow(label: "MLS #", value: mlsNumber)
                            }
                            if let dealScore = property.dealScore {
                                DetailRow(label: "Deal Score", value: "\(dealScore)/100")
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .overlay(alignment: .bottom) {
                // Action Buttons
                HStack(spacing: 12) {
                    Button(action: { showingTourRequest = true }) {
                        Label("Request Tour", systemImage: "calendar")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button(action: { showingMessageComposer = true }) {
                        Label("Message", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(.regularMaterial)
            }
        }
        .onAppear {
            loadAIInsight()
        }
        .sheet(isPresented: $showingMessageComposer) {
            MessageComposerView(property: property)
        }
        .sheet(isPresented: $showingTourRequest) {
            TourRequestView(property: property)
        }
    }

    private func loadAIInsight() {
        guard aiInsight == nil && property.aiInsight == nil else { return }

        Task {
            do {
                let insight = try await chatGPT.generatePropertyInsight(for: property)
                await MainActor.run {
                    self.aiInsight = insight
                }
            } catch {
                print("Failed to load AI insight: \(error)")
            }
        }
    }
}

struct DetailItem: View {
    let icon: String
    let value: String

    var body: some View {
        VStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            Text(value)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}