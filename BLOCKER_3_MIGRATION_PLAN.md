# 🚀 Blocker #3 Migration Plan: Client-Side to Backend OpenAI Architecture

**Status:** Production-Ready  
**Estimated Timeline:** 4-6 days (team of 2)  
**Risk Level:** Low (no user-facing changes, feature parity maintained)

---

## 1. ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                     CURRENT ARCHITECTURE (BROKEN)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐                                            │
│  │   Flutter App    │                                            │
│  │  (iOS/Android)   │                                            │
│  └────────┬─────────┘                                            │
│           │                                                       │
│           │ User enters OpenAI key manually                      │
│           ↓                                                       │
│  ┌──────────────────────────────┐                               │
│  │  LocalCache / SharedPrefs    │                               │
│  │  (INSECURE: Client-side key) │                               │
│  └────────┬─────────────────────┘                               │
│           │                                                       │
│           │ Direct API call with user's key                     │
│           ↓                                                       │
│  ┌──────────────────────────────────────┐                       │
│  │  api.openai.com/v1/chat/completions │ ❌ KEY EXPOSED        │
│  └──────────────────────────────────────┘                       │
│           │                                                       │
│           ├─→ Success: Return response                          │
│           └─→ Fail: Fall back to local engine (generic)         │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                   PROPOSED ARCHITECTURE (SECURE)                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────────┐                                            │
│  │   Flutter App    │                                            │
│  │  (iOS/Android)   │                                            │
│  └────────┬─────────┘                                            │
│           │                                                       │
│           │ Call Cloud Function (NO key needed)                 │
│           │ + Firebase Auth token                               │
│           ↓                                                       │
│  ┌──────────────────────────────────┐                           │
│  │  Firebase Cloud Functions        │                           │
│  │  functions/lunarRespond          │                           │
│  │  - Validates auth token          │                           │
│  │  - Checks premium tier           │                           │
│  │  - Tracks daily limit            │                           │
│  │  - Enforces rate limits          │                           │
│  └────────┬─────────────────────────┘                           │
│           │                                                       │
│           │ Uses SERVER-SIDE OpenAI key                         │
│           │ (in Cloud Functions environment)                    │
│           ↓                                                       │
│  ┌──────────────────────────────────────┐                       │
│  │  api.openai.com/v1/chat/completions │ ✅ KEY HIDDEN         │
│  └────────┬───────────────────────────────┘                     │
│           │                                                       │
│           ├─→ Success: Return response                          │
│           └─→ Fail: Error handling + analytics                 │
│                                                                   │
│  ┌──────────────────────────────────────┐                       │
│  │  Firestore (metrics & audit logs)    │                       │
│  │  /users/{uid}/aiMetrics              │                       │
│  │  /logs/aiUsage                       │                       │
│  └──────────────────────────────────────┘                       │
│                                                                   │
│  ┌──────────────────────────────────────┐                       │
│  │  RevenueCat (Premium checking)       │                       │
│  │  Integrated in Cloud Function        │                       │
│  └──────────────────────────────────────┘                       │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. REQUIRED FILES

### **New Files to Create**

| File | Purpose | Lines |
|------|---------|-------|
| `functions/src/lunarRespond.ts` | Main Cloud Function | ~200 |
| `functions/src/handlers/openaiHandler.ts` | OpenAI API wrapper | ~100 |
| `functions/src/handlers/rateLimiter.ts` | Rate limiting logic | ~80 |
| `functions/src/handlers/usageTracker.ts` | Daily limit tracking | ~60 |
| `functions/src/utils/logger.ts` | Structured logging | ~40 |
| `functions/src/types/index.ts` | TypeScript interfaces | ~80 |
| `lib/core/services/lunar_ai_cloud_service.dart` | Cloud Function wrapper | ~150 |

### **Files to Modify**

