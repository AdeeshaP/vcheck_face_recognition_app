import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jiffy/jiffy.dart';
import 'dart:convert';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:app_version_update/app_version_update.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_error_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/other_dialogs.dart';
import 'package:vcheck_face_recognition_app/main.dart';
import 'package:vcheck_face_recognition_app/screens/checkin/normal_checkin.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/menu/about_us.dart';
import 'package:vcheck_face_recognition_app/screens/menu/contact_us.dart';
import 'package:vcheck_face_recognition_app/screens/menu/help.dart';
import 'package:vcheck_face_recognition_app/screens/menu/settings.dart';
import 'package:vcheck_face_recognition_app/screens/menu/terms_condition.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String officeTime = "";
  String officeDate = "";
  Map<String, dynamic>? lastCheckIn;
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  String? userData;
  CameraDescription? firstCamera;
  int _cameraIndex = 0;
  final GeolocatorPlatform _geolocatorPlatform = GeolocatorPlatform.instance;
  double captureWait = 5;
  double sliderWait = 3;
  double errorWait = 6;
  double checkInCheckOutGap = 0;
  VersionStatus? versionstatus;
  Position? _currentPosition;
  bool _isLoading = true;

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        officeDate =
            "${Jiffy.now().format(pattern: "EEEE")}, ${Jiffy.now().yMMMMd}";
        officeTime = Jiffy.now().format(pattern: "hh:mm:ss a");
      });
    });

    getSharedPrefs();
    initCamera();
  }

  @override
  void dispose() {
    _cameraController!.dispose();
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    try {
      setState(() {
        _isLoading = true;
      });

      _storage = await SharedPreferences.getInstance();
      userData = _storage.getString('user_data');
      print("userData $userData");

      if (userData != null) {
        userObj = jsonDecode(userData!);
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return Future.error('Location permissions are denied');
        }
      } else if (permission == LocationPermission.deniedForever) {
        return Future.error(
            'Location permissions are permanently denied, we cannot request permissions.');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      await getVersionStatus();

      if (versionstatus != null) {
        Future.delayed(Duration(seconds: 4), () async {
          _verifyVersion();
        });
      }

      double? captureWaitPref = _storage.getDouble('CaptureWait');
      double? sliderWaitPref = _storage.getDouble('SliderWait');
      double? checkInCheckOutGapPref = _storage.getDouble('CheckInCheckOutGap');
      double? errorWaitPref = _storage.getDouble('ErrorWait');
      bool? autoCaptureFacePref = _storage.getBool('AutoCaptureFace');

      print("home captureWaitPref  $captureWaitPref");
      print("home errorWaitPref  $errorWaitPref");
      print("home sliderWaitPref  $sliderWaitPref");
      print("home checkInCheckOutGapPref  $checkInCheckOutGapPref");
      print("home autoCaptureFacePref  $autoCaptureFacePref");

      if ((autoCaptureFacePref == null || autoCaptureFacePref == false) &&
          userData != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // backgroundColor: Colors.white,
            content: Text(
              'Auto capturing has been disabled!',
              style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 15
                      : Responsive.isTabletPortrait(context)
                          ? 23
                          : 28,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      } else if (userData != null && autoCaptureFacePref == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // backgroundColor: Colors.white54,
            content: Text(
              'Auto capturing has been enabled now!',
              style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 15
                      : Responsive.isTabletPortrait(context)
                          ? 23
                          : 28,
                  color: Colors.orange,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Any user has not yet enrolled. Please enroll.!',
              style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context) ||
                          Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 15
                      : Responsive.isTabletPortrait(context)
                          ? 23
                          : 28,
                  color: Colors.red,
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// --------GET App Version Status--------------//
  Future<VersionStatus> getVersionStatus() async {
    NewVersionPlus? newVersion =
        NewVersionPlus(androidId: "com.auradot.vcheck");

    VersionStatus? status = await newVersion.getVersionStatus();
    setState(() {
      versionstatus = status;
    });
    print(newVersion);

    // if (versionstatus != null) {
    return versionstatus!;
    // }
  }

  // VERSION UPDATE

  Future<void> _verifyVersion() async {
    AppVersionUpdate.checkForUpdates(
      playStoreId: 'com.auradot.vcheck',
      country: 'us',
    ).then(
      (result) async {
        if (result.canUpdate!) {
          await AppVersionUpdate.showAlertUpdate(
            appVersionResult: result,
            context: context,
            backgroundColor: Colors.grey[200],
            title: 'Update vCheck ?',
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 24
                  : Responsive.isTabletPortrait(context)
                      ? 28
                      : 27,
            ),
            content: "vCheck recommends that you update to the latest version. " +
                "You still have vCheck ${versionstatus!.localVersion} and new version ${result.storeVersion}" +
                " is available in playstore.",
            contentTextStyle: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontSize: Responsive.isMobileSmall(context) ||
                        Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 16
                    : Responsive.isTabletPortrait(context)
                        ? 25
                        : 24,
                height: 1.44444),
            updateButtonText: 'UPDATE',
            updateTextStyle: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
            ),
            updateButtonStyle: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              backgroundColor: WidgetStateProperty.all(Colors.green[900]),
              minimumSize: Responsive.isMobileSmall(context)
                  ? WidgetStateProperty.all(Size(90, 40))
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? WidgetStateProperty.all(Size(100, 45))
                      : Responsive.isTabletPortrait(context)
                          ? WidgetStateProperty.all(Size(160, 60))
                          : WidgetStateProperty.all(Size(140, 50)),
            ),
            cancelButtonText: 'NO THANKS',
            cancelButtonStyle: ButtonStyle(
              shape: WidgetStateProperty.all(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              foregroundColor: WidgetStateProperty.all(Colors.white),
              backgroundColor: WidgetStateProperty.all(Colors.red[900]),
              minimumSize: Responsive.isMobileSmall(context)
                  ? WidgetStateProperty.all(Size(90, 40))
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? WidgetStateProperty.all(Size(100, 45))
                      : Responsive.isTabletPortrait(context)
                          ? WidgetStateProperty.all(Size(160, 60))
                          : WidgetStateProperty.all(Size(140, 50)),
            ),
            cancelTextStyle: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 18
                          : 18,
            ),
          );
        }
      },
    );
  }

  Future<void> initCamera() async {
    cameras = await availableCameras();

    if (cameras.length > 1) {
      firstCamera = cameras[1];
      _cameraIndex = 1;
    } else {
      firstCamera = cameras.first;
      _cameraIndex = 0;
    }
    _cameraController = CameraController(firstCamera!, ResolutionPreset.medium,
        enableAudio: false);
    _cameraController!.addListener(() {
      setState(() {});
    });
    _initializeControllerFuture = _cameraController!.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  Future<void> onNewCameraSelected(CameraDescription cameraDescription) async {
    final CameraController? oldController = _cameraController;
    if (oldController != null) {
      _cameraController = null;
      await oldController.dispose();
    }

    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _cameraController = cameraController;

    cameraController.addListener(() {
      if (mounted) {
        setState(() {});
      }
      if (cameraController.value.hasError) {}
    });

    try {
      await cameraController.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return Settings();
        }),
      );
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

  void okRecognition() {
    closeDialog(context);
  }

  void switchOnLocation() async {
    closeDialog(context);
    bool ison = await Geolocator.isLocationServiceEnabled();
    if (!ison) {
      await Geolocator.openLocationSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          toolbarHeight: Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context)
              ? 40
              : Responsive.isMobileLarge(context)
                  ? 50
                  : Responsive.isTabletPortrait(context)
                      ? 80
                      : 90,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              SizedBox(
                width: MediaQuery.of(context).size.width - 360,
              ),
            ],
          ),
          backgroundColor: appbarBgColor,
          actions: <Widget>[
            PopupMenuButton<String>(
              menuPadding: EdgeInsets.symmetric(horizontal: 3, vertical: 10),
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
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                color: screenHeadingColor,
              ))
            : getHomeContent(),
      ),
    );
  }

  Widget getHomeContent() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: <Widget>[
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(vertical: 75, horizontal: 30),
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.4),
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  officeTime,
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 32
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 35
                            : Responsive.isTabletPortrait(context)
                                ? 40
                                : 45,
                    fontWeight: FontWeight.bold,
                    color: screenHeadingColor,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  officeDate,
                  style: TextStyle(
                    fontSize: Responsive.isMobileSmall(context)
                        ? 17
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 20
                            : Responsive.isTabletPortrait(context)
                                ? 25
                                : 25,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Spacer(),

          // -------- Attendance Button --------- //
          getAttendenceButton(),
          // SizedBox(
          //   height: Responsive.isMobileSmall(context) ||
          //           Responsive.isMobileMedium(context) ||
          //           Responsive.isMobileLarge(context)
          //       ? 80
          //       : Responsive.isTabletPortrait(context)
          //           ? 60
          //           : 40,
          // ),
          // -------- Enroll Button ------------ //
          getEnrollButton(),
          SizedBox(
            height: Responsive.isMobileSmall(context) ||
                    Responsive.isMobileMedium(context)
                ? 70
                : Responsive.isMobileLarge(context)
                    ? 80.0
                    : Responsive.isTabletPortrait(context)
                        ? 100
                        : 100,
          ),
        ],
      ),
    );
  }

  Widget getAttendenceButton() {
    // Size size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(15),
      child: SizedBox(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: userData == null ? Colors.grey : Colors.white,
            backgroundColor: userData == null ? Colors.grey : actionBtnColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18.0),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: () {
            if (userData == null) {
              showDialog(
                context: context,
                builder: (context) => CustomErrorDialog(
                  title: 'No Enrolled User!',
                  message:
                      "Any user has not enrolled yet. Please enroll first using employee code.",
                  onOkPressed: () => okRecognition(),
                  iconData: Icons.person_add_alt_1_rounded,
                ),
              );
            } else {
              _geolocatorPlatform.isLocationServiceEnabled().then(
                (bool serviceEnabled) {
                  if (serviceEnabled) {
                    //-----------------New Code -------------------//

                    if (lastCheckIn == null ||
                        lastCheckIn!["OutTime"] != null) {
                      _storage.setString('Action', 'checkin');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return NormalCheckin();
                        }),
                      );
                    } else {}
                  } else {
                    _geolocatorPlatform.checkPermission().then(
                      (LocationPermission permission) {
                        if (permission == LocationPermission.denied ||
                            permission == LocationPermission.deniedForever) {
                          showDialog(
                            context: context,
                            builder: (context) => CustomErrorDialog(
                                title: 'Location Service Disabled.',
                                message:
                                    'Please enable location service before trying visit.',
                                onOkPressed: switchOnLocation,
                                iconData: Icons.error_outline),
                          );
                        } else {
                          //-----------------New Code -------------------//
                          if (lastCheckIn == null ||
                              lastCheckIn!["OutTime"] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return NormalCheckin();
                              }),
                            );
                          } else {}
                        }
                      },
                    );
                  }
                },
              );
            }
          },
          child: Text(
            "Attendance",
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 18
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 20
                      : Responsive.isTabletPortrait(context)
                          ? 25
                          : 25,
              fontWeight: FontWeight.w900,
              color: actionBtnTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget getEnrollButton() {
    return Container(
      padding: EdgeInsets.all(15),
      width: double.infinity,
      // -------- Enroll Button ------------ //
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: actionBtnColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        onPressed: () {
          _geolocatorPlatform
              .isLocationServiceEnabled()
              .then((bool serviceEnabled) {
            if (serviceEnabled) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) {
                  return CodeVerificationScreen(storage: _storage);
                }),
              );
            } else {
              _geolocatorPlatform.checkPermission().then(
                (LocationPermission permission) {
                  if (permission == LocationPermission.denied ||
                      permission == LocationPermission.deniedForever) {
                    showDialog(
                      context: context,
                      builder: (context) => CustomErrorDialog(
                          title: 'Location Service Disabled.',
                          message:
                              'Please enable location service before trying visit.',
                          onOkPressed: switchOnLocation,
                          iconData: Icons.error_outline),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return CodeVerificationScreen(storage: _storage);
                      }),
                    );
                  }
                },
              );
            }
          });
        },
        child: Text(
          "Enroll",
          style: TextStyle(
            fontSize: Responsive.isMobileSmall(context)
                ? 18
                : Responsive.isMobileMedium(context) ||
                        Responsive.isMobileLarge(context)
                    ? 20
                    : Responsive.isTabletPortrait(context)
                        ? 25
                        : 25,
            fontWeight: FontWeight.w900,
            color: actionBtnTextColor,
          ),
        ),
      ),
    );
  }
}
