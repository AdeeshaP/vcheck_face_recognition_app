import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcheck_face_recognition_app/api-access/api_service.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_error_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/other_dialogs.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/home/home_page.dart';

// OTP Input Screen
class OTPInputSreen extends StatefulWidget {
  OTPInputSreen({Key? key}) : super(key: key);

  @override
  State<OTPInputSreen> createState() => _OTPInputSreenState();
}

class _OTPInputSreenState extends State<OTPInputSreen> {
  List<TextEditingController> otpControllers = List.generate(
    4,
    (index) => TextEditingController(),
  );
  List<FocusNode> focusNodes = List.generate(
    4,
    (index) => FocusNode(),
  );
  late SharedPreferences _storage;
  String empCode = "";
  bool? _autoCaptureFace;

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  void dispose() {
    for (var controller in otpControllers) {
      controller.dispose();
    }
    for (var node in focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
    empCode = _storage.getString('employee_code') ?? "";
  }

  void resendCode() async {
    _storage = await SharedPreferences.getInstance();
    String empCode2 = _storage.getString('employee_code') ?? "";

    var response2 = await ApiService.verifyUserWithEmpCode(empCode2);
    print(response2);

    bool? autoCaptureFacePref = _storage.getBool('AutoCaptureFace');

    setState(() {
      _autoCaptureFace = autoCaptureFacePref;
    });
  }

  void validateOTP(String otp) async {
    print("emp code is $empCode");
    print("otpCode is $otp");

    showProgressDialog(context);
    _storage = await SharedPreferences.getInstance();

    var response = await ApiService.verifyUserOTPCode(empCode, otp);
    closeDialog(context);

    if (response.body == "null" || response.body == null) {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Error',
          message: 'Invalid OTP.',
          onOkPressed: () {
            Navigator.of(context).pop();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => CodeVerificationScreen(storage: _storage),
              ),
            );
          },
          iconData: Icons.error_outline,
        ),
      );
    } else {
      print("OTP Response body ${response.body}");

      _storage.setString('user_data', response.body);
      _storage.setString('employee_code', empCode);

   
      Map<String, dynamic> userObj = jsonDecode(response.body);
      if (userObj["enrolled"] == 'done' && _autoCaptureFace == true) {
      } else if (userObj["enrolled"] == 'done') {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) {
            return HomePage();
          }),
        );
      } else {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: appBgColor,
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              // Welcome Text
              Text(
                'Welcome to vCheck\nAttendance Management System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 20
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 22
                          : Responsive.isTabletPortrait(context)
                              ? 25
                              : 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 60),
              // OTP Icon with checkmark
              Container(
                height: 150,
                child: Center(
                  child: Image.asset(
                    'assets/images/iCheck_logo_2024.png',
                    fit: BoxFit.fill,
                    scale: 2,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 20
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 22
                          : Responsive.isTabletPortrait(context)
                              ? 25
                              : 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Enter the OTP sent to your phone number',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Responsive.isMobileSmall(context)
                      ? 14
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 16
                          : Responsive.isTabletPortrait(context)
                              ? 18
                              : 20,
                ),
              ),
              SizedBox(height: 40),
              // OTP Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  4,
                  (index) => SizedBox(
                    width: 40,
                    child: TextField(
                      style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 17
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 19
                                : Responsive.isTabletPortrait(context)
                                    ? 21
                                    : 20,
                      ),
                      controller: otpControllers[index],
                      focusNode: focusNodes[index],
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        counterText: "",
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey.shade600),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.orange),
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty && index < 3) {
                          focusNodes[index + 1].requestFocus();
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Resend OTP text
              TextButton(
                onPressed: () {
                  resendCode();
                },
                child: Text(
                  'Resend OTP',
                  style: TextStyle(
                    color: iconColors,
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 12
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 14
                            : Responsive.isTabletPortrait(context)
                                ? 18
                                : 18,
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Verify Button
              Container(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    String otp = otpControllers
                        .map((controller) => controller.text)
                        .join();
                    // Add verification logic here
                    print('Entered OTP: $otp');
                    validateOTP(otp);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionBtnColor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Verify',
                    style: TextStyle(
                        fontSize: Responsive.isMobileSmall(context)
                            ? 16
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 18
                                : Responsive.isTabletPortrait(context)
                                    ? 20
                                    : 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