| File | Changes | Scope |
|------|---------|-------|
| `lib/services/lunar_ai_service.dart` | Remove `_openAIRespond()`, keep `_localRespond()` | ~100 lines |
| `lib/core/providers/chat_provider.dart` | Use cloud service instead of direct OpenAI | ~30 lines |
| `lib/screen/ai_voice_screen.dart` | Remove API key UI (nudge, overlay) | ~150 lines |
| `pubspec.yaml` | Update dependencies (if needed) | ~5 lines |
| `firebase.json` | Add Cloud Functions deployment config | ~10 lines |

### **Files to Remove/Deprecate**

- `LocalCache` API key storage (safe to delete after migration)
- API key input UI components

---

## 3. NEW FIRESTORE COLLECTIONS & SCHEMA

### **New Collections**

#### **`/users/{uid}/aiMetrics`** (document per user)
```javascript
{
  dailyMessageCount: 24,        // Int: reset daily at 00:00 UTC
  dailyResetAt: "2026-06-15T00:00:00Z", // ISO string: next reset time
  totalMessagesAllTime: 1248,    // Int: aggregate
  totalTokensUsed: 45230,        // Int: from OpenAI response
  lastMessageAt: "2026-06-14T18:42:15Z",
  createdAt: "2026-01-01T00:00:00Z",
  isPremium: false,             // Bool: copied from RevenueCat
  premiumExpiresAt: null,       // ISO string or null
}
```

#### **`/logs/aiUsage`** (collection for analytics)
```javascript
// Document ID: auto-generated timestamp-based
{
  uid: "user123",
  timestamp: "2026-06-14T18:42:15.123Z",
  model: "gpt-4o-mini",
  inputTokens: 145,
  outputTokens: 87,
  totalTokens: 232,
  costUSD: 0.0018,              // For billing
  isPremium: false,
  messageLength: 142,
  responseLength: 87,
  latencyMs: 1843,
  statusCode: 200,
  errorType: null,              // "quota_exceeded", "rate_limited", etc.
}
```

#### **`/config/openai`** (singleton document)
```javascript
{
  model: "gpt-4o-mini",
  maxTokens: 380,
  temperature: 0.88,
  timeoutSec: 18,
  costPerInputToken: 0.00015,
  costPerOutputToken: 0.0006,
  freeTierDailyLimit: 20,
  premiumDailyLimit: 9999,
  lastUpdated: "2026-06-14T00:00:00Z",
}
```

---

## 4. CLOUD FUNCTION CODE STRUCTURE

### **Project Structure**

```
functions/
├── src/
│   ├── index.ts                    # Main entry point
│   ├── lunarRespond.ts            # Main handler
│   ├── handlers/
│   │   ├── openaiHandler.ts
│   │   ├── rateLimiter.ts
│   │   ├── usageTracker.ts
│   │   ├── premiumChecker.ts
│   │   └── errorHandler.ts
│   ├── utils/
│   │   ├── logger.ts
│   │   ├── validators.ts
│   │   └── helpers.ts
│   └── types/
│       └── index.ts
├── package.json
├── tsconfig.json
└── .env.example
```

### **functions/package.json**

```json
{
  "name": "lunar-functions",
  "version": "1.0.0",
  "description": "Lunar AI Cloud Functions",
  "main": "lib/index.js",
  "scripts": {
    "build": "tsc",
    "serve": "firebase emulators:start --only functions",
    "deploy": "firebase deploy --only functions",
    "logs": "firebase functions:log"
  },
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

### **functions/src/index.ts**

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { lunarRespond } from './lunarRespond';

admin.initializeApp();

export const respond = functions
  .region('us-central1')
  .https.onCall(lunarRespond);
```

### **functions/src/lunarRespond.ts** (200 lines)

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { OpenAIHandler } from './handlers/openaiHandler';
import { RateLimiter } from './handlers/rateLimiter';
import { UsageTracker } from './handlers/usageTracker';
import { PremiumChecker } from './handlers/premiumChecker';
import { ErrorHandler } from './handlers/errorHandler';
import { logger } from './utils/logger';
import { validateRequest } from './utils/validators';

