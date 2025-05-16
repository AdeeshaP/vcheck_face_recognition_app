import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jiffy/jiffy.dart';
import 'dart:convert';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:app_version_update/app_version_update.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/dialogs/other_dialogs.dart';
import 'package:vcheck_face_recognition_app/main.dart';
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

class _HomePageState extends State<HomePage> with WidgetsBindingObserver{
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
  
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    super.initState();
    // switchOnLocation();
    getSharedPrefs();
    initCamera();
  }

@override
  void dispose() {
    _cameraController!.dispose();
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    await getVersionStatus();

    _storage = await SharedPreferences.getInstance();
    userData = _storage.getString('user_data');

    if (userData != null) {
      userObj = jsonDecode(userData!);
      // print("userData  $userData");
    } else {
      // print("user data null");
    }

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      setState(() {
        officeDate =
            "${Jiffy.now().format(pattern: "EEEE")}, ${Jiffy.now().yMMMMd}";
        officeTime = Jiffy.now().format(pattern: "hh:mm:ss a");
      });
    });

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
    return Scaffold();
  }
}