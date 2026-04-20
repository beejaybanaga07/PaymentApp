import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';

class StripeServices {

  static const Map<String, String> testTokens = {
    '1232313321223313' : 'tok_visa',
    '5456564665455664' : 'tok_debit',
    '6787868876788876' : 'tok_mastercard',
    '8098098089080980' : 'tok_mastercard_debit',
    '3453543535343453' : 'tok_chargeDeclined',
    '5657567567575657' : 'tok_chargeDeclinedInsufficientFunds',
  };

  static Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
}) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll('', '');
    final token = testTokens[cleanCard];

    if (token == null ) {
      return<String, dynamic> {
        'success': false,
        'error' : 'unknown test card 1232313321223313 or 5456564665455664 ',
      };
    }

    try {
      final response = await http.post(
        Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
        headers: <String, String> {
          'Authorization' : 'Bearer ${StripeConfig.secretkey}',
          'Content-Type' : 'application/x-www-form-urlencoded',
        },
        body:  <String, String>{
          'amount' : amountInCentavos,
          'currency' : 'php',
          'payment_method_types[]': 'card',
          'payment_method_data[type]' : 'card',
          'payment_method_data[card][token]' : token,
          'confirm' : 'true',
        },
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data ['status']== 'succeeded') {
        return <String, dynamic> {
          'success' : true,
          'id' : data['id'].toString(),
          'amount' : (data['amount'] as num) / 100,
          'status' : data['status'].toString(),

        };
      } else {
        final errorMsg = data['error'] is Map
        ? (data['error']as Map)['message']?.toString() ?? 'Payment failed'
        : 'Payment failed';

        return <String, dynamic>{'success': false,'error': errorMsg};
        }
      } catch (e) {
        return <String, dynamic>{'success': false, 'error': e.toString()};
    }
  }
}
