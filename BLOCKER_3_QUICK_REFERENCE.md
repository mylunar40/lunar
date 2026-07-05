# BLOCKER #3: Quick Reference Guides & Checklists

---

## FIREBASE SETUP CHECKLIST

```bash
# 1. Ensure Firebase project exists
firebase projects:list

# 2. Enable Cloud Functions API
gcloud services enable cloudfunctions.googleapis.com

# 3. Enable Cloud Build API (needed for deployments)
gcloud services enable cloudbuild.googleapis.com

# 4. Set up OpenAI secret in Cloud Functions
# Option A: Via Firebase Console
#   - Go to Project Settings → Service accounts
#   - Create new key in Google Cloud Console
#   - Store OPENAI_API_KEY as environment variable

# Option B: Via gcloud CLI
gcloud functions deploy respond \
  --set-env-vars OPENAI_API_KEY="sk-..." \
  --region us-central1

# 5. Set up RevenueCat integration (optional for initial deployment)
# Requires: REVENUECAT_API_KEY in Cloud Function secrets
```

---

## CLOUD FUNCTION DEPLOYMENT CHECKLIST

```
Before Deployment:
☐ All TypeScript compiles without errors: npm run build
☐ Environment variables set (.env file in functions/)
☐ API keys in Cloud Function secrets (not in code)
☐ Functions tested locally: firebase emulators:start
☐ Rate limiter tested with multiple users
☐ Premium tier exemption verified
☐ Error handling for quota exceeded
☐ Firestore rules deployed

Deployment:
☐ firebase deploy --only functions
☐ Verify deployment: firebase functions:log
☐ Monitor for errors (first 5 minutes)

Post-Deployment:
☐ Test with real Firebase project
☐ Verify daily metrics created for test user
☐ Check Firestore logs collection has entries
☐ Verify latency acceptable (< 2s)
☐ Test error scenario: invalid input
☐ Test error scenario: rate limit exceeded
```

---

## FLUTTER APP DEPLOYMENT CHECKLIST

```
Before Build:
☐ Remove all API key UI components
☐ Update chat_provider.dart to use LunarAICloudService
☐ Verify LunarAICloudService is imported
☐ Test on device (not emulator) with real Firebase
☐ Verify Firebase auth token sent to Cloud Function
☐ Test daily limit (send 21 messages as free user)
☐ Test premium exemption (set isPremium=true in user doc)
☐ Verify error messages user-friendly

Build & Test:
☐ flutter clean
☐ flutter pub get
☐ flutter build apk (Android)
☐ flutter build ios (iOS)
☐ Test on physical device

Deployment:
☐ Increment version in pubspec.yaml
☐ Tag git release: git tag v2.1.0
☐ Upload to Play Store / TestFlight
☐ Run A/B test with 5% of users (24h)
☐ Monitor crashes in Crashlytics
☐ Monitor function logs in Firebase Console
```

---

## FIRESTORE SCHEMA QUICK REFERENCE

### User Metrics Document
**Path:** `/users/{uid}/aiMetrics/current`

```json
{
  "dailyMessageCount": 5,
  "dailyResetAt": "2026-06-15T00:00:00Z",
  "totalMessagesAllTime": 248,
  "totalTokensUsed": 45230,
  "lastMessageAt": "2026-06-14T18:42:15Z",
  "createdAt": "2026-01-01T00:00:00Z",
  "isPremium": false,
  "premiumExpiresAt": null
}
```

### Usage Log Entry
**Path:** `/logs/aiUsage/entries/{auto-id}`

```json
{
  "uid": "user123",
  "timestamp": "2026-06-14T18:42:15.123Z",
  "model": "gpt-4o-mini",
  "inputTokens": 145,
  "outputTokens": 87,
  "totalTokens": 232,
  "costUSD": 0.0018,
  "isPremium": false,
  "latencyMs": 1843,
  "statusCode": 200
}
```

---

## ERROR HANDLING MATRIX

