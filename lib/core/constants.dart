class AppConstants {
  // Hive box names
  static const String transactionsBox = 'transactions';
  static const String budgetsBox = 'budgets';
  static const String categoriesBox = 'categories';
  static const String settingsBox = 'settings';
  static const String vaultBox = 'vault';
  static const String pauseModeBox = 'pause_mode';
  static const String geminiCacheBox = 'gemini_cache';
  static const String payeesBox = 'payees';
  static const String bankAccountsBox = 'bank_accounts';

  // ── UPI banks (Bharat / NPCI member banks) ─────────────────────────────────
  // name → @handle used to build the user's VPA (e.g. 9876543210@oksbi).
  static const List<List<String>> upiBanks = [
    ['State Bank of India', 'oksbi', 'SBIN'],
    ['HDFC Bank', 'okhdfcbank', 'HDFC'],
    ['ICICI Bank', 'okicici', 'ICIC'],
    ['Axis Bank', 'okaxis', 'UTIB'],
    ['Kotak Mahindra Bank', 'kotak', 'KKBK'],
    ['Punjab National Bank', 'okpnb', 'PUNB'],
    ['Bank of Baroda', 'okbob', 'BARB'],
    ['Yes Bank', 'okyesbank', 'YESB'],
    ['IDFC FIRST Bank', 'okidfcfirst', 'IDFB'],
    ['Union Bank of India', 'okunion', 'UBIN'],
    ['Canara Bank', 'okcanara', 'CNRB'],
    ['IndusInd Bank', 'okindus', 'INDB'],
  ];

  // ── Razorpay ──────────────────────────────────────────────────────────────
  // Only the PUBLISHABLE Key ID belongs in the client — it's safe to ship.
  // The Key Secret must NEVER live in the app: it goes on a server (Cloud
  // Function) that creates orders, verifies signatures and does any cancels.
  // This is the user's own Razorpay TEST Key ID.
  static const String razorpayTestKey = 'rzp_test_Sc8aDpC3ezp2Xm';
  static const String merchantName = 'GenPay';
  static const String merchantUpiId = 'genpay@upi';

  // ── GenPay backend (keeps Razorpay Secret + NVIDIA NIM key server-side) ─────
  // Android emulator reaches the host machine at 10.0.2.2. Override with
  // BACKEND_URL in .env for a real device / deployed server.
  static const String backendUrlFallback = 'http://10.0.2.2:8787';

  // GenPay Premium price (paise are computed in the service).
  static const double premiumPriceMonthly = 49;

  // Avatar palette for payee circles
  static const List<int> avatarColors = [
    0xFF00D9FF, 0xFF39FF14, 0xFFFF6B6B, 0xFFFFD93D,
    0xFF6C5CE7, 0xFFFD79A8, 0xFF55EFC4, 0xFFA29BFE,
    0xFFFF9FF3, 0xFF74B9FF,
  ];

  // Gemini API
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const int geminiDailyLimit = 1500;

  // Categories
  static const List<String> defaultCategories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Health',
    'Education',
    'Travel',
    'Groceries',
    'Fuel',
    'Subscriptions',
    'Other',
  ];

  static const Map<String, String> categoryIcons = {
    'Food': '🍔',
    'Transport': '🚗',
    'Shopping': '🛍️',
    'Bills': '💡',
    'Entertainment': '🎬',
    'Health': '💊',
    'Education': '📚',
    'Travel': '✈️',
    'Groceries': '🛒',
    'Fuel': '⛽',
    'Subscriptions': '📱',
    'Other': '💸',
  };

  static const Map<String, double> defaultBudgets = {
    'Food': 5000,
    'Transport': 2000,
    'Shopping': 3000,
    'Bills': 2500,
    'Entertainment': 1500,
    'Health': 1000,
    'Education': 2000,
    'Travel': 3000,
    'Groceries': 4000,
    'Fuel': 2000,
    'Subscriptions': 1000,
    'Other': 2000,
  };

  // SMS Regex patterns for UPI parsing
  static final List<RegExp> upiAmountPatterns = [
    RegExp(r'(?:Rs\.?|INR|₹)\s*(\d+(?:[,\d]*)?(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'(\d+(?:[,\d]*)?(?:\.\d{1,2})?)\s*(?:Rs\.?|INR|₹)', caseSensitive: false),
    RegExp(r'debited.*?(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false),
    RegExp(r'paid.*?(\d+(?:,\d+)*(?:\.\d{1,2})?)', caseSensitive: false),
  ];

  static final List<RegExp> merchantPatterns = [
    RegExp(r'(?:to|at)\s+([A-Za-z0-9\s&\-\.]+?)(?:\s+on|\s+via|\s+ref|\.|\n|$)', caseSensitive: false),
    RegExp(r'(?:VPA|UPI)\s+([A-Za-z0-9@\.\-]+)', caseSensitive: false),
    RegExp(r'merchant\s+name[:\s]+([A-Za-z0-9\s]+)', caseSensitive: false),
  ];

  static final List<String> upiSmsKeywords = [
    'debited', 'upi', 'paid', 'payment', 'transfer', 'txn', 'transaction',
    'credited', 'received', 'razorpay', 'gpay', 'phonepe', 'paytm', 'bhim'
  ];

  static final Map<String, List<String>> bankSmsKeywords = {
    'HDFC': ['hdfc', 'hdfcbank'],
    'SBI': ['sbi', 'sbiinb', 'sbiatm'],
    'ICICI': ['icici', 'icicib'],
    'Axis': ['axis', 'axisbank'],
    'Kotak': ['kotak', 'kotakbank'],
    'YES': ['yesbank', 'yes bank'],
    'BOB': ['bob', 'bankofbaroda'],
    'GPay': ['gpay', 'google pay'],
    'PhonePe': ['phonepe', 'phone pe'],
    'Paytm': ['paytm'],
    'BHIM': ['bhim'],
  };

  // Merchant keyword to category mapping
  static const Map<String, String> merchantCategoryMap = {
    'zomato': 'Food',
    'swiggy': 'Food',
    'dominos': 'Food',
    'pizza': 'Food',
    'mcdonald': 'Food',
    'kfc': 'Food',
    'starbucks': 'Food',
    'cafe': 'Food',
    'restaurant': 'Food',
    'ola': 'Transport',
    'uber': 'Transport',
    'rapido': 'Transport',
    'metro': 'Transport',
    'irctc': 'Travel',
    'makemytrip': 'Travel',
    'goibibo': 'Travel',
    'amazon': 'Shopping',
    'flipkart': 'Shopping',
    'myntra': 'Shopping',
    'ajio': 'Shopping',
    'meesho': 'Shopping',
    'netflix': 'Subscriptions',
    'spotify': 'Subscriptions',
    'hotstar': 'Subscriptions',
    'prime': 'Subscriptions',
    'youtube': 'Subscriptions',
    'electricity': 'Bills',
    'bsnl': 'Bills',
    'airtel': 'Bills',
    'jio': 'Bills',
    'vodafone': 'Bills',
    'reliance': 'Groceries',
    'bigbasket': 'Groceries',
    'blinkit': 'Groceries',
    'zepto': 'Groceries',
    'dunzo': 'Groceries',
    'medplus': 'Health',
    'apollo': 'Health',
    'pharmeasy': 'Health',
    'netmeds': 'Health',
    'udemy': 'Education',
    'coursera': 'Education',
    'byju': 'Education',
    'petrol': 'Fuel',
    'diesel': 'Fuel',
    'hp petrol': 'Fuel',
    'indian oil': 'Fuel',
  };

  // Personality strings
  static const List<String> emptyStateMessages = [
    "No expenses yet 🎉 Either you're broke or a saint",
    "Clean slate! Enjoy it while it lasts.",
    "Nothing here. You're either very disciplined or your UPI is broken.",
  ];

  static const List<String> smsParsingMessages = [
    "Parsing your financial chaos... 🔍",
    "Reading your spending confessions...",
    "Snooping through your SMS (ethically)...",
  ];

  static const List<String> overBudget80Messages = [
    "Getting close 👀 ₹{remaining} left. Maybe cook today?",
    "Hmm. 80% gone already. The takeout is judging you.",
    "Budget alert! ₹{remaining} left. You've got this (barely).",
  ];

  static const List<String> overBudget90Messages = [
    "Bruh. 90% gone. The next biryani is your last biryani this month.",
    "90%?! Are you stress-spending again?",
    "Almost there! ₹{remaining} left. No, that's not a challenge.",
  ];

  static const List<String> overBudget100Messages = [
    "That's it. That's the budget. 🥲",
    "Budget: defeated. You: technically alive.",
    "Congratulations! You've unlocked: Ramen Mode 🍜",
  ];

  static const Map<int, String> streakMessages = {
    3: "3 days strong! You're actually doing it.",
    7: "7 day streak! Your future self is clapping 👏",
    14: "Two weeks of discipline. Suspicious, but we respect it.",
    30: "A WHOLE MONTH?! You're built different 💎",
  };

  static const String pauseActivation = "Entered chill mode 🧊 Your wallet is on airplane mode";
  static const String pauseOverrideWarning = "Really? Is this ACTUALLY urgent or just a vibe?";
  static const String noInsights = "Add some transactions first. We need data to roast you.";
  static const String emptyVault = "Your vault is empty. Every ₹48 coffee is hiding ₹2 from you.";

  static const List<String> foundSmsMessages = [
    "Found {count} UPI transactions. Approve the ones that aren't your friend paying you back",
    "Discovered {count} spending crimes. Time to face the music.",
  ];

  // Payment methods
  static const List<String> paymentMethods = ['UPI', 'Card', 'Cash', 'NetBanking', 'Wallet'];

  // UPI apps
  static const List<String> upiApps = [
    'GPay', 'PhonePe', 'Paytm', 'BHIM', 'Amazon Pay',
    'CRED', 'WhatsApp Pay', 'iMobile', 'HDFC', 'SBI YONO',
    'Axis Pay', 'Other UPI',
  ];

  static const Map<String, String> upiAppEmojis = {
    'GPay': '🟢',
    'PhonePe': '🟣',
    'Paytm': '🔵',
    'BHIM': '🇮🇳',
    'Amazon Pay': '🟠',
    'CRED': '⚫',
    'WhatsApp Pay': '💬',
    'iMobile': '🏦',
    'HDFC': '🔴',
    'SBI YONO': '🏛️',
    'Axis Pay': '🟤',
    'Other UPI': '💳',
  };

  // Keywords to detect UPI app from SMS body
  static const Map<String, List<String>> upiAppKeywords = {
    'GPay': ['gpay', 'google pay', 'googlepay', '@okicici', '@oksbi', '@okaxis', '@okhdfcbank'],
    'PhonePe': ['phonepe', 'phone pe', '@ybl', '@ibl', '@axl'],
    'Paytm': ['paytm', '@paytm'],
    'BHIM': ['bhim', '@upi', '@sbi'],
    'Amazon Pay': ['amazon pay', 'amazonpay', '@apl'],
    'CRED': ['cred', '@cred'],
    'WhatsApp Pay': ['whatsapp pay', 'whatsapp', '@wa'],
    'iMobile': ['imobile', '@icici'],
    'HDFC': ['hdfc', '@hdfcbank'],
    'SBI YONO': ['yono', '@sbi'],
  };

  // Moods
  static const List<String> moods = ['😊', '😐', '😔', '😤', '🥳', '😰', '🤑', '😴'];
  static const Map<String, String> moodLabels = {
    '😊': 'Happy',
    '😐': 'Meh',
    '😔': 'Sad',
    '😤': 'Stressed',
    '🥳': 'Celebrating',
    '😰': 'Anxious',
    '🤑': 'Splurging',
    '😴': 'Lazy',
  };
}
