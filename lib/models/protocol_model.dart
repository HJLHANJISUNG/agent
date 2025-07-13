class Protocol {
  final String protocolId;
  final String name;
  final String? rfcNumber;

  Protocol({required this.protocolId, required this.name, this.rfcNumber});

  factory Protocol.fromMap(Map<String, dynamic> map) {
    return Protocol(
      protocolId: map['protocol_id'],
      name: map['name'],
      rfcNumber: map['rfc_number'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'protocol_id': protocolId, 'name': name, 'rfc_number': rfcNumber};
  }
}
