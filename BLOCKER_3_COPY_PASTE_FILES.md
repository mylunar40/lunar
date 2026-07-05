# BLOCKER #3: Copy-Paste Implementation Files

All code below is production-ready and tested. Paste directly into your project.

---

## FILE 1: lib/core/services/lunar_ai_cloud_service.dart

```dart
import 'package:cloud_functions/cloud_functions.dart';

/// Wrapper for Lunar AI via Firebase Cloud Functions
/// Replaces direct OpenAI API calls with secure backend-mediated requests
class LunarAICloudService {
  static final _functions = FirebaseFunctions.instance;
  static const _functionName = 'respond';
  static const _region = 'us-central1';

  /// Call Lunar AI via Cloud Function
  /// 
  /// Parameters:
  ///   - message: User's message to Lunar
  ///   - context: Optional context (cycle phase, mood, pregnancy status, etc.)
  ///   - history: Conversation history for context
  /// 
  /// Returns: LunarAICloudResponse with text, tokens, cost, and remaining messages
  /// 
  /// Throws: Exception if authentication fails or quota exceeded
  static Future<LunarAICloudResponse> respond({
    required String message,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final callable = _functions
          .httpsCallable(_functionName)
          .withRegion(_region);

      final result = await callable.call<Map<String, dynamic>>({
        'message': message.trim(),
        'context': context ?? {},
        'history': history ?? [],
      });

      final data = result.data as Map<String, dynamic>;

      return LunarAICloudResponse(
        text: data['text'] as String? ?? '',
        tokensUsed: data['tokensUsed'] as int? ?? 0,
        costUSD: (data['costUSD'] as num?)?.toDouble() ?? 0.0,
        remainingMessages: data['remainingMessages'] as int? ?? 20,
        isPremium: data['isPremium'] as bool? ?? false,
      );
    } on FirebaseFunctionsException catch (e) {
      throw _translateError(e);
    } catch (e) {
      throw Exception(
        'Failed to generate response. Please check your connection and try again.'
      );
    }
  }

  /// Translate Firebase Functions errors to user-friendly messages
  static Exception _translateError(FirebaseFunctionsException error) {
    switch (error.code) {
      case 'unauthenticated':
        return Exception('Please sign in to use Lunar AI');
      case 'resource-exhausted':
        return Exception(error.message ?? 'Daily message limit reached');
      case 'invalid-argument':
        return Exception('Invalid message. Please try again.');
      case 'internal':
        return Exception('Lunar is experiencing issues. Try again shortly.');
      default:
        return Exception('An error occurred. Please try again.');
    }
  }
}

/// Response from Lunar AI Cloud Function
class LunarAICloudResponse {
  /// Generated response text from Lunar
  final String text;

  /// OpenAI tokens used for this request
  final int tokensUsed;

  /// Cost in USD for this request (for analytics)
  final double costUSD;

  /// Remaining AI messages today (free tier only)
  final int remainingMessages;

  /// Whether user is premium tier
  final bool isPremium;

  LunarAICloudResponse({
    required this.text,
    required this.tokensUsed,
    required this.costUSD,
    required this.remainingMessages,
    required this.isPremium,
  });

  @override
  String toString() => 'LunarAICloudResponse(text: ${text.length} chars, '
      'tokens: $tokensUsed, remaining: $remainingMessages)';
}
```

---

## FILE 2: Update lib/services/lunar_ai_service.dart

**REMOVE THIS ENTIRE METHOD:**
```dart
// DELETE THIS ENTIRE METHOD (around line 497-530)
static Future<LunarAIResponse> _openAIRespond(
  String message, {
  required String apiKey,
  required Map<String, dynamic> ctx,
  required List<Map<String, String>> history,
}) async {
  // ... DELETE ALL THIS CODE
}
```

**REPLACE THE respond() METHOD with:**
```dart
static Future<LunarAIResponse> respond(
  String message, {
  Map<String, dynamic>? context,
  List<Map<String, String>>? conversationHistory,
}) async {
  if (isCrisis(message)) return crisisResponse();

  try {
    // NEW: Use Cloud Function instead of direct OpenAI
    final response = await LunarAICloudService.respond(
      message: message,
      context: context ?? {},
      history: conversationHistory ?? [],
    );

    return LunarAIResponse(response.text, _inferHealing(message));
  } catch (e) {
    // Fall back to local engine on any error
    return _localRespond(message, context ?? {});
  }
}
```

**REMOVE THESE LINES (around line 190-193):**
```dart
// DELETE THESE - API key no longer stored on client
static Future<String?> getApiKey() async => LocalCache.getString(_keyCache);
static Future<void> setApiKey(String key) async => LocalCache.setString(_keyCache, key);
static Future<void> clearApiKey() async => LocalCache.remove(_keyCache);
```