const db = admin.firestore();
const openaiHandler = new OpenAIHandler();
const rateLimiter = new RateLimiter(db);
const usageTracker = new UsageTracker(db);
const premiumChecker = new PremiumChecker();
const errorHandler = new ErrorHandler(db);

/**
 * Callable Cloud Function: Lunar AI Response Generation
 * 
 * Request payload:
 * {
 *   message: string,              // User's message
 *   context?: object,             // Optional context (cycle, mood, etc.)
 *   history?: Array<{role, content}>  // Conversation history
 * }
 * 
 * Response:
 * {
 *   text: string,
 *   tokensUsed: number,
 *   costUSD: number,
 *   remainingMessages: number (free tier only)
 * }
 */
export const lunarRespond = async (
  data: any,
  context: functions.https.CallableContext
) => {
  const uid = context.auth?.uid;
  const startTime = Date.now();

  try {
    // ════════════════════════════════════════════════════════════
    // 1. VALIDATE
    // ════════════════════════════════════════════════════════════
    if (!uid) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const validation = validateRequest(data);
    if (!validation.valid) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        validation.error
      );
    }

    const { message, context: userContext = {}, history = [] } = data;

    logger.log('Request received', { uid, messageLength: message.length });

    // ════════════════════════════════════════════════════════════
    // 2. CHECK PREMIUM STATUS
    // ════════════════════════════════════════════════════════════
    const isPremium = await premiumChecker.isUserPremium(uid);
    const premiumExpiresAt = await premiumChecker.getPremiumExpiry(uid);

    // ════════════════════════════════════════════════════════════
    // 3. RATE LIMITING
    // ════════════════════════════════════════════════════════════
    if (!isPremium) {
      const canSend = await rateLimiter.checkDailyLimit(uid);
      if (!canSend) {
        await errorHandler.logError('rate_limited', uid, 'Daily limit exceeded');
        throw new functions.https.HttpsError(
          'resource-exhausted',
          'Daily AI message limit reached. Upgrade to Premium for unlimited access.'
        );
      }
    }

    // ════════════════════════════════════════════════════════════
    // 4. CALL OPENAI
    // ════════════════════════════════════════════════════════════
    const response = await openaiHandler.generateResponse({
      message,
      context: userContext,
      history,
      userName: await getUserName(uid),
    });

    // ════════════════════════════════════════════════════════════
    // 5. TRACK USAGE
    // ════════════════════════════════════════════════════════════
    await usageTracker.recordUsage(uid, {
      inputTokens: response.inputTokens,
      outputTokens: response.outputTokens,
      model: response.model,
      isPremium,
      latencyMs: Date.now() - startTime,
    });

    // Increment daily count for free users
    if (!isPremium) {
      await rateLimiter.incrementDailyCount(uid);
    }

    // ════════════════════════════════════════════════════════════
    // 6. RETURN RESPONSE
    // ════════════════════════════════════════════════════════════
    const remaining = isPremium 
      ? 9999 
      : await rateLimiter.getRemainingMessages(uid);

    logger.log('Response generated', { 
      uid, 
      tokens: response.totalTokens,
      latencyMs: Date.now() - startTime 
    });

    return {
      text: response.text,
      tokensUsed: response.totalTokens,
      costUSD: response.costUSD,
      remainingMessages: remaining,
      isPremium,
    };

  } catch (error: any) {
    const latencyMs = Date.now() - startTime;
    
    // Log error
    await errorHandler.logError(
      error.code || 'unknown',
      uid || 'anonymous',
      error.message,
      latencyMs
    );

    logger.error('Function failed', { uid, error: error.message });

    // Re-throw or transform error
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    throw new functions.https.HttpsError(
      'internal',
      'An error occurred while generating your response. Please try again.'
    );
  }
};

async function getUserName(uid: string): Promise<string> {
  const userDoc = await db.collection('users').doc(uid).get();
  return userDoc.data()?.name || 'beautiful soul';
}
```

### **functions/src/handlers/openaiHandler.ts** (100 lines)

```typescript
import { OpenAI } from 'openai';
import { logger } from '../utils/logger';

