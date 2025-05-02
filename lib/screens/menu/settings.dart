import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_error_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_success_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/utils.dart';
import 'package:vcheck_face_recognition_app/screens/checkin/normal_checkin.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/home/home_page.dart';
import 'package:vcheck_face_recognition_app/screens/menu/help.dart';
import 'package:vcheck_face_recognition_app/screens/menu/terms_condition.dart';
import 'about_us.dart';
import 'contact_us.dart';

class Settings extends StatefulWidget {
  @override
  _SettingsState createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  double captureWaitTime = 5;
  double sliderWaitTime = 3;
  double errorMessageWaitTime = 6;
  double checkInCheckOutGap = 0;
  late SharedPreferences _storage;
  bool _autoCaptureFace = false;
  bool _onChangedAutoCaptureFeature = false;
  dynamic userObj = <String, String>{};
  String? userData;
  double newCaptureWitTime = 0;
  double newSliderWaitTime = 0;
  double newErrorMessageWaitTime = 0;
  double newCheckInCheckOutGap = 0;

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  void getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();

    userData = _storage.getString('user_data');

    double? captureWaitPref = _storage.getDouble('CaptureWait');
    double? sliderWaitPref = _storage.getDouble('SliderWait');
    double? checkInCheckOutGapPref = _storage.getDouble('CheckInCheckOutGap');
    double? errorWaitPref = _storage.getDouble('ErrorWait');
    bool? autoCaptureFacePref = _storage.getBool('AutoCaptureFace');

    print("captureWaitPref $captureWaitPref");
    print("sliderWaitPref $sliderWaitPref");
    print("checkInCheckOutGapPref $checkInCheckOutGapPref");
    print("errorWaitPref $errorWaitPref");
    // bool? onPressedSavePref = _storage.getBool('OnPressedSave');