| Scenario | Cloud Function Returns | Flutter Receives | UI Shows |
|----------|---|---|---|
| **Valid request** | 200 + response | `LunarAICloudResponse` | AI message |
| **Not authenticated** | 401 unauthenticated | Exception | "Please sign in" |
| **Daily limit exceeded** | 429 resource-exhausted | Exception | "Upgrade for unlimited" |
| **Invalid input** | 400 invalid-argument | Exception | "Message too long" |
| **OpenAI quota exceeded** | 503 | Exception | "Try again later" |
| **Network timeout** | 504 | Exception | "Connection lost" |
| **Rate limited by OpenAI** | 429 | Exception | "Too many requests" |

---

## LOCAL TESTING SETUP

### Start Emulators
```bash
firebase emulators:start --only functions,firestore

# In another terminal:
flutter run
```

### Test Commands (in Flutter debugger)

```dart
// Test 1: Valid message
final response = await LunarAICloudService.respond(
  message: "I'm feeling anxious",
  context: {'name': 'Test User'},
);
print(response.text);

// Test 2: Daily limit (send 21 messages as free user)
for (int i = 0; i < 21; i++) {
  try {
    await LunarAICloudService.respond(message: "Message $i");
  } catch (e) {
    print("Limit reached at message $i: $e");
  }
}

// Test 3: Premium exemption
// Change isPremium to true in user doc
final response = await LunarAICloudService.respond(
  message: "Message 22 - should succeed for premium",
);
print("Success: ${response.text}");
```

---

## MONITORING & DEBUGGING

### Firebase Console

**Cloud Functions → Logs**
- Search by function name: `respond`
- Filter by time range
- Look for errors, timeouts, quota issues

**Firestore → Usage**
- Monitor read/write operations
- Check daily quotas
- Verify index usage

### Application Monitoring

**In Flutter:**
```dart
// Add to chat_provider.dart
Future<void> _send(...) async {
  final stopwatch = Stopwatch()..start();
  
  try {
    final response = await LunarAICloudService.respond(...);
    stopwatch.stop();
    
    analytics.logEvent(
      name: 'ai_response_success',
      parameters: {
        'latencyMs': stopwatch.elapsedMilliseconds,
        'tokens': response.tokensUsed,
        'isPremium': response.isPremium,
      },
    );
  } catch (e) {
    stopwatch.stop();
    analytics.logEvent(
      name: 'ai_response_error',
      parameters: {
        'error': e.toString(),
        'latencyMs': stopwatch.elapsedMilliseconds,
      },
    );
  }
}
```

---

## ROLLBACK PROCEDURES

### If Cloud Function is Down

**Option 1: Emergency Fallback (5 min)**
```dart
// In lunar_ai_service.dart - temporarily restore this:
static Future<LunarAIResponse> respond(String message, ...) async {
  // Try cloud first (1 second timeout)
  try {
    return await LunarAICloudService.respond(message: message, ...);
  } catch (_) {
    // Fallback to local engine
    return _localRespond(message, context ?? {});
  }
}
```

**Option 2: Revert Deployment (15 min)**
```bash
firebase functions:delete respond --region us-central1
# Previous version auto-restores from previous deploy
```

### If Firestore Quota Exceeded

```bash
# Check current usage
gcloud firestore usage describe --database=default

# Request quota increase in Google Cloud Console
# Or: Temporarily disable detailed logging
```

---

## PERFORMANCE OPTIMIZATION TIPS

### Reduce Cloud Function Latency

```typescript
// In lunarRespond.ts - Cache premium status
const premiumCache = new Map<string, { status: boolean; ttl: number }>();

async function isPremiumCached(uid: string): Promise<boolean> {
  const cached = premiumCache.get(uid);
  if (cached && Date.now() < cached.ttl) {
    return cached.status;
  }
  
  const status = await premiumChecker.isUserPremium(uid);
  premiumCache.set(uid, { status, ttl: Date.now() + 3600000 }); // 1h TTL
  return status;
}
```

### Optimize OpenAI Requests

```typescript
// Reduce max_tokens for faster response
'max_tokens': 250,  // Instead of 380
'temperature': 0.7,  // Slightly lower for consistency
```