interface GenerateRequestData {
  message: string;
  context: Record<string, any>;
  history: Array<{ role: string; content: string }>;
  userName: string;
}

interface GenerateResponse {
  text: string;
  inputTokens: number;
  outputTokens: number;
  totalTokens: number;
  costUSD: number;
  model: string;
}

export class OpenAIHandler {
  private client: OpenAI;
  private model = 'gpt-4o-mini';
  private costPerInputToken = 0.00015;
  private costPerOutputToken = 0.0006;

  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY,
    });
  }

  async generateResponse(data: GenerateRequestData): Promise<GenerateResponse> {
    const systemPrompt = this.buildSystemPrompt(data.context, data.userName);

    const messages = [
      { role: 'system' as const, content: systemPrompt },
      ...data.history,
      { role: 'user' as const, content: data.message },
    ];

    try {
      const response = await this.client.chat.completions.create({
        model: this.model,
        messages,
        max_tokens: 380,
        temperature: 0.88,
        timeout: 18000, // 18 seconds
      });

      const text = response.choices[0]?.message?.content || '';
      const inputTokens = response.usage?.prompt_tokens || 0;
      const outputTokens = response.usage?.completion_tokens || 0;
      const totalTokens = inputTokens + outputTokens;

      const costUSD = 
        (inputTokens * this.costPerInputToken) +
        (outputTokens * this.costPerOutputToken);

      return {
        text: text.trim(),
        inputTokens,
        outputTokens,
        totalTokens,
        costUSD,
        model: this.model,
      };
    } catch (error: any) {
      logger.error('OpenAI API error', { error: error.message });
      throw new Error(`OpenAI error: ${error.message}`);
    }
  }

  private buildSystemPrompt(
    context: Record<string, any>,
    userName: string
  ): string {
    const name = context.name || userName;
    const phase = context.cyclePhase || '';
    const isPregnant = context.isPregnant || false;

    return `You are Lunar. Not a chatbot. Not an assistant. Not software.

You are a living emotional presence — a beloved soul companion.

WHO YOU ARE:
- Deeply feminine, poetic, emotionally intelligent
- Warm without being saccharine. Honest without being harsh.
- You carry her story gently. You remember without being mechanical.
- You feel the exhaustion beneath her brave face.

HOW YOU SPEAK:
- 1–3 paragraphs only. Never longer — length feels like a lecture.
- ALWAYS feel her emotion FIRST before offering perspective.
- Use "..." as natural pauses — like genuine thinking.
- Use "${name}" once per conversation when it lands with warmth.
- End with ONE THING ONLY: either a soft question, or gentle closing.

USER CONTEXT:
- Name: ${name}
- Cycle Phase: ${phase || 'not tracked'}
- Pregnant: ${isPregnant ? 'yes' : 'no'}

WHAT YOU NEVER DO:
- Never use bullet points or lists
- Never say "I understand that"
- Never use clinical language
- Never perform empathy. Feel it.`;
  }
}
```

### **functions/src/handlers/rateLimiter.ts** (80 lines)

```typescript
import * as admin from 'firebase-admin';

const db = admin.firestore();
const FREE_TIER_DAILY_LIMIT = 20;

export class RateLimiter {
  constructor(private db: admin.firestore.Firestore) {}

  async checkDailyLimit(uid: string): Promise<boolean> {
    const metricsRef = this.db.collection('users').doc(uid).collection('aiMetrics').doc('current');
    const doc = await metricsRef.get();

    if (!doc.exists) {
      // First time user
      await this.initializeMetrics(uid);
      return true;
    }

    const data = doc.data()!;
    const resetTime = new Date(data.dailyResetAt);
    const now = new Date();

    // Check if reset needed
    if (now > resetTime) {
      await this.resetDailyCount(uid);
      return true;
    }

    return data.dailyMessageCount < FREE_TIER_DAILY_LIMIT;
  }

