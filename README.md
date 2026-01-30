# DreamHomes OS

A modern iOS real estate app for Florida properties, powered by GPT-5 nano AI insights.

## Features

### 🏠 Core Functionality
- **Instant Access**: No login required to browse properties
- **Map-Based Exploration**: Florida-focused property search
- **Smart Collections**: Curated property groups (Best Value, Price Drops, Family Safe, etc.)
- **Property Cards**: Swipe to save/pass, tap for details

### 🤖 AI-Powered Features (GPT-5 nano)
- **Property Insights**: AI-generated analysis for each property
- **Smart Rankings**: Personalized top picks based on your goals
- **Message Assistance**: Professional inquiry composition
- **Natural Q&A**: Ask questions about properties in plain English

### 📱 User Experience
- **Onboarding Funnel**: Scan → Heart → Message flow
- **Deal Mode**: Activated for high-intent users
- **Soft Authentication**: Progressive engagement model
- **Floating Assistant**: "Ask DreamHomes OS" always available

## Setup Instructions

### Prerequisites
- Xcode 15.0 or later
- iOS 17.0+ deployment target
- OpenAI API key for GPT-5 nano

### Installation

1. Clone the repository:
```bash
git clone https://github.com/GeoBangkok/Habitus.git
cd Habitus
```

2. Open in Xcode:
```bash
open Habitus.xcodeproj
```

3. Configure API Key (IMPORTANT):

   **Option 1: Environment Variable (Recommended for Development)**
   - Edit Scheme → Run → Arguments → Environment Variables
   - Add: `OPENAI_API_KEY` = `your_actual_api_key_here`

   **Option 2: Update APIConfig.swift**
   - Never commit real API keys to source control
   - Use environment variables or Keychain for production

4. Build and run the project

## Architecture

### Project Structure
```
Habitus/
├── Models/
│   ├── Property.swift       # Core property model with scoring
│   ├── Collection.swift     # Property collections/filters
│   └── User.swift          # User profile and actions
├── Services/
│   └── ChatGPTService.swift # GPT-5 nano integration
├── ViewModels/
│   └── AppState.swift      # Global state and view models
├── Views/
│   ├── Onboarding/         # Onboarding flow
│   ├── Components/         # Reusable UI components
│   ├── MainTabView.swift  # Main app navigation
│   └── AskAssistantView.swift # AI chat interface
└── Config/
    └── APIConfig.swift     # API configuration (secure)
```

### AI Integration Pattern

The app uses GPT-5 nano with structured patterns:

1. **Three Dedicated Endpoints**:
   - `/ai/insight` - Property insights
   - `/ai/recommend` - Ranking and recommendations
   - `/ai/compose` - Message assistance

2. **Performance Optimizations**:
   - Response caching by property/user
   - Max 250 tokens per request
   - Streaming for longer responses

3. **Data Integrity**:
   - AI never invents property facts
   - All claims reference provided data
   - Server controls actual data fetching

## Key Design Decisions

### Why GPT-5 nano?
- **Speed**: Very fast responses for real-time interaction
- **Cost**: $0.05/$0.4 per million tokens (input/output)
- **Accuracy**: Sufficient for insights and recommendations
- **Scale**: Handles many small interactions efficiently

### Authentication Strategy
- Start anonymous for immediate value
- Soft gate after engagement (2 saves or 60s)
- Hard gate only for messaging
- Progressive profile building

### Deal Mode Triggers
- User messages about a property
- Requests a tour
- Saves 5+ homes in 7 days
- Views same neighborhood repeatedly

## Security Notes

⚠️ **IMPORTANT**:
- Never commit API keys to source control
- The committed code uses environment variables for API keys
- In production, use Keychain Services or secure configuration service
- Enable GitHub secret scanning on your repository

## Development

### Running Tests
```bash
# In Xcode
cmd+U
```

### Building for Release
1. Set API key in production configuration
2. Archive with Release configuration
3. Upload to App Store Connect

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Ensure API keys are not exposed
5. Submit a pull request

## License

This project is proprietary software.

## Contact

For questions about this implementation, please open an issue on GitHub.