### Batch Logging

```typescript
// Instead of logging every request immediately:
// Batch updates every 10 seconds
const usageBatch: UsageData[] = [];
setInterval(async () => {
  if (usageBatch.length > 0) {
    // Write batch to Firestore
    usageBatch.length = 0;
  }
}, 10000);
```

---

## SECURITY BEST PRACTICES

### Cloud Function Security Rules
```typescript
// Validate input strictly
if (message.length > 2000) throw new Error('Input too long');

// Never log sensitive data
logger.log('Request received', { uid: uid.substring(0, 8) + '...' });

// Sanitize error messages sent to client
try {
  // ... API call
} catch (error) {
  // Don't expose internal error details
  throw new functions.https.HttpsError('internal', 
    'An error occurred');
}
```

### API Key Security
```bash
# Store API keys in Cloud Secret Manager (not env vars)
gcloud secrets create openai-key --data-file=- <<< "sk-..."
```

### Firestore Rules
```javascript
// Never allow public access to metrics
match /users/{uid}/aiMetrics/{doc} {
  allow read, write: if request.auth.uid == uid;
}
```

---

## FAQ & TROUBLESHOOTING

### Q: Cloud Function not deploying
**A:** Check `npm run build` for TypeScript errors, ensure all imports exist

### Q: "Daily limit reached" but user is premium
**A:** Verify `isPremium` field in user doc is boolean `true`, not string `"true"`

### Q: Latency > 3 seconds
**A:** 
1. Check OpenAI response time in logs
2. Cache premium status lookup
3. Reduce context data passed to function

### Q: No logs in Firestore aiUsage collection
**A:** Verify Firestore rules allow write access, check Cloud Function logs for errors

### Q: Flutter app crashes on old version
**A:** Old app tries to find `_openAIRespond()` which was removed — must upgrade

### Q: Premium check always returns false
**A:** Verify RevenueCat integration in `PremiumChecker`, check API key permissions

---

## COST MONITORING

### Set Budget Alert in Google Cloud
```bash
# In Cloud Console:
# Billing → Budgets & alerts → Create budget
# Set alert at $20/month
```

### Manual Cost Calculation
```
Daily cost = (total_input_tokens × 0.00015) + (total_output_tokens × 0.0006)

Example (100 users, 50 messages/day average):
= (50 × 100 × 145 tokens × 0.00015) + (50 × 100 × 87 × 0.0006)
= $1.09 + $2.61
= $3.70/day ≈ $111/month
```

---

## DEPLOYMENT TIMELINE GANTT

```
Day 1 (4-6 hours)
├─ Cloud Function setup      [||||||||]
├─ TypeScript configuration  [||||]
└─ Handler implementation    [||||||||||||||||]

Day 2 (3-4 hours)
├─ Flutter integration       [||||||||||||]
├─ Remove API key UI         [||||]
└─ Dependency updates        [||]

Day 3 (4-6 hours)
├─ Emulator testing         [||||||||||||||||]
├─ Device E2E testing       [||||||||]
├─ Error scenario testing   [||||||]
└─ Rate limit testing       [||||]

Day 4 (2-3 hours)
├─ User migration            [||||]
├─ Cloud Function deploy    [||]
├─ Flutter app upload       [||||]
└─ Canary release (5%)      [||||||]

Day 5 (Monitoring 24h)
├─ Monitor errors           [████████████████████████]
├─ Check performance        [████████████████████████]
└─ Full rollout             [||||||||]
```

---

## SIGN-OFF CRITERIA

Before marking migration complete:

- [ ] All tests passing (emulator + device)
- [ ] Canary deployment (5% users) shows 0 new crashes
- [ ] Cloud Function latency < 2000ms (p95)
- [ ] Daily limit enforced correctly
- [ ] Premium exemption working
- [ ] Firestore metrics populating
- [ ] Cost within budget
- [ ] No error rate spike in Crashlytics
- [ ] Analytics events firing correctly
- [ ] All team members trained on new architecture
