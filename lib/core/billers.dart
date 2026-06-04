// Bharat Connect (BBPS) biller catalog.
//
// Mirrors the real NPCI Bharat Bill Payment System taxonomy: biller
// categories → registered billers → the consumer-reference label each biller
// asks for. The bill fetch is simulated locally (a live BBPS fetch needs a
// registered backend agent), but the actual settlement runs through the app's
// Razorpay UPI checkout.

class Biller {
  final String id;
  final String name;
  final String spendCategory; // maps to app expense categories

  const Biller(this.id, this.name, {this.spendCategory = 'Bills'});
}

class BillerCategory {
  final String key;
  final String label;
  final String icon;
  final String consumerLabel; // e.g. "Consumer Number", "Policy Number"
  final String consumerHint;
  final bool numericRef;
  final List<Biller> billers;

  const BillerCategory({
    required this.key,
    required this.label,
    required this.icon,
    required this.consumerLabel,
    required this.consumerHint,
    required this.billers,
    this.numericRef = true,
  });
}

class Billers {
  static const List<BillerCategory> categories = [
    BillerCategory(
      key: 'mobile',
      label: 'Mobile Recharge',
      icon: '📱',
      consumerLabel: 'Mobile Number',
      consumerHint: '10-digit mobile number',
      billers: [
        Biller('airtel_prepaid', 'Airtel Prepaid'),
        Biller('jio_prepaid', 'Jio Prepaid'),
        Biller('vi_prepaid', 'Vi (Vodafone Idea)'),
        Biller('bsnl_prepaid', 'BSNL Prepaid'),
      ],
    ),
    BillerCategory(
      key: 'electricity',
      label: 'Electricity',
      icon: '💡',
      consumerLabel: 'Consumer Number',
      consumerHint: 'As printed on your bill',
      billers: [
        Biller('msedcl', 'MSEDCL (Maharashtra)'),
        Biller('adani_mumbai', 'Adani Electricity Mumbai'),
        Biller('tatapower', 'Tata Power'),
        Biller('bescom', 'BESCOM (Bengaluru)'),
        Biller('bses_rajdhani', 'BSES Rajdhani (Delhi)'),
        Biller('tneb', 'TNEB (Tamil Nadu)'),
        Biller('uppcl', 'UPPCL (Uttar Pradesh)'),
      ],
    ),
    BillerCategory(
      key: 'dth',
      label: 'DTH',
      icon: '📺',
      consumerLabel: 'Subscriber ID / VC No.',
      consumerHint: 'Subscriber/VC number',
      billers: [
        Biller('tataplay', 'Tata Play'),
        Biller('airtel_dth', 'Airtel Digital TV'),
        Biller('dishtv', 'Dish TV'),
        Biller('d2h', 'd2h'),
        Biller('sundirect', 'Sun Direct'),
      ],
    ),
    BillerCategory(
      key: 'broadband',
      label: 'Broadband',
      icon: '🌐',
      consumerLabel: 'Account / User ID',
      consumerHint: 'Your account ID',
      numericRef: false,
      billers: [
        Biller('jiofiber', 'JioFiber'),
        Biller('airtel_xstream', 'Airtel Xstream'),
        Biller('act', 'ACT Fibernet'),
        Biller('bsnl_bb', 'BSNL Broadband'),
        Biller('excitel', 'Excitel'),
      ],
    ),
    BillerCategory(
      key: 'water',
      label: 'Water',
      icon: '💧',
      consumerLabel: 'Consumer ID',
      consumerHint: 'Water connection ID',
      billers: [
        Biller('djb', 'Delhi Jal Board'),
        Biller('bwssb', 'BWSSB (Bengaluru)'),
        Biller('mcgm_water', 'MCGM Water (Mumbai)'),
      ],
    ),
    BillerCategory(
      key: 'gas',
      label: 'Piped Gas',
      icon: '🔥',
      consumerLabel: 'Consumer / CRN',
      consumerHint: 'Customer reference number',
      billers: [
        Biller('mahanagar_gas', 'Mahanagar Gas'),
        Biller('igl', 'Indraprastha Gas (IGL)'),
        Biller('gujarat_gas', 'Gujarat Gas'),
        Biller('adani_gas', 'Adani Total Gas'),
      ],
    ),
    BillerCategory(
      key: 'lpg',
      label: 'LPG Cylinder',
      icon: '🛢️',
      consumerLabel: 'LPG ID / Consumer No.',
      consumerHint: 'Your LPG consumer ID',
      billers: [
        Biller('indane', 'Indane Gas'),
        Biller('hpgas', 'HP Gas'),
        Biller('bharatgas', 'Bharat Gas'),
      ],
    ),
    BillerCategory(
      key: 'creditcard',
      label: 'Credit Card',
      icon: '💳',
      consumerLabel: 'Card Number',
      consumerHint: 'Your credit card number',
      billers: [
        Biller('hdfc_cc', 'HDFC Bank Credit Card'),
        Biller('icici_cc', 'ICICI Bank Credit Card'),
        Biller('sbi_cc', 'SBI Card'),
        Biller('axis_cc', 'Axis Bank Credit Card'),
        Biller('kotak_cc', 'Kotak Credit Card'),
      ],
    ),
    BillerCategory(
      key: 'insurance',
      label: 'Insurance',
      icon: '🛡️',
      consumerLabel: 'Policy Number',
      consumerHint: 'Your policy number',
      billers: [
        Biller('lic', 'LIC of India'),
        Biller('hdfc_life', 'HDFC Life'),
        Biller('icici_pru', 'ICICI Prudential'),
        Biller('sbi_life', 'SBI Life'),
        Biller('max_life', 'Max Life Insurance'),
      ],
    ),
    BillerCategory(
      key: 'fastag',
      label: 'FASTag',
      icon: '🚗',
      consumerLabel: 'Vehicle Number',
      consumerHint: 'e.g. MH01AB1234',
      numericRef: false,
      billers: [
        Biller('paytm_fastag', 'Paytm FASTag', spendCategory: 'Transport'),
        Biller('icici_fastag', 'ICICI FASTag', spendCategory: 'Transport'),
        Biller('hdfc_fastag', 'HDFC FASTag', spendCategory: 'Transport'),
        Biller('airtel_fastag', 'Airtel FASTag', spendCategory: 'Transport'),
      ],
    ),
    BillerCategory(
      key: 'loan',
      label: 'Loan EMI',
      icon: '🏦',
      consumerLabel: 'Loan Account No.',
      consumerHint: 'Your loan account number',
      billers: [
        Biller('hdfc_loan', 'HDFC Bank Loan'),
        Biller('bajaj', 'Bajaj Finserv'),
        Biller('tata_capital', 'Tata Capital'),
        Biller('idfc_loan', 'IDFC First Loan'),
      ],
    ),
    BillerCategory(
      key: 'education',
      label: 'Education Fee',
      icon: '🎓',
      consumerLabel: 'Student / Reg. ID',
      consumerHint: 'Registration number',
      numericRef: false,
      billers: [
        Biller('school_fee', 'School Fee', spendCategory: 'Education'),
        Biller('college_fee', 'College / University Fee',
            spendCategory: 'Education'),
      ],
    ),
  ];

  static BillerCategory? byKey(String key) {
    for (final c in categories) {
      if (c.key == key) return c;
    }
    return null;
  }
}