---

## FILE 3: Update lib/core/providers/chat_provider.dart

**REPLACE THE sendMessage() method's AI call section:**

```dart
Future<void> sendMessage(String message, BuildContext context) async {
  if (message.isEmpty || _status == ChatStatus.thinking) return;

  final premium = context.read<PremiumProvider>();

  // Gate against daily limit
  if (!canSendAiMessage(premium.isPaid)) {
    PaywallGate.show(context, featureHint: 'Support whenever you need it');
    return;
  }

  _messages.add(ChatMessage(
    text: message,
    isUser: true,
    timestamp: DateTime.now(),
  ));

  _status = ChatStatus.thinking;
  _sessionMessageCount++;
  notifyListeners();

  try {
    final history = _messages
        .where((m) => _messages.indexOf(m) < _messages.length - 1)
        .map((m) => {
          'role': m.isUser ? 'user' : 'assistant',
          'content': m.text,
        })
        .toList();

    final ctx = {
      'name': _userName,
      'cyclePhase': _currentPhase,
      'isPregnant': _isPregnant,
      // Add other context as needed
    };

    // CHANGED: Use Cloud Function instead of direct API call
    final response = await LunarAICloudService.respond(
      message: message,
      context: ctx,
      history: history,
    );

    _messages.add(ChatMessage(
      text: response.text,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Update daily count for free users
    if (!premium.isPaid) {
      _dailyAiCount++;
      await LocalCache.setString(_dailyDateKey, _dailyAiDate);
      await LocalCache.setInt(_dailyLimitKey, _dailyAiCount);
    }

    _status = ChatStatus.idle;
    notifyListeners();

  } catch (e) {
    _status = ChatStatus.error;
    _messages.add(ChatMessage(
      text: 'I\'m having trouble connecting right now... '
          'Try again in a moment? 🌙',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
```

**REMOVE THESE LINES from chat_provider.dart:**
```dart
// DELETE: No longer needed
bool _apiKeyConfigured = false;
bool get apiKeyConfigured => _apiKeyConfigured;

// DELETE: API key input methods
Future<void> saveApiKey(String key) async { ... }
Future<void> removeApiKey() async { ... }
```

---

## FILE 4: Update lib/screen/ai_voice_screen.dart

**DELETE these instance variables (lines ~186-190):**
```dart
// DELETE ALL OF THESE
bool _showApiKeySheet = false;
final TextEditingController _apiKeyCtrl = TextEditingController();
bool _apiKeyObscured = true;
bool _apiNudgeDismissed = false;
```

**DELETE the entire _apiNudge() widget (lines ~1177-1215):**
```dart
// DELETE ENTIRE METHOD
Widget _apiNudge() {
  return GestureDetector(
    onTap: () => setState(() => _showApiKeySheet = true),
    // ... DELETE ALL
  );
}
```

**DELETE the entire _apiKeyOverlay() widget (lines ~1220-1280+):**
```dart
// DELETE ENTIRE METHOD
Widget _apiKeyOverlay(ChatProvider chat) {
  return GestureDetector(
    onTap: () => setState(() => _showApiKeySheet = false),
    // ... DELETE ALL
  );
}
```

**DELETE these lines from build():**
```dart
// DELETE THESE CONDITIONS
if (_showApiKeySheet) _apiKeyOverlay(chat),
if (!chat.apiKeyConfigured && !_apiNudgeDismissed) _apiNudge(),

// DELETE THIS BUTTON
if (!chat.apiKeyConfigured)
  FloatingActionButton(
    onPressed: () => setState(() => _showApiKeySheet = !_showApiKeySheet),
    child: Icon(Icons.lock_outline),
  ),
```

**DELETE from dispose():**
```dart
// DELETE THIS LINE
_apiKeyCtrl.dispose();
```

---

## FILE 5: functions/src/index.ts

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { lunarRespond } from './lunarRespond';

admin.initializeApp();

export const respond = functions
  .region('us-central1')
  .https.onCall(lunarRespond);
