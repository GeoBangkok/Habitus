import SwiftUI

struct AskAssistantView: View {
    @State private var question = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    @StateObject private var chatGPT = ChatGPTService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            // Welcome Message
                            AssistantMessageBubble(
                                message: "Hi! I'm DreamHomes OS. I can help you find properties, compare homes, or answer questions about the Florida real estate market. What would you like to know?"
                            )

                            ForEach(messages.indices, id: \.self) { index in
                                if messages[index].role == .user {
                                    UserMessageBubble(message: messages[index].content)
                                } else {
                                    AssistantMessageBubble(message: messages[index].content)
                                }
                            }

                            if isLoading {
                                AssistantMessageBubble(message: "Thinking...", isLoading: true)
                            }
                        }
                        .padding()
                        .id("bottom")
                    }
                    .onChange(of: messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                    }
                }

                // Suggested Questions
                if messages.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(suggestedQuestions, id: \.self) { question in
                                Button(action: { askQuestion(question) }) {
                                    Text(question)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(Color.blue.opacity(0.1))
                                        .foregroundColor(.blue)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // Input Field
                HStack {
                    TextField("Ask about properties...", text: $question)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit {
                            askQuestion(question)
                        }

                    Button(action: { askQuestion(question) }) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .disabled(question.isEmpty || isLoading)
                }
                .padding()
            }
            .navigationTitle("Ask DreamHomes OS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var suggestedQuestions: [String] {
        [
            "Find homes under $500k near Tampa",
            "What's the catch with waterfront properties?",
            "Which saved home is best for rentals?",
            "Compare my top 2 saved homes"
        ]
    }

    private func askQuestion(_ text: String) {
        guard !text.isEmpty else { return }

        // Add user message
        messages.append(ChatMessage(role: .user, content: text))
        question = ""
        isLoading = true

        // Get AI response
        Task {
            do {
                let context = SearchContext(
                    savedPropertyCount: AppState.shared.savedProperties.count,
                    recentSearches: ["Tampa", "Miami", "Orlando"],
                    preferredLocations: ["Tampa Bay", "Miami Beach"]
                )

                let response = try await chatGPT.askQuestion(text, context: context)

                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, content: response))
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    messages.append(ChatMessage(
                        role: .assistant,
                        content: "I'm sorry, I couldn't process that request. Please try again."
                    ))
                    isLoading = false
                }
            }
        }
    }
}

struct UserMessageBubble: View {
    let message: String

    var body: some View {
        HStack {
            Spacer()
            Text(message)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
                .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .trailing)
        }
    }
}

struct AssistantMessageBubble: View {
    let message: String
    var isLoading: Bool = false

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("DreamHomes OS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(message)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                } else {
                    Text(message)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(16)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: .leading)
            Spacer()
        }
    }
}