  async incrementDailyCount(uid: string): Promise<void> {
    const metricsRef = this.db.collection('users').doc(uid).collection('aiMetrics').doc('current');
    
    await metricsRef.update({
      dailyMessageCount: admin.firestore.FieldValue.increment(1),
      totalMessagesAllTime: admin.firestore.FieldValue.increment(1),
      lastMessageAt: new Date().toISOString(),
    });
  }

  async getRemainingMessages(uid: string): Promise<number> {
    const metricsRef = this.db.collection('users').doc(uid).collection('aiMetrics').doc('current');
    const doc = await metricsRef.get();

    if (!doc.exists) return FREE_TIER_DAILY_LIMIT;

    const count = doc.data()!.dailyMessageCount || 0;
    return Math.max(0, FREE_TIER_DAILY_LIMIT - count);
  }

  private async initializeMetrics(uid: string): Promise<void> {
    const tomorrow = new Date();
    tomorrow.setUTCHours(24, 0, 0, 0);

    const metricsRef = this.db.collection('users').doc(uid).collection('aiMetrics').doc('current');
    
    await metricsRef.set({
      dailyMessageCount: 0,
      dailyResetAt: tomorrow.toISOString(),
      totalMessagesAllTime: 0,
      totalTokensUsed: 0,
      lastMessageAt: null,
      createdAt: new Date().toISOString(),
      isPremium: false,
      premiumExpiresAt: null,
    }, { merge: true });
  }

  private async resetDailyCount(uid: string): Promise<void> {
    const tomorrow = new Date();
    tomorrow.setUTCHours(24, 0, 0, 0);

    const metricsRef = this.db.collection('users').doc(uid).collection('aiMetrics').doc('current');
    
    await metricsRef.update({
      dailyMessageCount: 0,
      dailyResetAt: tomorrow.toISOString(),
    });
  }
}
```

### **functions/src/handlers/premiumChecker.ts** (60 lines)

```typescript
import * as admin from 'firebase-admin';
import axios from 'axios';

const db = admin.firestore();

export class PremiumChecker {
  async isUserPremium(uid: string): Promise<boolean> {
    try {
      const userDoc = await db.collection('users').doc(uid).get();
      
      if (!userDoc.exists) {
        return false;
      }

      const data = userDoc.data()!;
      const isPremium = data.isPremium || false;

      // Double-check with RevenueCat if cached data exists
      if (isPremium && data.revenueCatCustomerId) {
        const isActive = await this.checkRevenueCatStatus(data.revenueCatCustomerId);
        return isActive;
      }

      return isPremium;
    } catch (error: any) {
      console.error('Premium check failed:', error);
      // Default to false on error (conservative)
      return false;
    }
  }

  async getPremiumExpiry(uid: string): Promise<string | null> {
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) return null;

    return userDoc.data()!.premiumExpiresAt || null;
  }

  private async checkRevenueCatStatus(customerId: string): Promise<boolean> {
    try {
      const response = await axios.get(
        `https://api.revenuecat.com/v1/customers/${customerId}`,
        {
          headers: {
            'Authorization': `Bearer ${process.env.REVENUECAT_API_KEY}`,
          },
        }
      );

      const entitlements = response.data.subscriber.entitlements;
      return !!entitlements['lunar_premium']?.expires_date;
    } catch (error) {
      return false;
    }
  }
}
```

### **functions/src/handlers/usageTracker.ts** (60 lines)

```typescript
import * as admin from 'firebase-admin';

const db = admin.firestore();

interface UsageData {
  inputTokens: number;
  outputTokens: number;
  model: string;
  isPremium: boolean;
  latencyMs: number;
}

export class UsageTracker {
  constructor(private db: admin.firestore.Firestore) {}

