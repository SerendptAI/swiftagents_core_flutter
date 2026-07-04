class ReopenTicketResponse {
  final String? status;
  final String? ticketId;

  ReopenTicketResponse({this.status, this.ticketId});

  factory ReopenTicketResponse.fromJson(Map<String, dynamic> json) {
    return ReopenTicketResponse(
      status: json['status'],
      ticketId: json['ticket_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'status': status, 'ticket_id': ticketId};
  }
}
