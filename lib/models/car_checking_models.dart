class Transaction {
  final String bookingCode;
  final String displayText;
  final String clientName;
  final String phoneNumber;
  final String vehicle;

  Transaction({
    required this.bookingCode,
    required this.displayText,
    required this.clientName,
    required this.phoneNumber,
    required this.vehicle,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      bookingCode: json['booking_code'] ?? '',
      displayText: json['display_text'] ?? '',
      clientName: json['client_name'] ?? '',
      phoneNumber: json['phone_number'] ?? '',
      vehicle: json['vehicle'] ?? '',
    );
  }
}

class CheckType {
  final String id;
  final String name;

  CheckType({
    required this.id,
    required this.name,
  });

  factory CheckType.fromJson(Map<String, dynamic> json) {
    return CheckType(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }
}
