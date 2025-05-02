import 'package:http/http.dart' as http;
import 'package:jiffy/jiffy.dart';

class ApiService {
  static final String apiBaseUrl =
      'https://0830s3gvuh.execute-api.us-east-2.amazonaws.com/dev/';

  static dynamic verifyUserWithEmpCode(String empCode) async {
    try {
      var response = await http.get(Uri.parse(apiBaseUrl +
          'users/verifyByTheCode?Code=$empCode' +
          '&isEnabled=True'));

      return response;
    } catch (e) {
      print(e);
    }

    return [];
  }

  static dynamic verifyUserOTPCode(String empCode, String otp) async {
    try {
      var response = await http.get(
        Uri.parse(apiBaseUrl +
            'users/verifyByTheCode?Code=' +
            empCode +
            '&isEnabled=True' +
            '&OTP=' +
            otp),
      );

      return response;
    } catch (e) {
      print(e);
    }

    return [];
  }

  static String getMultiFRBaseURL() {
    return 'http://icheck-face-recognition-stelacom.us-east-2.elasticbeanstalk.com';
  }

  static dynamic getTodayCheckInCheckOut(
      String userId, String customerId) async {
    var url = apiBaseUrl +
        'users/todayCheckInCheckOut?customerId=' +
        customerId +
        "&userId=" +
        userId +
        "&date=" +
        Jiffy.parseFromDateTime((new DateTime.now()))
            .format(pattern: "yyyy-MM-dd");
    var response = await http.get(Uri.parse(url));
    return response;
  }
}
