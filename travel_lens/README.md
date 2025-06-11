# TravelLens

TravelLens is an AI-Powered Visual Travel Companion built with Flutter and Firebase. Point your phone camera at any landmark, sign, menu, or street scene and instantly get information in your language.

## Features

- **Object Detection**: Recognize landmarks, signs, menu items, and public art
- **OCR**: Extract text from menus, plaques, and signs
- **Question Answering**: Get information about detected objects
- **Summarization**: Condense long passages into bite-sized information
- **Translation**: Translate extracted text into your preferred language
- **Text-to-Speech**: Listen to the information in a natural voice

## Tech Stack

- **Frontend**: Flutter + Dart
- **State Management**: Provider
- **Backend**: Firebase (Auth, Firestore, Storage)
- **ML Services**: Hugging Face Inference API
- **Content**: Wikipedia REST API

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or newer)
- Firebase account
- Hugging Face account (for API access)

### Installation

1. Clone the repository:

   ```
   git clone https://github.com/yourusername/travel_lens.git
   cd travel_lens
   ```

2. Install dependencies:

   ```
   flutter pub get
   ```

3. Configure Firebase:

   - Create a Firebase project
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files
   - Follow the Firebase setup instructions for Flutter

4. Set up your Hugging Face API key:

   - Create a `.env` file in the root of your project
   - Add your API key: `HUGGING_FACE_API_KEY=your_api_key_here`

5. Run the app:
   ```
   flutter run
   ```

## Project Structure

```
lib/
├── core/        # Core functionality, constants, and utilities
├── data/        # Data models, providers, and repositories
├── features/    # Feature-specific implementations
├── ui/          # UI components and screens
└── main.dart    # Entry point
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
