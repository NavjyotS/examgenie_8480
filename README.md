# Flutter

A modern Flutter-based mobile application utilizing the latest mobile development technologies and tools for building responsive cross-platform applications.

## 📋 Prerequisites

- Flutter SDK (^3.38.4)
- Dart SDK
- Android Studio / VS Code with Flutter extensions
- Android SDK / Xcode (for iOS development)

## 🛠️ Installation

1. Install dependencies:
```bash
flutter pub get
```

2. Run the application:

To run the app with environment variables defined in an env.json file, follow the steps mentioned below:
1. Through CLI
    ```bash
    flutter run --dart-define-from-file=env.json
    ```
2. For VSCode
    - Open .vscode/launch.json (create it if it doesn't exist).
    - Add or modify your launch configuration to include --dart-define-from-file:
    ```json
    {
        "version": "0.2.0",
        "configurations": [
            {
                "name": "Launch",
                "request": "launch",
                "type": "dart",
                "program": "lib/main.dart",
                "args": [
                    "--dart-define-from-file",
                    "env.json"
                ]
            }
        ]
    }
    ```
3. For IntelliJ / Android Studio
    - Go to Run > Edit Configurations.
    - Select your Flutter configuration or create a new one.
    - Add the following to the "Additional arguments" field:
    ```bash
    --dart-define-from-file=env.json
    ```

## 📁 Project Structure

```
flutter_app/
├── android/            # Android-specific configuration
├── ios/                # iOS-specific configuration
├── lib/
│   ├── core/           # Core utilities and services
│   │   └── utils/      # Utility classes
│   ├── presentation/   # UI screens and widgets
│   │   └── splash_screen/ # Splash screen implementation
│   ├── routes/         # Application routing
│   ├── theme/          # Theme configuration
│   ├── widgets/        # Reusable UI components
│   └── main.dart       # Application entry point
├── assets/             # Static assets (images, fonts, etc.)
├── pubspec.yaml        # Project dependencies and configuration
└── README.md           # Project documentation
```

## 🧠 AI Integration & App Flow

### 1. High-Level App Flow
The exam generation workflow consists of the following key steps:
1. **Source Upload (`SourceUploadScreen`)**: The user uploads study notes, handouts, or reference sheets as image files (JPEG, PNG) or PDFs.
2. **Configuration (`QuestionTypeSelectionScreen`)**: The user chooses:
   - Question distribution (Multiple Choice, Short Answer, Long Answer count).
   - Custom instructions (e.g., target difficulty, syllabus standards, or specific focus areas).
   - An optional reference pattern schema sheet (to guide question formatting/style).
3. **Multimodal Direct Inference**: The client encodes notes directly into Base64 format and packages them with the generation prompt containing instructions and a target JSON schema.
4. **AI Generation**: Gemini receives the multimodal prompt, parses text and handwritten notes/tables/diagrams directly from visual data, and generates structured questions in one pass.
5. **Exam Viewer (`ExamViewerScreen`)**: The app parses the generated JSON response into a `GeneratedExam` model and displays it in a clean, interactive UI for review, practice, and sharing.

---

### 2. Mid-Level Context: How and Where AI is Called
The AI workflow is fully integrated into the Flutter architecture using **Riverpod** and **Dio**:

* **Trigger Location**: 
  The call starts in `_generateExam()` in [`question_type_selection_screen.dart`](file:///n:/Navjyot%20Singh/APP%20creation%20for%20Pay/CODE/ExamGenieMobileApp/examgenie-version0.3/examgenie/lib/presentation/question_type_selection_screen/question_type_selection_screen.dart). 
  It gathers the notes, custom instructions, and pattern files, and invokes Riverpod's `chatNotifierProvider`.

* **Message Construction (`_buildMessages()`)**:
  Before sending, the app converts note files (and pattern references) into a list of multimodal elements:
  - Binary files are converted to Base64 strings formatted as Data URIs: `data:$mimeType;base64,...`.
  - The generation prompt is appended as a final text element containing the specific JSON structure required.
  - They are combined into a single user message payload: `[{type: "image_url", ...}, {type: "text", text: "..."}]`.

* **API Client & Proxy Routing (`chat_completion_service.dart`)**:
  The request is processed in [`chat_completion_service.dart`](file:///n:/Navjyot%20Singh/APP%20creation%20for%20Pay/CODE/ExamGenieMobileApp/examgenie-version0.3/examgenie/lib/core/services/aiIntegrations/chat_completion_service.dart):
  - **Local Development**: Routes requests through the `connector.rocket.new` CORS proxy, pointing to Gemini's OpenAI-compatible endpoint (`https://generativelanguage.googleapis.com/v1beta/openai/chat/completions`) using the `gemini-3.5-flash-lite` model. It extracts API keys from the compilation environment (`GEMINI_API_KEY`) and automatically attaches them to the `Authorization` header.
  - **Production Mode**: Calls a backend AWS Lambda function (`aws-lambda/chat-completion`) which securely houses the LLM SDK and makes calls to the providers.

## 🧩 Adding Routes

To add new routes to the application, update the `lib/routes/app_routes.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:package_name/presentation/home_screen/home_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String home = '/home';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    home: (context) => const HomeScreen(),
    // Add more routes as needed
  }
}
```

## 🎨 Theming

This project includes a comprehensive theming system with both light and dark themes:

```dart
// Access the current theme
ThemeData theme = Theme.of(context);

// Use theme colors
Color primaryColor = theme.colorScheme.primary;
```

The theme configuration includes:
- Color schemes for light and dark modes
- Typography styles
- Button themes
- Input decoration themes
- Card and dialog themes

## 📱 Responsive Design

The app is built with responsive design using the Sizer package:

```dart
// Example of responsive sizing
Container(
  width: 50.w, // 50% of screen width
  height: 20.h, // 20% of screen height
  child: Text('Responsive Container'),
)
```
## 📦 Deployment

Build the application for production:

```bash
# For Android
flutter build apk --release

# For iOS
flutter build ios --release
```

## 🙏 Acknowledgments
- Built with [Rocket.new](https://rocket.new)
- Powered by [Flutter](https://flutter.dev) & [Dart](https://dart.dev)
- Styled with Material Design

Built with ❤️ on Rocket.new
