class AutomationSettings {
  final bool duplicateCancelEnabled;
  final bool upgradeAdvisoryEnabled;
  final bool spendingFreezeEnabled;
  final bool refundFinderEnabled;
  final bool offlineAiEnabled;

  const AutomationSettings({
    this.duplicateCancelEnabled = false,
    this.upgradeAdvisoryEnabled = true,
    this.spendingFreezeEnabled = false,
    this.refundFinderEnabled = true,
    this.offlineAiEnabled = false,
  });

  AutomationSettings copyWith({
    bool? duplicateCancelEnabled,
    bool? upgradeAdvisoryEnabled,
    bool? spendingFreezeEnabled,
    bool? refundFinderEnabled,
    bool? offlineAiEnabled,
  }) {
    return AutomationSettings(
      duplicateCancelEnabled: duplicateCancelEnabled ?? this.duplicateCancelEnabled,
      upgradeAdvisoryEnabled: upgradeAdvisoryEnabled ?? this.upgradeAdvisoryEnabled,
      spendingFreezeEnabled: spendingFreezeEnabled ?? this.spendingFreezeEnabled,
      refundFinderEnabled: refundFinderEnabled ?? this.refundFinderEnabled,
      offlineAiEnabled: offlineAiEnabled ?? this.offlineAiEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'duplicateCancelEnabled': duplicateCancelEnabled,
      'upgradeAdvisoryEnabled': upgradeAdvisoryEnabled,
      'spendingFreezeEnabled': spendingFreezeEnabled,
      'refundFinderEnabled': refundFinderEnabled,
      'offlineAiEnabled': offlineAiEnabled,
    };
  }

  factory AutomationSettings.fromJson(Map<String, dynamic> json) {
    return AutomationSettings(
      duplicateCancelEnabled: json['duplicateCancelEnabled'] ?? false,
      upgradeAdvisoryEnabled: json['upgradeAdvisoryEnabled'] ?? true,
      spendingFreezeEnabled: json['spendingFreezeEnabled'] ?? false,
      refundFinderEnabled: json['refundFinderEnabled'] ?? true,
      offlineAiEnabled: json['offlineAiEnabled'] ?? false,
    );
  }
}
