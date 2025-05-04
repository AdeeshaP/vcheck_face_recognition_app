import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/face_enrollment_capture.dart';
class EnrollUser extends StatefulWidget {
  final dynamic userObj;
  EnrollUser({Key? key, required this.userObj}) : super(key: key);

  @override
  State<EnrollUser> createState() => _EnrollUserState();
}

class _EnrollUserState extends State<EnrollUser> {
  late SharedPreferences _storage;

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => CodeVerificationScreen(storage: _storage),
          ),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: iconColors,
                size: Responsive.isMobileSmall(context)
                    ? 20
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 24
                        : Responsive.isTabletPortrait(context)
                            ? 31
                            : 35,
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CodeVerificationScreen(storage: _storage),
                  ),
                  (route) => false,
                );
              }),
          title: Text(
            'Employee Registration',
            style: TextStyle(
              color: screenHeadingColor,
              fontSize: Responsive.isMobileSmall(context)
                  ? 22
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 24
                      : Responsive.isTabletPortrait(context)
                          ? 27
                          : 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello ${widget.userObj["FirstName"]},',
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 17
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 20
                            : Responsive.isTabletPortrait(context)
                                ? 25
                                : 25,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please verify your information before proceeding to the enrollment.',
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 15
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 16
                            : Responsive.isTabletPortrait(context)
                                ? 18
                                : 20,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.justify,
                ),
                SizedBox(height: 20),
                _buildInfoField('Code', '${widget.userObj["Code"]}'),
                _buildInfoField('Name',
                    '${widget.userObj["FirstName"]} ${widget.userObj["LastName"]}'),
                _buildInfoField('Office Address',
                    '${widget.userObj["OfficeAddress"]?.replaceAll(RegExp(r'\n{2,}'), '') ?? ''}'),
                _buildInfoField('Email', '${widget.userObj["Email"]}'),
                _buildInfoField(
                    'Contact No', '${widget.userObj["MobilePhone"]}'),
                SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return EnrollmentCaptureScreen();
                        }),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: actionBtnColor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Face Enrollment',
                          style: TextStyle(
                            fontSize: Responsive.isMobileSmall(context)
                                ? 15
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 18
                                    : Responsive.isTabletPortrait(context)
                                        ? 22
                                        : 25,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: Responsive.isMobileSmall(context)
                              ? 18
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 22
                                  : Responsive.isTabletPortrait(context)
                                      ? 25
                                      : 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 12
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 14
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 22,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: Responsive.isMobileSmall(context)
                    ? 15
                    : Responsive.isMobileMedium(context) ||
                            Responsive.isMobileLarge(context)
                        ? 16
                        : Responsive.isTabletPortrait(context)
                            ? 20
                            : 25,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
