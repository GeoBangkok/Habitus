import SwiftUI
import MapKit
import Combine

// MARK: - Stub Views (To be implemented)

struct SavedPropertyCard: View {
    let property: Property

    var body: some View {
        VStack(alignment: .leading) {
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .cornerRadius(8)

            Text(property.formattedPrice)
                .font(.headline)
            Text(property.city)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct ComparePropertiesView: View {
    let properties: [Property]

    var body: some View {
        NavigationView {
            Text("Compare Properties")
                .navigationTitle("Compare")
        }
    }
}

struct ConversationView: View {
    let conversation: Conversation

    var body: some View {
        Text("Conversation View")
            .navigationTitle("Messages")
    }
}

struct ConversationRow: View {
    let conversation: Conversation

    var body: some View {
        HStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)

            VStack(alignment: .leading) {
                Text(conversation.propertyAddress)
                    .font(.headline)
                Text(conversation.lastMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct FiltersView: View {
    @Binding var filters: PropertyFilters

    var body: some View {
        NavigationView {
            Form {
                Section("Price Range") {
                    TextField("Min Price", value: $filters.priceMin, format: .currency(code: "USD"))
                    TextField("Max Price", value: $filters.priceMax, format: .currency(code: "USD"))
                }

                Section("Bedrooms") {
                    Stepper("Min: \(filters.bedroomsMin)", value: $filters.bedroomsMin, in: 1...10)
                }
            }
            .navigationTitle("Filters")
        }
    }
}

struct DealPickCard: View {
    let rankedProperty: RankedProperty

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("#\(rankedProperty.rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.green)

                Text(rankedProperty.property.formattedPrice)
                    .font(.headline)

                Spacer()
            }

            Text(rankedProperty.property.address)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .cornerRadius(8)
    }
}

struct SettingsView: View {
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Price Drop Alerts", isOn: .constant(true))
                    Toggle("New Listings", isOn: .constant(false))
                }
            }
            .navigationTitle("Settings")
        }
    }
}

struct MessageComposerView: View {
    let property: Property
    @State private var message = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                // Property Card
                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 80, height: 60)
                        .cornerRadius(8)

                    VStack(alignment: .leading) {
                        Text(property.formattedPrice)
                            .font(.headline)
                        Text(property.address)
                            .font(.caption)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.gray.opacity(0.05))

                // Quick Actions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(quickMessages, id: \.self) { quick in
                            Button(quick) {
                                message = quick
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }

                // Message Field
                TextEditor(text: $message)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .padding()

                Spacer()
            }
            .navigationTitle("Message About Property")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        // Send message
                        dismiss()
                    }
                    .disabled(message.isEmpty)
                }
            }
        }
    }

    private var quickMessages: [String] {
        [
            "Is it still available?",
            "Any issues I should know?",
            "Can we tour this week?",
            "What's the best offer strategy?"
        ]
    }
}

struct TourRequestView: View {
    let property: Property
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Property") {
                    Text(property.address)
                    Text(property.formattedPrice)
                }

                Section("Preferred Times") {
                    DatePicker("Date", selection: .constant(Date()), displayedComponents: .date)
                    DatePicker("Time", selection: .constant(Date()), displayedComponents: .hourAndMinute)
                }
            }
            .navigationTitle("Request Tour")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Request") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Supporting Models

struct Conversation: Identifiable {
    let id = UUID()
    let propertyAddress: String
    let lastMessage: String
    let unreadCount: Int
}

// MARK: - View Model Stubs

final class InboxViewModel: ObservableObject {
    @Published var conversations: [Conversation] = [
        Conversation(
            propertyAddress: "123 Ocean Drive",
            lastMessage: "Thanks for your interest!",
            unreadCount: 1
        )
    ]
}

final class ProfileViewModel: ObservableObject {
    @Published var userName = "John Doe"
    @Published var userEmail = "john@example.com"
    @Published var timeline = UserProfile.Timeline.threeToTwelve
    @Published var goal = UserProfile.Goal.live
    @Published var budgetRange = "$400k - $600k"
    @Published var viewedCount = 47
    @Published var savedCount = 12
    @Published var messageCount = 5
    @Published var tourCount = 2

    func signOut() {
        AppState.shared.signOut()
    }
}