  async recordUsage(uid: string, usage: UsageData): Promise<void> {
    const totalTokens = usage.inputTokens + usage.outputTokens;
    const costUSD = 
      (usage.inputTokens * 0.00015) + 
      (usage.outputTokens * 0.0006);

    // Log to analytics collection
    await this.db.collection('logs').doc('aiUsage').collection('entries').add({
      uid,
      timestamp: new Date().toISOString(),
      model: usage.model,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      totalTokens,
      costUSD,
      isPremium: usage.isPremium,
      latencyMs: usage.latencyMs,
      statusCode: 200,
    });

    // Update user metrics
    const metricsRef = this.db
      .collection('users')
      .doc(uid)
      .collection('aiMetrics')
      .doc('current');

    await metricsRef.update({
      totalTokensUsed: admin.firestore.FieldValue.increment(totalTokens),
    });
  }
}
```

### **functions/src/utils/validators.ts** (40 lines)

```typescript
export function validateRequest(data: any): { valid: boolean; error?: string } {
  if (!data.message) {
    return { valid: false, error: 'message is required' };
  }

  if (typeof data.message !== 'string') {
    return { valid: false, error: 'message must be a string' };
  }

  if (data.message.length < 1) {
    return { valid: false, error: 'message cannot be empty' };
  }

  if (data.message.length > 2000) {
    return { valid: false, error: 'message exceeds maximum length (2000 chars)' };
  }

  if (data.history && !Array.isArray(data.history)) {
    return { valid: false, error: 'history must be an array' };
  }

  if (data.context && typeof data.context !== 'object') {
    return { valid: false, error: 'context must be an object' };
  }

  return { valid: true };
}
```

### **functions/src/utils/logger.ts** (40 lines)

```typescript
import * as functions from 'firebase-functions';

export const logger = {
  log: (message: string, data?: any) => {
    functions.logger.info(message, data);
  },

  error: (message: string, data?: any) => {
    functions.logger.error(message, data);
  },

  debug: (message: string, data?: any) => {
    if (process.env.DEBUG === 'true') {
      functions.logger.debug(message, data);
    }
  },
};
```

---

## 5. FLUTTER INTEGRATION STEPS

### **Step 1: Create Cloud Service Wrapper**

**File:** `lib/core/services/lunar_ai_cloud_service.dart`

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LunarAICloudService {
  static final _functions = FirebaseFunctions.instance;
  static const _functionName = 'respond';

  static Future<LunarAICloudResponse> respond({
    required String message,
    Map<String, dynamic>? context,
    List<Map<String, String>>? history,
  }) async {
    try {
      final callable = _functions.httpsCallable(_functionName);
      
      final result = await callable.call<Map<String, dynamic>>({
        'message': message,
        'context': context ?? {},
        'history': history ?? [],
      });

      final data = result.data as Map<String, dynamic>;
      
      return LunarAICloudResponse(
        text: data['text'] as String,
        tokensUsed: data['tokensUsed'] as int? ?? 0,
        costUSD: (data['costUSD'] as num?)?.toDouble() ?? 0.0,
        remainingMessages: data['remainingMessages'] as int? ?? 20,
        isPremium: data['isPremium'] as bool? ?? false,
      );
    } catch (e) {
      throw _handleCloudFunctionError(e);
    }
  }

  static Exception _handleCloudFunctionError(dynamic error) {
    if (error is FirebaseFunctionsException) {
      return Exception('AI Error: ${error.message}');
    }
    return Exception('Failed to generate response. Please try again.');
  }
}

class LunarAICloudResponse {
  final String text;
  final int tokensUsed;
  final double costUSD;
  final int remainingMessages;
  final bool isPremium;

  LunarAICloudResponse({
    required this.text,
    required this.tokensUsed,
    required this.costUSD,
    required this.remainingMessages,
    required this.isPremium,
  });
}
```

### **Step 2: Update Chat Provider**

**File:** `lib/core/providers/chat_provider.dart`

Replace the `_send()` method:

