import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:jiffy/jiffy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_error_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/other_dialogs.dart';
import 'package:vcheck_face_recognition_app/main.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/enroll_user.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/face_enrollment_preview.dart';

class EnrollmentCaptureScreen extends StatefulWidget {
  const EnrollmentCaptureScreen({super.key});

  @override
  State<EnrollmentCaptureScreen> createState() =>
      _EnrollmentCaptureScreenState();
}

class _EnrollmentCaptureScreenState extends State<EnrollmentCaptureScreen>
    with WidgetsBindingObserver {
  XFile? imageFile;
  SharedPreferences? _storage;
  double lat = 0.0;
  double long = 0.0;
  dynamic userObj = Map<String, String>();
  String locationId = "";
  double locationDistance = 0.0;
  bool inCameraPreview = true;
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  CameraDescription? firstCamera;
  int _cameraIndex = 0;
  late var timer2;
  Position? _currentPosition;
  late bool servicePermission = false;
  late LocationPermission locationPermission;
  String location = "";
  bool _isCameraReady = false;
  String time = "";
  String name = "";
  String locationAddress = "";
  String date = "";

  @override
  void initState() {
    super.initState();

    getSharedPrefs();
    WidgetsBinding.instance.addObserver(this);
    if (mounted)
      timer2 = Timer.periodic(
        Duration(microseconds: 10),
        (_) => setState(() {
          time = Jiffy.now().format(pattern: "hh:mm:ss a");
        }),
      );

    initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController!.dispose();
    timer2.cancel();
    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    await handleLocationPermssion();

    _storage = await SharedPreferences.getInstance();

    userObj = jsonDecode(_storage!.getString('user_data')!);

    if (mounted) {
      setState(() {
        name = userObj["FirstName"] + " " + userObj["LastName"];
        date = Jiffy.now().yMMMMd;
      });
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
    } else {
      _currentPosition = await Geolocator.getCurrentPosition();
      await _getAddressFromCoordinated();

      long = _currentPosition!.longitude;
      lat = _currentPosition!.latitude;

      locationId = _storage!.getString('LocationId') ?? "";
      locationDistance = _storage!.getDouble('LocationDistance') ?? 0.0;
    }
  }

  Future<void> initCamera() async {
    try {
      if (cameras.length > 1) {
        firstCamera = cameras[1];
        _cameraIndex = 1;
      } else {
        firstCamera = cameras.first;
        _cameraIndex = 0;
      }
      final controller = CameraController(firstCamera!, ResolutionPreset.medium,
          enableAudio: false);

      await controller.initialize();

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraReady = true;
        });
      }
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _isCameraReady = false;
      });
    }
  }

  Future<bool> handleLocationPermssion() async {
    LocationPermission permission;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        showDialog(
          context: context,
          builder: (context) => CustomErrorDialog(
            title: 'Feature is blocked!',
            message: 'Location permissions are denied.',
            onOkPressed: () {
              closeDialog(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CodeVerificationScreen(storage: _storage!),
                ),
              );
              Geolocator.requestPermission();
            },
            iconData: Icons.block,
          ),
        );
      }
    }
    if (permission == LocationPermission.deniedForever) {
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialog(
          title: 'Feature is blocked!',
          message: 'Location permissions are permanently denied.',
          onOkPressed: () {
            closeDialog(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => CodeVerificationScreen(storage: _storage!),
              ),
            );
            Geolocator.requestPermission();
          },
          iconData: Icons.block,
        ),
      );
    }
    return true;
  }

  // Get user current location

  Future<Position> get_currentPosition() async {
    servicePermission = await Geolocator.isLocationServiceEnabled();
    if (!servicePermission) {
      print("Service disbaled");
    }

    locationPermission = await Geolocator.checkPermission();
    if (locationPermission == LocationPermission.deniedForever ||
        locationPermission == LocationPermission.denied) {
      locationPermission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  // Future<void> getUserCurrentPosition() async {
  //   final hasPermission = await handleLocationPermssion();
  //   if (!hasPermission) return;

  //   await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
  //       .then((Position position) {
  //     setState(() => _currentPosition = position);
  //     _getAddressFromLatLng(_currentPosition!);
  //   }).catchError((e) {
  //     debugPrint(e);
  //   });
  // }

  _getAddressFromCoordinated() async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentPosition!.latitude, _currentPosition!.longitude);

    Placemark place = placemarks[0];

    locationAddress =
        '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
  }

  // Future<void> _getAddressFromLatLng(Position position) async {
  //   await placemarkFromCoordinates(
  //           _currentPosition!.latitude, _currentPosition!.longitude)
  //       .then((List<Placemark> placemarks) {
  //     Placemark place = placemarks[0];
  //     setState(() {
  //       locationAddress =
  //           '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
  //     });
  //   }).catchError((e) {
  //     debugPrint(e);
  //   });
  // }

  saveImage() async {
    try {
      await _initializeControllerFuture;
      imageFile = await _cameraController!.takePicture();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EnrollmentPreview(
            imagePath: imageFile!.path,
            username: userObj["FirstName"] + " " + userObj["LastName"],
            location: locationAddress,
            time: time,
            date: date,
          ),
        ),
      );
    } catch (e) {
      print(e);
    }
  }

  Future _onCameraSwitched(CameraDescription cameraDescription) async {
    _cameraController = CameraController(
        cameraDescription, ResolutionPreset.medium,
        enableAudio: false);

    try {
      await _cameraController!.initialize();
    } on CameraException catch (e) {
      print(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => EnrollUser(
                userObj: userObj,
              ),
            ),
            (Route<dynamic> route) => false);
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildHeader(context),
                        Expanded(
                          child: _buildFaceRecognitionArea(screenHeight),
                        ),
                        _buildBottomButtons(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: screenHeadingColor),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnrollUser(
                        userObj: userObj,
                      ),
                    ),
                    (route) => false,
                  );
                },
              ),
              Expanded(
                child: Text(
                  'Face Enrollment',
                  style: TextStyle(
                    color: screenHeadingColor,
                    fontSize: Responsive.isMobileSmall(context)
                        ? 20
                        : Responsive.isMobileMedium(context) ||
                                Responsive.isMobileLarge(context)
                            ? 24
                            : Responsive.isTabletPortrait(context)
                                ? 28
                                : 30,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 40),
            ],
          ),
          SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: shadeBoxBgColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        Icons.calendar_today,
                        'Date',
                        DateFormat('MMM dd, yyyy').format(DateTime.now()),
                      ),
                    ),
                    Expanded(
                      child: _buildInfoItem(
                        Icons.access_time,
                        'Time',
                        DateFormat('HH:mm:ss').format(DateTime.now()),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                _buildInfoItem(
                  Icons.location_on,
                  'Location',
                  locationAddress,
                ),
              ],
            ),
          ),
          SizedBox(height: 10)
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColors,
          size: Responsive.isMobileSmall(context)
              ? 18
              : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 20
                  : Responsive.isTabletPortrait(context)
                      ? 25
                      : 25,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 11
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 13
                          : Responsive.isTabletPortrait(context)
                              ? 16
                              : 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                              ? 18
                              : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraPreview(double screenHeight) {
    if (!_isCameraReady || _cameraController == null) {
      return Container(
        width: screenHeight * 0.35,
        height: screenHeight * 0.35,
        decoration: BoxDecoration(
          color: Colors.orange[50],
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.face,
          size: screenHeight * 0.15,
          color: iconColors,
        ),
      );
    }

    final size = screenHeight * 0.35;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: OverflowBox(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.cover,
          child: Container(
            width: size,
            height: size,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: CameraPreview(_cameraController!),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaceRecognitionArea(double screenHeight) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Keep your face focused',
            style: TextStyle(
              color: iconColors,
              fontSize: Responsive.isMobileSmall(context)
                  ? 18
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 20
                      : Responsive.isTabletPortrait(context)
                          ? 22
                          : 25,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 15),
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: screenHeight * 0.32,
                height: screenHeight * 0.32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: iconColors, width: 2),
                ),
                child: _buildCameraPreview(screenHeight),
              ),
            ],
          ),
          SizedBox(height: 15),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: shadeBoxBgColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                'Position your face in the circle and ensure adequate light.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                              ? 18
                              : 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EnrollUser(
                        userObj: userObj,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.arrow_back,
                      color: Colors.grey[800]!,
                      size: Responsive.isMobileSmall(context)
                          ? 25
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 30
                              : 35),
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Back",
                style: TextStyle(
                  color: Colors.grey[800]!,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                              ? 18
                              : 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (locationAddress != "") {
                    saveImage();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: locationAddress == ""
                      ? BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        )
                      : BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange[600]!, Colors.orange[800]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red[200]!.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                  child: Icon(Icons.camera_alt,
                      color: locationAddress == ""
                          ? Colors.grey[800]
                          : Colors.white,
                      size: Responsive.isMobileSmall(context)
                          ? 30
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 40
                              : 45),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Capture',
                style: TextStyle(
                  color: locationAddress == ""
                      ? Colors.grey[800]!
                      : cameraCaptureBtnColor,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                              ? 18
                              : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  if (_cameraIndex == 0 && cameras.length > 1) {
                    firstCamera = cameras[1];
                    _cameraIndex = 1;
                  } else {
                    firstCamera = cameras.first;
                    _cameraIndex = 0;
                  }

                  _onCameraSwitched(firstCamera!);
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(Icons.cameraswitch_rounded,
                      color: Colors.grey[800]!,
                      size: Responsive.isMobileSmall(context)
                          ? 25
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 30
                              : 35),
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Switch",
                style: TextStyle(
                  color: Colors.grey[800]!,
                  fontSize: Responsive.isMobileSmall(context)
                      ? 12
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 14
                          : Responsive.isTabletPortrait(context)
                              ? 18
                              : 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
