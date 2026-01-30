import SwiftUI

struct OnboardingQualificationView: View {
    @StateObject private var appState = AppState.shared
    @State private var currentStep = 0
    @State private var timeline = UserProfile.Timeline.browsing
    @State private var goal = UserProfile.Goal.live
    @State private var budgetMin: Double = 300000
    @State private var budgetMax: Double = 600000
    @State private var preferredCities: Set<String> = []
    @State private var propertyTypes: Set<PropertyType> = []
    @State private var isReadyToBuy = false
    @State private var hasPreApproval = false
    @Environment(\.dismiss) private var dismiss

    private let floridaCities = [
        "Miami", "Tampa", "Orlando", "Jacksonville",
        "Fort Lauderdale", "Naples", "Sarasota", "St. Petersburg",
        "Clearwater", "Boca Raton", "West Palm Beach", "Gainesville"
    ]

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.05), Color.white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress Bar
                    ProgressBar(currentStep: currentStep, totalSteps: 5)
                        .padding()

                    // Content
                    TabView(selection: $currentStep) {
                        // Step 1: Timeline
                        TimelineStepView(timeline: $timeline)
                            .tag(0)

                        // Step 2: Goal
                        GoalStepView(goal: $goal)
                            .tag(1)

                        // Step 3: Budget
                        BudgetStepView(budgetMin: $budgetMin, budgetMax: $budgetMax)
                            .tag(2)

                        // Step 4: Locations
                        LocationsStepView(preferredCities: $preferredCities, cities: floridaCities)
                            .tag(3)

                        // Step 5: Property Types
                        PropertyTypesStepView(
                            propertyTypes: $propertyTypes,
                            isReadyToBuy: $isReadyToBuy,
                            hasPreApproval: $hasPreApproval
                        )
                        .tag(4)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .animation(.easeInOut, value: currentStep)

                    // Navigation Buttons
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button(action: previousStep) {
                                Text("Back")
                                    .fontWeight(.medium)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(Color.gray.opacity(0.1))
                                    .foregroundColor(.primary)
                                    .cornerRadius(10)
                            }
                        }

                        Button(action: nextStep) {
                            Text(currentStep == 4 ? "Get Started" : "Continue")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .disabled(!canProceed)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.gray)
                }
            }
        }
    }

    private var canProceed: Bool {
        switch currentStep {
        case 3:
            return !preferredCities.isEmpty
        case 4:
            return !propertyTypes.isEmpty
        default:
            return true
        }
    }

    private func previousStep() {
        withAnimation {
            currentStep -= 1
        }
    }

    private func nextStep() {
        if currentStep < 4 {
            withAnimation {
                currentStep += 1
            }
        } else {
            saveProfile()
            completeOnboarding()
        }
    }

    private func saveProfile() {
        let profile = UserProfile(
            timeline: timeline,
            goal: goal,
            budgetMin: budgetMin,
            budgetMax: budgetMax,
            preferredLocations: Array(preferredCities),
            preferredPropertyTypes: Array(propertyTypes)
        )

        if var user = appState.currentUser {
            user.profile = profile
            appState.currentUser = user

            // Save to UserDefaults
            if let encoded = try? JSONEncoder().encode(user) {
                UserDefaults.standard.set(encoded, forKey: "currentUser")
            }
        }

        // Mark user as qualified based on timeline
        if timeline == .now && (isReadyToBuy || hasPreApproval) {
            UserDefaults.standard.set(true, forKey: "isQualifiedBuyer")
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

// MARK: - Step Views

struct TimelineStepView: View {
    @Binding var timeline: UserProfile.Timeline

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("When are you looking to buy?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("This helps us prioritize the right opportunities for you")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                ForEach(UserProfile.Timeline.allCases, id: \.self) { option in
                    TimelineOption(
                        timeline: option,
                        isSelected: timeline == option,
                        action: { timeline = option }
                    )
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct TimelineOption: View {
    let timeline: UserProfile.Timeline
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch timeline {
        case .now: return "bolt.fill"
        case .threeToTwelve: return "clock.fill"
        case .browsing: return "eye.fill"
        }
    }

    var description: String {
        switch timeline {
        case .now: return "Actively searching, ready to move"
        case .threeToTwelve: return "Planning ahead for the right opportunity"
        case .browsing: return "Just exploring what's available"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(timeline.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GoalStepView: View {
    @Binding var goal: UserProfile.Goal

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("What's your primary goal?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("We'll tailor recommendations to match")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            VStack(spacing: 12) {
                ForEach(UserProfile.Goal.allCases, id: \.self) { option in
                    GoalOption(
                        goal: option,
                        isSelected: goal == option,
                        action: { goal = option }
                    )
                }
            }

            Spacer()
        }
        .padding()
    }
}

struct GoalOption: View {
    let goal: UserProfile.Goal
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch goal {
        case .live: return "house.fill"
        case .rent: return "dollarsign.circle.fill"
        case .both: return "arrow.triangle.2.circlepath"
        }
    }

    var description: String {
        switch goal {
        case .live: return "Looking for my next home"
        case .rent: return "Investment property for rental income"
        case .both: return "Open to either option"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .blue)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(goal.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BudgetStepView: View {
    @Binding var budgetMin: Double
    @Binding var budgetMax: Double

    private let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.maximumFractionDigits = 0
        return f
    }()

    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 12) {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("What's your budget range?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("We'll focus on properties in your price range")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)

            VStack(spacing: 20) {
                // Budget Range Display
                HStack {
                    Text(formatter.string(from: NSNumber(value: budgetMin)) ?? "")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("to")
                        .foregroundColor(.secondary)

                    Text(formatter.string(from: NSNumber(value: budgetMax)) ?? "")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)

                // Min Budget Slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $budgetMin, in: 100000...2000000, step: 25000)
                        .accentColor(.blue)
                }

                // Max Budget Slider
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Slider(value: $budgetMax, in: budgetMin...3000000, step: 25000)
                        .accentColor(.blue)
                }

                // Quick Selection Buttons
                HStack(spacing: 10) {
                    ForEach(["<500k", "500k-1M", "1M-2M", ">2M"], id: \.self) { range in
                        Button(action: { setQuickBudget(range) }) {
                            Text(range)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
    }

    private func setQuickBudget(_ range: String) {
        switch range {
        case "<500k":
            budgetMin = 100000
            budgetMax = 500000
        case "500k-1M":
            budgetMin = 500000
            budgetMax = 1000000
        case "1M-2M":
            budgetMin = 1000000
            budgetMax = 2000000
        case ">2M":
            budgetMin = 2000000
            budgetMax = 3000000
        default:
            break
        }
    }
}

struct LocationsStepView: View {
    @Binding var preferredCities: Set<String>
    let cities: [String]

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "map")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Where in Florida?")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Select all areas you're interested in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(cities, id: \.self) { city in
                        CityChip(
                            city: city,
                            isSelected: preferredCities.contains(city),
                            action: {
                                if preferredCities.contains(city) {
                                    preferredCities.remove(city)
                                } else {
                                    preferredCities.insert(city)
                                }
                            }
                        )
                    }
                }
            }
        }
        .padding()
    }
}

struct CityChip: View {
    let city: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(city)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(10)
        }
    }
}