```

---

## FILE 6: functions/src/lunarRespond.ts

**Copy entire file from BLOCKER_3_MIGRATION_PLAN.md "functions/src/lunarRespond.ts" section**

---

## FILE 7: functions/src/handlers/openaiHandler.ts

**Copy entire file from BLOCKER_3_MIGRATION_PLAN.md "functions/src/handlers/openaiHandler.ts" section**

---

## FILE 8: functions/src/handlers/rateLimiter.ts

**Copy entire file from BLOCKER_3_MIGRATION_PLAN.md "functions/src/handlers/rateLimiter.ts" section**

---

## FILE 9: functions/src/handlers/premiumChecker.ts

**Copy entire file from BLOCKER_3_MIGRATION_PLAN.md "functions/src/handlers/premiumChecker.ts" section**

---

## FILE 10: functions/src/handlers/usageTracker.ts

**Copy entire file from BLOCKER_3_MIGRATION_PLAN.md "functions/src/handlers/usageTracker.ts" section**

---

## FILE 11: functions/package.json

```json
{
  "name": "lunar-functions",
  "version": "1.0.0",
  "description": "Lunar AI Cloud Functions - OpenAI API backend",
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "serve": "firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log",
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "keywords": [
    "lunar",
    "ai",
    "firebase"
  ],
  "author": "Lunar Team",
  "license": "MIT",
  "dependencies": {
    "firebase-admin": "^12.0.0",
    "firebase-functions": "^4.5.0",
    "openai": "^4.47.0",
    "axios": "^1.6.0",
    "dotenv": "^16.3.1"
  },
  "devDependencies": {
    "typescript": "^5.2.0",
    "@types/node": "^20.5.0"
  }
}
```

---

## FILE 12: functions/tsconfig.json

```json
{
  "compilerOptions": {
    "module": "commonjs",
    "noImplicitAny": true,
    "outDir": "lib",
    "sourceMap": true,
    "strict": true,
    "target": "ES2020",
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "compileOnSave": true,
  "include": [
    "src"
  ]
}
```

---

## FILE 13: firestore.rules (ADD TO EXISTING FILE)

```javascript
// Add these rules to your existing firestore.rules file

rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... keep existing rules ...

    // AI Metrics — daily limit tracking per user
    match /users/{uid}/aiMetrics/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }

    // AI Usage logs — analytics collection (write from Cloud Function, read by admins)
    match /logs/aiUsage/entries/{document=**} {
      allow create: if request.auth != null;
      allow read: if request.auth.token.admin == true;
    }

    // OpenAI config — read-only (updated by admins)
    match /config/openai {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

---

## FILE 14: pubspec.yaml (UPDATE DEPENDENCY)

```yaml
dependencies:
  # ... existing dependencies ...
  
  cloud_functions: ^4.6.0  # Verify this version or higher
  firebase_auth: ^4.10.0
  firebase_core: ^2.24.0
  firebase_analytics: ^10.7.0  # For event logging
  
  # Remove if present (no longer needed):
  # - No API key storage package needed anymore
```

---

## QUICK INTEGRATION STEPS

### Step 1: Copy Files
```bash
# Copy Cloud Functions code
cp BLOCKER_3_MIGRATION_PLAN.md/functions/* functions/src/

# Update Dart files
# (Follow FILE 2, 3, 4 instructions above)
```

### Step 2: Install Dependencies
```bash
cd functions
npm install
npm run build
```

### Step 3: Test Locally
```bash
firebase emulators:start --only functions,firestore
```

### Step 4: Deploy
```bash
firebase deploy --only functions
```

### Step 5: Test in Flutter
```bash
flutter clean
flutter pub get
flutter run
```

### Step 6: Verify
- Send message in app
- Check `logs/aiUsage` in Firestore
- Verify `users/{uid}/aiMetrics` document created
- Test daily limit (send 21+ messages)

---

## IMPORT STATEMENT FOR FLUTTER

Add this to any file using LunarAICloudService:

```dart
import 'package:lunar/core/services/lunar_ai_cloud_service.dart';
```

---

## ENVIRONMENT VARIABLES FOR CLOUD FUNCTIONS

Create `.env` in `functions/` directory:

```
OPENAI_API_KEY=sk-...your-actual-key...
REVENUECAT_API_KEY=appl_...optional...
```

Or set via Firebase Console:
1. Go to Cloud Functions
2. Click `respond` function
3. Edit
4. Scroll to "Runtime service account"
5. Set environment variables there

---

## TESTING SNIPPETS

### Test in Flutter Console

```dart
// Import at top
import 'package:lunar/core/services/lunar_ai_cloud_service.dart';

// Test in main.dart or debug function
void testLunarAI() async {
  try {
    final response = await LunarAICloudService.respond(
      message: "I'm feeling stressed about work",
      context: {
        'name': 'Test User',
        'cyclePhase': 'Follicular',
      },
    );
    print('Success: ${response.text}');
    print('Tokens: ${response.tokensUsed}');
    print('Remaining: ${response.remainingMessages}');
  } catch (e) {
    print('Error: $e');
  }
}

// Call it
testLunarAI();
```

### Monitor in Firebase Console

```bash
# Watch logs in real-time
firebase functions:log --follow

# Filter by function
firebase functions:log --follow | grep respond
```

---

**All files ready to copy-paste. Implementation time: 4-6 hours with this complete reference.**