    setState(() {
      captureWaitTime = captureWaitPref ?? 5;
      sliderWaitTime = sliderWaitPref ?? 3;
      checkInCheckOutGap = checkInCheckOutGapPref ?? 0;
      errorMessageWaitTime = errorWaitPref ?? 6;
      _autoCaptureFace = autoCaptureFacePref ?? false;

      newCaptureWitTime = captureWaitTime;
      newSliderWaitTime = sliderWaitTime;
      newErrorMessageWaitTime = errorMessageWaitTime;
      newCheckInCheckOutGap = checkInCheckOutGap;
    });
  }

  void saveSharedPrefs() {
    _storage.setDouble(
        'CaptureWait', double.parse(newCaptureWitTime.toString()));
    _storage.setDouble(
        'SliderWait', double.parse(newSliderWaitTime.toString()));
    _storage.setDouble(
        'ErrorWait', double.parse(newErrorMessageWaitTime.toString()));
    _storage.setDouble(
        'CheckInCheckOutGap', double.parse(newCheckInCheckOutGap.toString()));
    _storage.setBool('AutoCaptureFace', _autoCaptureFace);
  }

  //   setState(() {
  //     captureWaitController.text = captureWait.toString();
  //     resultSliderWaitController.text = sliderWait.toString();
  //     errorWaitController.text = errorWait.toString();
  //     checkInCheckOutGapController.text = checkInCheckOutGap.toString();
  //     _autoCaptureFace = autoCaptureFace;
  //   });
  // }

  @override
  void dispose() {
    super.dispose();
  }

  void okButton() {
    // closeDialog(context);
    Navigator.of(context, rootNavigator: true).pop('dialog');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return HomePage();
      }),
    );
  }

  void okRecognition() {
    closeDialog(context);
  }

  final List<String> _menuOptions = [
    'Help',
    'About Us',
    'Contact Us',
    'T & C',
    'Settings',
    'Logout'
  ];

  void choiceAction(String choice) {
    if (choice == _menuOptions[0]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return Help();
        }),
      );
    } else if (choice == _menuOptions[1]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return AboutUs();
        }),
      );
    } else if (choice == _menuOptions[2]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return ContactUs();
        }),
      );
    } else if (choice == _menuOptions[3]) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return TermsAndConditions();
        }),
      );
    } else if (choice == _menuOptions[4]) {
    } else if (choice == _menuOptions[5]) {
      // _storage.clear();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => CodeVerificationScreen(storage: _storage),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, dynamic) {
        if (didPop) {
          return;
        }
        _autoCaptureFace == true && userData != null
            ? Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => NormalCheckin(),
                ),
                (route) => true,
              )
            : Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(),
                ),
                (route) => true,
              );
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF5F6FA),
        appBar: AppBar(
          backgroundColor: appbarBgColor,
          toolbarHeight: Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context) ||
                  Responsive.isMobileLarge(context)
              ? 40
              : Responsive.isTabletPortrait(context)
                  ? 80
                  : 90,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // --------- App Logo ---------- //
              SizedBox(
                width: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 90.0
                    : Responsive.isTabletPortrait(context)
                        ? 150
                        : 170,
                height: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 40.0
                    : Responsive.isTabletPortrait(context)
                        ? 120
                        : 100,
                child: Image.asset(
                  'assets/images/iCheck_logo_2024.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: size.width * 0.25),
            ],
          ),
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: choiceAction,
              itemBuilder: (BuildContext context) {
                return _menuOptions.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(
                      choice,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 15
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 17
                                : Responsive.isTabletPortrait(context)
                                    ? size.width * 0.025
                                    : size.width * 0.018,
                      ),
                    ),
                  );
                }).toList();
              },
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: screenHeadingColor,
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
                      Navigator.of(context).pop();
                    },
                  ),
                  Expanded(
                    flex: 6,
                    child: Text(
                      "Settings",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: screenHeadingColor,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 22
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 26
                                : Responsive.isTabletPortrait(context)
                                    ? 28
                                    : 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(""),
                  )
                ],
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildSwitchTile(
                              'Auto Capture Face', _autoCaptureFace, (value) {
                            setState(() {
                              _autoCaptureFace = value;
                              _onChangedAutoCaptureFeature = true;
                            });
                          }),
                          AnimatedOpacity(
                            opacity: _autoCaptureFace ? 1.0 : 0.5,
                            duration: Duration(milliseconds: 300),
                            child: Column(
                              children: [
                                _buildSliderTile(
                                  'Capture Wait Time',
                                  'Seconds',
                                  captureWaitTime,
                                  (value) {
                                    if (_autoCaptureFace) {
                                      setState(() {
                                        captureWaitTime = value;
                                        newCaptureWitTime = value;
                                        _onChangedAutoCaptureFeature = true;
                                      });
                                    }
                                  },
                                  enabled: _autoCaptureFace,
                                ),
                                _buildSliderTile(
                                  'Result Slider Wait Time',
                                  'Seconds',
                                  sliderWaitTime,
                                  (value) {
                                    if (_autoCaptureFace) {
                                      setState(() {
                                        sliderWaitTime = value;
                                        newSliderWaitTime = value;
                                        _onChangedAutoCaptureFeature = true;
                                      });
                                    }
                                  },
                                  enabled: _autoCaptureFace,
                                ),
                                _buildSliderTile(
                                  'Error Message Wait Time',
                                  'Seconds',
                                  errorMessageWaitTime,
                                  (value) {
                                    if (_autoCaptureFace) {
                                      setState(() {
                                        errorMessageWaitTime = value;
                                        newErrorMessageWaitTime = value;
                                        _onChangedAutoCaptureFeature = true;
                                      });
                                    }
                                  },
                                  enabled: _autoCaptureFace,
                                ),
                                _buildSliderTile(
                                  'Check-in Check-out Gap',
                                  'Minutes',
                                  checkInCheckOutGap,
                                  (value) {
                                    if (_autoCaptureFace) {
                                      setState(() {
                                        checkInCheckOutGap = value;
                                        newCheckInCheckOutGap = value;
                                        _onChangedAutoCaptureFeature = true;
                                      });
                                    }
                                  },
                                  enabled: _autoCaptureFace,
                                  max: 60,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onChangedAutoCaptureFeature == false
                          ? () {}
                          : () {
                              // setState(() {
                              //   _onPressedSave = true;
                              // });
                              if (userData == null) {
                                showDialog(
                                  context: context,
                                  builder: (context) => CustomErrorDialog(
                                    title: 'Error occured!',
                                    message:
                                        "Any user has not enrolled yet. Please enroll first and then change the settings.",
                                    onOkPressed: moveToHome,
                                    iconData: Icons.warning,
                                  ),
                                );
                              } else {
                                saveSharedPrefs();
                                if (_autoCaptureFace == true) {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomSuccessDialog(
                                      message:
                                          "Auto capturing has been enabled. Settings updated successfully.",
                                      onOkPressed: moveToCheckin,
                                    ),
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (context) => CustomSuccessDialog(
                                      message: "Settings updated successfully.",
                                      onOkPressed: okButton,
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _onChangedAutoCaptureFeature
                            ? actionBtnColor
                            : Colors.grey.shade400,
                        foregroundColor: actionBtnTextColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 0,
                        padding: EdgeInsets.all(15),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void moveToHome() {
    closeDialog(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return HomePage();
      }),
    );
  }

  void moveToCheckin() {
    closeDialog(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return NormalCheckin();
      }),
    );
  }

  Widget _buildSwitchTile(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2D3142),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String unit,
    double value,
    Function(double) onChanged, {
    double max = 10,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: enabled
                      ? Color(0xFF2D3142)
                      : Color(0xFF2D3142).withOpacity(0.5),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: enabled
                      ? Colors.orange.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${value.toDouble()} $unit',
                  style: TextStyle(
                      color: enabled
                          ? Colors.black.withOpacity(0.9)
                          : Colors.black.withOpacity(0.3),
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor:
                  enabled ? Colors.orange : Colors.orange.withOpacity(0.3),
              inactiveTrackColor: enabled
                  ? Colors.orange.withOpacity(0.2)
                  : Colors.orange.withOpacity(0.1),
              thumbColor:
                  enabled ? Colors.orange : Colors.orange.withOpacity(0.3),
              overlayColor:
                  enabled ? Colors.orange.withOpacity(0.1) : Colors.transparent,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: max,
              divisions: max.toInt(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}