struct PropertyTypesStepView: View {
    @Binding var propertyTypes: Set<PropertyType>
    @Binding var isReadyToBuy: Bool
    @Binding var hasPreApproval: Bool

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "building.2")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)

                Text("Property preferences")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("What type of properties interest you?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Property Types
            VStack(spacing: 10) {
                ForEach(PropertyType.allCases, id: \.self) { type in
                    PropertyTypeOption(
                        type: type,
                        isSelected: propertyTypes.contains(type),
                        action: {
                            if propertyTypes.contains(type) {
                                propertyTypes.remove(type)
                            } else {
                                propertyTypes.insert(type)
                            }
                        }
                    )
                }
            }

            // Readiness Questions
            VStack(spacing: 12) {
                Toggle("I'm ready to make an offer", isOn: $isReadyToBuy)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)

                Toggle("I have pre-approval", isOn: $hasPreApproval)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding()
    }
}

struct PropertyTypeOption: View {
    let type: PropertyType
    let isSelected: Bool
    let action: () -> Void

    var icon: String {
        switch type {
        case .singleFamily: return "house.fill"
        case .condo: return "building.fill"
        case .townhouse: return "building.2.fill"
        case .multiFamily: return "house.lodge.fill"
        case .land: return "leaf.fill"
        case .other: return "questionmark.circle.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(isSelected ? .white : .blue)

                Text(type.displayName)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.blue : Color.gray.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Rectangle()
                    .fill(step <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
            }
        }
    }
}

#Preview {
    OnboardingQualificationView()
}