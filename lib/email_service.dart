import 'dart:convert';
import 'package:http/http.dart' as http;

/// Sends ticket information by email using a Cloud Function.
/// Returns `true` if the request was successful (status code 200),
/// otherwise returns `false`.
Future<bool> sendTicketEmail(String email, Map<String, dynamic> ticketData) async {
  final url = Uri.parse('https://us-central1-optima-360-b055b.cloudfunctions.net/sendTicketEmail');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': email,
      'ticketData': ticketData,
    }),
  );

  // Print body for debugging purposes
  print('sendTicketEmail response: ${response.body}');

  return response.statusCode == 200;
}
