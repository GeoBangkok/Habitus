import SwiftUI

struct PropertyCard: View {
    let property: Property
    let onSave: () -> Void
    let onPass: () -> Void
    let onMessage: () -> Void

    @State private var imageOffset: CGSize = .zero
    @State private var showingDetails = false
    @StateObject private var chatGPT = ChatGPTService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Hero Image
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: property.mainImageUrl ?? "")) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 250)
                            .clipped()
                    case .failure(_):
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 250)
                            .overlay(
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                            )
                    case .empty:
                        Rectangle()
                            .fill(Color.gray.opacity(0.1))
                            .frame(height: 250)
                            .shimmering()
                    @unknown default:
                        EmptyView()
                    }
                }

                // Badges
                HStack {
                    ForEach(property.badges.indices, id: \.self) { index in
                        PropertyBadgeView(badge: property.badges[index])
                    }
                }
                .padding(12)
            }
            .offset(imageOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        imageOffset = value.translation
                    }
                    .onEnded { value in
                        withAnimation(.spring()) {
                            if abs(value.translation.width) > 100 {
                                if value.translation.width > 0 {
                                    onSave()
                                } else {
                                    onPass()
                                }
                            }
                            imageOffset = .zero
                        }
                    }
            )

            // Property Info
            VStack(alignment: .leading, spacing: 12) {
                // Price & Location
                HStack {
                    Text(property.formattedPrice)
                        .font(.title2)
                        .fontWeight(.bold)

                    Spacer()

                    Text(property.city)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Details
                HStack(spacing: 16) {
                    Label("\(property.bedrooms) bed", systemImage: "bed.double")
                    Label("\(property.bathrooms, specifier: "%.1f") bath", systemImage: "drop")
                    if let sqft = property.squareFeet {
                        Label("\(sqft) sqft", systemImage: "square")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)

                // AI Insight (if available)
                if let insight = property.aiInsight {
                    VStack(alignment: .leading, spacing: 4) {
                        Label("DreamHomes Insight", systemImage: "sparkles")
                            .font(.caption)
                            .foregroundColor(.blue)

                        Text(insight)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(8)
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)
                }

                // Action Buttons
                HStack(spacing: 12) {
                    ActionButton(
                        icon: "heart",
                        title: "Save",
                        color: .pink,
                        action: onSave
                    )

                    ActionButton(
                        icon: "hand.thumbsdown",
                        title: "Pass",
                        color: .gray,
                        action: onPass
                    )

                    ActionButton(
                        icon: "message",
                        title: "Message",
                        color: .blue,
                        action: onMessage
                    )
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 4)
        .onTapGesture {
            showingDetails = true
        }
        .sheet(isPresented: $showingDetails) {
            PropertyDetailView(property: property)
        }
        .onAppear {
            // Generate AI insight if not cached
            if property.aiInsight == nil {
                Task {
                    do {
                        let insight = try await chatGPT.generatePropertyInsight(for: property)
                        // Update property with insight (in real app, would update in data store)
                    } catch {
                        print("Failed to generate insight: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Property Badge View
struct PropertyBadgeView: View {
    let badge: PropertyBadge

    var badgeColor: Color {
        switch badge {
        case .dealScore:
            return .green
        case .priceDrop:
            return .red
        case .lowFloodRisk:
            return .blue
        case .highRentalDemand:
            return .purple
        case .newConstruction:
            return .orange
        }
    }

    var body: some View {
        Text(badge.text)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeColor.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(6)
    }
}

// MARK: - Action Button
struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .cornerRadius(10)
        }
    }
}

// MARK: - Shimmer Effect
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.white.opacity(0.3),
                        Color.clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase * 200)
                .mask(content)
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 2
                }
            }
    }
}

extension View {
    func shimmering() -> some View {
        modifier(ShimmerModifier())
    }
}