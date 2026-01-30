import SwiftUI

struct SwipeModeView: View {
    @StateObject private var viewModel = SwipeModeViewModel()
    @State private var offset = CGSize.zero
    @State private var currentCardIndex = 0
    @State private var showingPropertyDetail = false
    @State private var selectedProperty: Property?

    var body: some View {
        VStack(spacing: 0) {
            // Top Controls
            HStack {
                Button(action: {}) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("\(viewModel.remainingCount) homes")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { viewModel.undoLastAction() }) {
                    Image(systemName: "arrow.uturn.backward.circle")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                .disabled(!viewModel.canUndo)
            }
            .padding()

            // Card Stack
            ZStack {
                // Background cards
                ForEach(viewModel.properties.indices.reversed(), id: \.self) { index in
                    if index >= currentCardIndex && index < currentCardIndex + 3 {
                        SwipeCard(
                            property: viewModel.properties[index],
                            onTap: {
                                selectedProperty = viewModel.properties[index]
                                showingPropertyDetail = true
                            }
                        )
                        .offset(y: CGFloat((index - currentCardIndex) * 10))
                        .scaleEffect(index == currentCardIndex ? 1 : 0.95)
                        .opacity(index == currentCardIndex ? 1 : 0.8)
                        .offset(index == currentCardIndex ? offset : .zero)
                        .rotationEffect(
                            .degrees(index == currentCardIndex ? Double(offset.width / 10) : 0)
                        )
                        .gesture(
                            index == currentCardIndex ? dragGesture : nil
                        )
                    }
                }

                // Swipe indicators
                if offset.width > 50 {
                    SaveIndicator()
                        .opacity(Double(offset.width / 100))
                }

                if offset.width < -50 {
                    PassIndicator()
                        .opacity(Double(-offset.width / 100))
                }

                // Empty state
                if currentCardIndex >= viewModel.properties.count {
                    EmptyStateView()
                }
            }
            .padding()

            // Action Buttons
            HStack(spacing: 30) {
                // Pass Button
                Button(action: { swipeLeft() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.red)
                }

                // Super Like (Instant Message)
                Button(action: { superLike() }) {
                    Image(systemName: "star.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                }

                // Save Button
                Button(action: { swipeRight() }) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                }
            }
            .padding(.bottom, 30)
        }
        .sheet(isPresented: $showingPropertyDetail) {
            if let property = selectedProperty {
                PropertyDetailView(property: property)
            }
        }
        .onAppear {
            viewModel.loadProperties()
        }
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                withAnimation(.spring()) {
                    swipeCard(width: value.translation.width)
                }
            }
    }

    private func swipeCard(width: CGFloat) {
        switch width {
        case let x where x > 100:
            swipeRight()
        case let x where x < -100:
            swipeLeft()
        default:
            offset = .zero
        }
    }

    private func swipeRight() {
        guard currentCardIndex < viewModel.properties.count else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            offset = CGSize(width: 500, height: 0)
        }

        viewModel.saveProperty(viewModel.properties[currentCardIndex])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentCardIndex += 1
            offset = .zero
        }
    }

    private func swipeLeft() {
        guard currentCardIndex < viewModel.properties.count else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            offset = CGSize(width: -500, height: 0)
        }

        viewModel.passProperty(viewModel.properties[currentCardIndex])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentCardIndex += 1
            offset = .zero
        }
    }

    private func superLike() {
        guard currentCardIndex < viewModel.properties.count else { return }

        withAnimation(.easeInOut(duration: 0.3)) {
            offset = CGSize(width: 0, height: -500)
        }

        viewModel.superLikeProperty(viewModel.properties[currentCardIndex])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            currentCardIndex += 1
            offset = .zero
        }
    }
}

// MARK: - Swipe Card
struct SwipeCard: View {
    let property: Property
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Image
            ZStack(alignment: .topLeading) {
                if let imageUrl = property.mainImageUrl {
                    AsyncImage(url: URL(string: imageUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                ProgressView()
                            )
                    }
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.3), .blue.opacity(0.1)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }

                // Badges
                HStack {
                    ForEach(property.badges.indices, id: \.self) { index in
                        PropertyBadgeView(badge: property.badges[index])
                    }
                }
                .padding()
            }
            .frame(height: 400)
            .clipped()

            // Property Info
            VStack(alignment: .leading, spacing: 12) {
                Text(property.formattedPrice)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text(property.address)
                    .font(.headline)
                    .foregroundColor(.secondary)

                HStack {
                    Label("\(property.bedrooms) bed", systemImage: "bed.double")
                    Label(String(format: "%.1f bath", property.bathrooms), systemImage: "drop")
                    if let sqft = property.squareFeet {
                        Label("\(sqft) sqft", systemImage: "square")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)

                if let insight = property.aiInsight {
                    Text(insight)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(2)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 10)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Indicators
struct SaveIndicator: View {
    var body: some View {
        VStack {
            Image(systemName: "heart.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
            Text("SAVE")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.green.opacity(0.2))
        .cornerRadius(20)
        .rotationEffect(.degrees(-20))
        .offset(x: -50, y: -100)
    }
}

struct PassIndicator: View {
    var body: some View {
        VStack {
            Image(systemName: "xmark")
                .font(.system(size: 80))
                .foregroundColor(.red)
            Text("PASS")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color.red.opacity(0.2))
        .cornerRadius(20)
        .rotationEffect(.degrees(20))
        .offset(x: 50, y: -100)
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "house.circle")
                .font(.system(size: 80))
                .foregroundColor(.gray.opacity(0.5))

            Text("No more properties")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Check back later for new listings")
                .foregroundColor(.secondary)

            Button(action: {}) {
                Text("Adjust Filters")
                    .fontWeight(.medium)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
    }
}

// MARK: - View Model
class SwipeModeViewModel: ObservableObject {
    @Published var properties: [Property] = []
    @Published var savedProperties: [Property] = []
    @Published var passedProperties: [Property] = []
    @Published var lastAction: SwipeAction?

    var remainingCount: Int {
        properties.count
    }

    var canUndo: Bool {
        lastAction != nil
    }

    enum SwipeAction {
        case saved(Property)
        case passed(Property)
        case superLiked(Property)
    }

    func loadProperties() {
        // Load properties based on user preferences
        properties = MockData.sampleProperties + MockData.sampleProperties // Duplicate for testing
    }

    func saveProperty(_ property: Property) {
        savedProperties.append(property)
        lastAction = .saved(property)
        AppState.shared.savedProperties.append(property)
    }

    func passProperty(_ property: Property) {
        passedProperties.append(property)
        lastAction = .passed(property)
    }

    func superLikeProperty(_ property: Property) {
        savedProperties.append(property)
        lastAction = .superLiked(property)
        AppState.shared.savedProperties.append(property)
        // Trigger message flow
    }

    func undoLastAction() {
        guard let action = lastAction else { return }

        switch action {
        case .saved(let property):
            savedProperties.removeAll { $0.id == property.id }
            AppState.shared.savedProperties.removeAll { $0.id == property.id }
        case .passed(let property):
            passedProperties.removeAll { $0.id == property.id }
        case .superLiked(let property):
            savedProperties.removeAll { $0.id == property.id }
            AppState.shared.savedProperties.removeAll { $0.id == property.id }
        }

        lastAction = nil
    }
}

#Preview {
    SwipeModeView()
}