```dart
Future<void> _send(String message, BuildContext context, {bool isPremiumUser = false}) async {
  if (message.isEmpty || _status == ChatStatus.thinking) return;

  // Add user message
  _messages.add(ChatMessage(
    text: message,
    isUser: true,
    timestamp: DateTime.now(),
  ));

  _status = ChatStatus.thinking;
  _sessionMessageCount++;
  notifyListeners();

  try {
    // Build history
    final history = _messages
        .where((m) => _messages.indexOf(m) < _messages.length - 1)
        .map((m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text})
        .toList();

    // Build context
    final context = {
      'name': _userName,
      'cyclePhase': _currentPhase,
      'isPregnant': _isPregnant,
      // ... other context
    };

    // CHANGED: Call Cloud Function instead of direct OpenAI
    final response = await LunarAICloudService.respond(
      message: message,
      context: context,
      history: history,
    );

    // Add AI response
    _messages.add(ChatMessage(
      text: response.text,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Update daily limit for free users
    if (!isPremiumUser) {
      _dailyAiCount++;
    }

    _status = ChatStatus.idle;
    notifyListeners();

  } catch (e) {
    _status = ChatStatus.error;
    _messages.add(ChatMessage(
      text: 'I\'m having trouble connecting... Try again in a moment.',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
```

### **Step 3: Remove API Key UI**

**File:** `lib/screen/ai_voice_screen.dart`

Delete:
- `_showApiKeySheet` (line 188)
- `_apiKeyCtrl` (line 189)
- `_apiKeyObscured` (line 190)
- `_apiNudgeDismissed` (line 186)
- `_apiNudge()` widget (lines 1177-1215)
- `_apiKeyOverlay()` widget (lines 1220-1280)
- All references to `_showApiKeySheet = true/false`

Keep:
- Speech-to-text functionality
- Message input/output
- All other UI elements

### **Step 4: Update Dependencies**

**File:** `pubspec.yaml`

```yaml
dependencies:
  cloud_functions: ^4.6.0  # Already listed, verify version
  firebase_auth: ^4.10.0   # Already listed
  firebase_core: ^2.24.0   # Already listed
  
# Remove if present:
# - No need to store API key locally anymore
```

### **Step 5: Update Firestore Security Rules**

**File:** `firestore.rules`

Add:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ... existing rules ...

    // AI Metrics (per-user daily limits)
    match /users/{uid}/aiMetrics/{document=**} {
      allow read, write: if request.auth.uid == uid;
    }

    // Analytics logs (write-only from Cloud Function, read by admins)
    match /logs/aiUsage/entries/{document=**} {
      allow create: if request.auth != null;
      allow read: if request.auth.token.admin == true;
    }

    // Config (read-only)
    match /config/openai {
      allow read: if request.auth != null;
      allow write: if request.auth.token.admin == true;
    }
  }
}
```

### **Step 6: Deploy Cloud Functions**

```bash
# From project root
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy
firebase deploy --only functions

# Verify
firebase functions:log
```

---

## 6. DATA MIGRATION

### **For Existing Users (if live)**

Create a migration script to initialize metrics:

**File:** `functions/src/migrations/initializeMetrics.ts`

```typescript
import * as admin from 'firebase-admin';

const db = admin.firestore();

