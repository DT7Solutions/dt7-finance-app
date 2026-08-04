class AccountModel {
  final int id;
  final String name;
  final String accountType; // CHECKING, SAVINGS, CREDIT, INVESTMENT, CASH
  final double balance;
  final String currency;
  final String? accountNumber;
  final bool isActive;

  AccountModel({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balance,
    this.currency = 'USD',
    this.accountNumber,
    this.isActive = true,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) {
    return AccountModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      accountType: json['account_type'] ?? 'CHECKING',
      balance: double.tryParse(json['balance'].toString()) ?? 0.0,
      currency: json['currency'] ?? 'USD',
      accountNumber: json['account_number'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'account_type': accountType,
      'balance': balance,
      'currency': currency,
      'account_number': accountNumber,
      'is_active': isActive,
    };
  }

  String get typeLabel {
    switch (accountType) {
      case 'CHECKING': return 'Checking Account';
      case 'SAVINGS': return 'Savings Account';
      case 'CREDIT': return 'Credit Card';
      case 'INVESTMENT': return 'Investment Account';
      case 'CASH': return 'Cash Wallet';
      default: return accountType;
    }
  }
}