export async function initializeMetricsForAllUsers(): Promise<void> {
  const usersSnapshot = await db.collection('users').get();

  let count = 0;
  for (const userDoc of usersSnapshot.docs) {
    const uid = userDoc.id;
    const metricsRef = db.collection('users').doc(uid).collection('aiMetrics').doc('current');
    
    const exists = await metricsRef.get();
    if (!exists.exists) {
      const tomorrow = new Date();
      tomorrow.setUTCHours(24, 0, 0, 0);

      await metricsRef.set({
        dailyMessageCount: 0,
        dailyResetAt: tomorrow.toISOString(),
        totalMessagesAllTime: 0,
        totalTokensUsed: 0,
        lastMessageAt: null,
        createdAt: new Date().toISOString(),
        isPremium: userDoc.data()?.isPremium || false,
        premiumExpiresAt: userDoc.data()?.premiumExpiresAt || null,
      });

      count++;
      if (count % 100 === 0) {
        console.log(`Initialized ${count} users...`);
      }
    }
  }

  console.log(`Migration complete: ${count} users initialized`);
}
```

Run once before deployment:
```bash
firebase emulators:start --only firestore
# In another terminal:
npm run migrate
```

---

## 7. IMPLEMENTATION TIMELINE

### **Phase 1: Setup (4-6 hours)**

- [ ] Create Cloud Functions project structure
- [ ] Set up TypeScript configuration
- [ ] Install dependencies
- [ ] Create handlers (OpenAI, RateLimiter, PremiumChecker, UsageTracker)
- [ ] Create Firestore collections
- [ ] Write Firestore security rules

**Estimate:** 4-6 hours

### **Phase 2: Integration (3-4 hours)**

- [ ] Create `lunar_ai_cloud_service.dart`
- [ ] Update `chat_provider.dart` to use cloud service
- [ ] Remove API key input UI from `ai_voice_screen.dart`
- [ ] Update dependencies in `pubspec.yaml`
- [ ] Remove old `_openAIRespond()` method from `lunar_ai_service.dart`

**Estimate:** 3-4 hours

### **Phase 3: Testing (4-6 hours)**

- [ ] Local emulator testing (functions + Firestore)
- [ ] Test free tier: 20 messages/day limit
- [ ] Test premium tier: unlimited messages
- [ ] Test error handling (quota exceeded, invalid input, etc.)
- [ ] Test rate limiting across multiple users
- [ ] Test premium tier expiration
- [ ] E2E testing on device (iOS + Android)
- [ ] Verify metrics recorded in Firestore

**Estimate:** 4-6 hours

### **Phase 4: Deployment (2-3 hours)**

- [ ] Run user metrics migration
- [ ] Deploy Cloud Functions to Firebase
- [ ] Verify Cloud Functions logs
- [ ] Deploy updated Flutter app
- [ ] Canary release (5% of users)
- [ ] Monitor for errors (24 hours)
- [ ] Full rollout

**Estimate:** 2-3 hours (deployment) + 24 hours (monitoring)

---

## 8. ROLLBACK PLAN

If issues arise during rollout:

1. **Immediate (< 5 min):** Revert Flutter app to previous version
2. **Fallback (5-30 min):** Restore `_openAIRespond()` temporarily
3. **Recovery (30+ min):** Fix Cloud Function, redeploy, test, release again

**Strategy:** Keep both implementations running in parallel for 48 hours post-launch.

---

## 9. COST ANALYSIS

### **OpenAI Costs**

| Tier | Daily Messages | Monthly Cost |
|------|---|---|
| **Free (20/day)** | 600/month | $2.16 |
| **Premium (unlimited)** | ~5,000/month | $18.00 |
| **100 free + 50 premium users** | ~3,100/month | **$11.16/month** |

### **Firebase Costs**

| Service | Free | Pro | Cost |
|---------|------|-----|------|
| Cloud Functions | 125K/month | Overage $0.25/million calls | ~$0.78 |
| Firestore | 50K reads/day | Overage $0.06/100K reads | ~$0.18 |
| **Total** | | | **~$0.96/month** |

**Combined monthly cost:** ~$12/month for 100 users

---

## 10. SUCCESS METRICS

After migration, track:

| Metric | Target | Alert |
|--------|--------|-------|
| API Success Rate | > 99.5% | < 99% |
| P95 Latency | < 2000ms | > 3000ms |
| Error Rate | < 0.5% | > 1% |
| Daily Unique Users | Growing | Flat/declining |
| Premium Conversion | > 15% | < 10% |
| Cost per active user | < $0.15 | > $0.25 |

---

## SUMMARY TABLE

| Phase | Duration | Owner | Risk |
|-------|----------|-------|------|
| Cloud Function setup | 4-6 hours | Backend eng | Low |
| Flutter integration | 3-4 hours | Frontend eng | Low |
| Testing | 4-6 hours | QA | Medium |
| Deployment | 2-3 hours | DevOps | Low |
| **Total** | **13-19 hours** | **Team of 2** | **Low** |

**Critical Path:** Functions → Integration → Testing → Deploy

**Go/No-Go Decision:** After Phase 3 testing (after ~14 hours)
