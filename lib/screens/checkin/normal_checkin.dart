import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:http_parser/http_parser.dart';
import 'package:jiffy/jiffy.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unique_identifier/unique_identifier.dart';
import 'package:geocoding/geocoding.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:sliding_widget/sliding_widget.dart';
import 'package:intl/intl.dart';
import 'package:vcheck_face_recognition_app/api-access/api_service.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_error_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/custom_error_dialog_two.dart';
import 'package:vcheck_face_recognition_app/dialogs/status_overlay_dialog.dart';
import 'package:vcheck_face_recognition_app/dialogs/utils.dart';
import 'package:vcheck_face_recognition_app/main.dart';
import 'package:vcheck_face_recognition_app/screens/auto-capture/auto_capture_cameraview.dart';
import 'package:vcheck_face_recognition_app/screens/auto-capture/get_processing_status_view.dart';
import 'package:vcheck_face_recognition_app/screens/home/home_page.dart';

class NormalCheckin extends StatefulWidget {
  NormalCheckin({super.key});

  @override
  _NormalCheckinSate createState() => _NormalCheckinSate();
}

class _NormalCheckinSate extends State<NormalCheckin>
    with WidgetsBindingObserver {
  XFile? imageFile;
  late SharedPreferences _storage;
  Timer? timer;
  Timer? errorWaitTimer;
  double lat = 0;
  double long = 0;
  dynamic userObj = <String, String>{};
  String date = "";
  String time = "";
  String name = "";
  String locationAddress = "";
  String locationId = "";
  double locationDistance = 0.0;
  String barcodeText = "";
  bool inCameraPreview = true;
  String action_text = "Slide to Checkin/\nCheckout";
  bool autoCaptureFace = false;
  List<dynamic> events = [];
  bool startSlider = false;
  int lastSliderIndex = -1;
  int counter = 0;
  String userId = "";
  CameraController? _cameraController;
  CameraDescription? firstCamera;
  Future<void>? _initializeControllerFuture;
  int _cameraIndex = 0;
  Position? _currentPosition;
  late var timer2;
  int successCount = 0;
  int failedCount = 0;
  int noMatchCount = 0;
  int duplicateCount = 0;
  bool _isCameraReady = false;
  double sliderWait = 5;
  double errorWait = 6;
  double NormalCheckinCheckOutGap = 0;

  List<dynamic> successEventList = [];
  List<dynamic> noMatchEventList = [];
  List<dynamic> failEventList = [];

  @override
  void initState() {
    super.initState();
    getUserCurrentPosition();
    getSharedPrefs();
    if (mounted) {
      timer2 = Timer.periodic(
        Duration(microseconds: 10),
        (_) => setState(() {
          time = Jiffy.now().format(pattern: "hh:mm:ss a");
        }),
      );
    }

    initCamera();
  }

  @override
  void dispose() {
    _cameraController!.dispose();
    timer2.cancel();

    super.dispose();
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
    userObj = jsonDecode(_storage.getString('user_data')!);
    if (mounted) {
      setState(() {
        name = userObj["FirstName"] + " " + userObj["LastName"];
      });
    }

    userId = userObj["Id"].replaceAll(RegExp('[^A-Za-z]'), '');

    locationId = _storage.getString('LocationId') ?? "";
    locationDistance = _storage.getDouble('LocationDistance') ?? 0.0;

    double? captureWaitPref = _storage.getDouble('CaptureWait');
    double? sliderWaitPref = _storage.getDouble('SliderWait');
    double? CheckinCheckOutGapPref =
        _storage.getDouble('NormalCheckinCheckOutGap');
    double? errorWaitPref = _storage.getDouble('ErrorWait');
    bool? autoCaptureFacePref = _storage.getBool('AutoCaptureFace');

    int? _successCount2 = _storage.getInt('SuccessCount');
    int? _duplicateCount2 = _storage.getInt('DuplicateCount');
    int? _noMatchCount2 = _storage.getInt('NoMatchCount');
    int? _failedCount2 = _storage.getInt('FailedCount');

    setState(() {
      sliderWait = sliderWaitPref ?? 5;
      NormalCheckinCheckOutGap = CheckinCheckOutGapPref ?? 0;
      errorWait = errorWaitPref ?? 6;
      autoCaptureFace = autoCaptureFacePref ?? false;

      successCount = _successCount2 ?? 0;
      duplicateCount = _duplicateCount2 ?? 0;
      noMatchCount = _noMatchCount2 ?? 0;
      failedCount = _failedCount2 ?? 0;
    });

    print("NormalCheckin captureWaitPref  $captureWaitPref");
    // print("NormalCheckin NormalCheckinCheckOutGapPref  $NormalCheckinCheckOutGapPref");
    // print("NormalCheckin errorWaitPref  $errorWaitPref");
    // print("NormalCheckin sliderWaitPref  $sliderWaitPref");

    // print("NormalCheckin autoCaptureFacePref  $autoCaptureFacePref");

    date = Jiffy.now().yMMMMd;
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
      await getUserCurrentPosition();

      long = _currentPosition!.longitude;
      lat = _currentPosition!.latitude;

      locationId = _storage.getString('LocationId') ?? "";
      locationDistance = _storage.getDouble('LocationDistance') ?? 0.0;
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

  @override
  Widget build(BuildContext context) {
    if (inCameraPreview) {
      return _cameraController == null ||
              (!_cameraController!.value.isInitialized)
          ? Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 2),
                Text(
                  "Loading...",
                  style: GoogleFonts.lato(
                    textStyle: Theme.of(context).textTheme.displayMedium,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            )
          : getCameraPreview(context);
    } else if (autoCaptureFace && !inCameraPreview) {
      print("passed events $events");
     
     
      return GetProcessingStatusView(
        errorWait: errorWait,
        events: events,
        lastSliderIndex: lastSliderIndex,
        sliderWait: sliderWait,
        startSlider: startSlider,
      );
    } else {
      return getImagePreview(context);
    }
  }

  Future<void> processImage(XFile inputImage) async {
    if (mounted) {
      setState(() {
        inCameraPreview = false;
      });
    }
    imageFile = inputImage;
    try {
      saveAction(imageFile!.path, userObj['FaceCheckAccuracy'], "No");
    } catch (e) {
      // If an error occurs, log the error to the console.
      print(e);
    }
  }

  Widget getCameraPreview(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    if (autoCaptureFace) {
      return AutoCaptureCameraView(
        onImage: (inputImage) {
          processImage(inputImage);
        },
        initialDirection: CameraLensDirection.front,
      );
    } else {
      return PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          if (didPop) {
            return;
          }
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) {
              return HomePage();
            }),
            (route) => false,
          );
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
                            child: _buildFaceRecognitionArea(size.height),
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
                    MaterialPageRoute(builder: (context) {
                      return HomePage();
                    }),
                    (route) => false,
                  );
                },
              ),
              Expanded(
                child: Text(
                  'Attendance',
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => HomePage(),
                    ),
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

  Future _onCameraSwitched(CameraDescription cameraDescription) async {
    // await _cameraController!.dispose();

    _cameraController = CameraController(
        cameraDescription, ResolutionPreset.medium,
        enableAudio: false);

    // If the controller is updated then update the UI.
    _cameraController!.addListener(() {
      if (mounted) {
        setState(() {});
      }

      if (_cameraController!.value.hasError) {}
    });

    try {
      await _cameraController!.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }
  }

  void _showCameraException(CameraException e) {
    String errorText = 'Error: ${e.code}\nError Message: ${e.description}';
    print(errorText);
  }

  saveImage() async {
    try {
      await _initializeControllerFuture;
      imageFile = await _cameraController!.takePicture();
      if (mounted) {
        setState(() {
          inCameraPreview = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Widget getImagePreview(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    //   return PopScope(
    //     canPop: false,
    //     onPopInvoked: (didPop) {
    //       if (didPop) {
    //         return;
    //       }
    //       Navigator.of(context).push(
    //         MaterialPageRoute(builder: (_) => NormalCheckin()),
    //       );
    //     },
    //     child: Scaffold(
    //       body: Column(
    //         children: <Widget>[
    //           Stack(
    //             children: <Widget>[
    //               _cameraController != null && _cameraController!.value != null
    //                   ? _cameraIndex == 1
    //                       ? Container(
    //                           alignment: Alignment.center,
    //                           width: size.width,
    //                           height: size.height,
    //                           child: Transform.scale(
    //                             scale: 1,
    //                             child: AspectRatio(
    //                               aspectRatio: 3.0 / 4.0,
    //                               child: Transform(
    //                                 alignment: Alignment.center,
    //                                 transform: Matrix4.rotationY(math.pi),
    //                                 child: Container(
    //                                   decoration: BoxDecoration(
    //                                     image: DecorationImage(
    //                                       fit: BoxFit.contain,
    //                                       image: FileImage(
    //                                         File(imageFile!.path),
    //                                       ),
    //                                     ),
    //                                   ),
    //                                 ),
    //                               ),
    //                             ),
    //                           ),
    //                         )
    //                       : Container(
    //                           alignment: Alignment.center,
    //                           width: size.width,
    //                           height: size.height,
    //                           child: Transform.scale(
    //                             scale: 1.1,
    //                             child: AspectRatio(
    //                               aspectRatio: 3.0 / 4.0,
    //                               child: Container(
    //                                 decoration: BoxDecoration(
    //                                   image: DecorationImage(
    //                                     fit: BoxFit.contain,
    //                                     image: FileImage(
    //                                       File(imageFile!.path),
    //                                     ),
    //                                   ),
    //                                 ),
    //                               ),
    //                             ),
    //                           ),
    //                         )
    //                   : Container(),
    //               Positioned(
    //                 top: 55,
    //                 left: 10,
    //                 child: Container(
    //                   color: Colors.white24,
    //                   child: Text(
    //                     date,
    //                     style: TextStyle(
    //                       fontSize: Responsive.isMobileSmall(context) ||
    //                               Responsive.isMobileMedium(context) ||
    //                               Responsive.isMobileLarge(context)
    //                           ? 12
    //                           : Responsive.isTabletPortrait(context)
    //                               ? 24
    //                               : 20,
    //                       fontWeight: FontWeight.bold,
    //                       color: Colors.black,
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //               !autoCaptureFace
    //                   ? Positioned(
    //                       top: 85,
    //                       left: 10,
    //                       child: Container(
    //                         color: Colors.white24,
    //                         child: Text(
    //                           name,
    //                           style: TextStyle(
    //                             fontSize: Responsive.isMobileSmall(context) ||
    //                                     Responsive.isMobileMedium(context) ||
    //                                     Responsive.isMobileLarge(context)
    //                                 ? 14
    //                                 : Responsive.isTabletPortrait(context)
    //                                     ? 24
    //                                     : 19,
    //                             fontWeight: FontWeight.bold,
    //                             color: Colors.black,
    //                           ),
    //                         ),
    //                       ),
    //                     )
    //                   : SizedBox(width: 1),
    //               Positioned(
    //                 top: 55,
    //                 right: 10,
    //                 child: Container(
    //                   color: Colors.white24,
    //                   child: Text(
    //                     time,
    //                     style: TextStyle(
    //                       fontSize: Responsive.isMobileSmall(context) ||
    //                               Responsive.isMobileMedium(context) ||
    //                               Responsive.isMobileLarge(context)
    //                           ? 12
    //                           : Responsive.isTabletPortrait(context)
    //                               ? 24
    //                               : 20,
    //                       fontWeight: FontWeight.bold,
    //                       color: Colors.black,
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //               // CAMERA BUTTON
    //               Positioned(
    //                 bottom: Responsive.isMobileSmall(context)
    //                     ? 5
    //                     : Responsive.isMobileMedium(context)
    //                         ? 10
    //                         : Responsive.isMobileLarge(context)
    //                             ? 10
    //                             : Responsive.isTabletPortrait(context)
    //                                 ? 10
    //                                 : 5,
    //                 right: 10,
    //                 child: ClipOval(
    //                   child: Material(
    //                     color: Colors.blue[900], // button color
    //                     child: InkWell(
    //                       splashColor: Colors.grey, // inkwell color
    //                       child: SizedBox(
    //                         width: Responsive.isMobileSmall(context) ||
    //                                 Responsive.isMobileMedium(context) ||
    //                                 Responsive.isMobileLarge(context)
    //                             ? 60
    //                             : Responsive.isTabletPortrait(context)
    //                                 ? 80
    //                                 : 80,
    //                         height: Responsive.isMobileSmall(context) ||
    //                                 Responsive.isMobileMedium(context) ||
    //                                 Responsive.isMobileLarge(context)
    //                             ? 60
    //                             : Responsive.isTabletPortrait(context)
    //                                 ? 80
    //                                 : 80,
    //                         child: Icon(
    //                           Icons.camera_alt_outlined,
    //                           color: Colors.white,
    //                           size: Responsive.isMobileSmall(context) ||
    //                                   Responsive.isMobileMedium(context) ||
    //                                   Responsive.isMobileLarge(context)
    //                               ? 30
    //                               : 40,
    //                         ),
    //                       ),
    //                       onTap: () {
    //                         if (mounted) {
    //                           setState(() {
    //                             inCameraPreview = true;
    //                           });
    //                         }
    //                       },
    //                     ),
    //                   ),
    //                 ),
    //               ),
    //               locationAddress != ""
    //                   ? Positioned(
    //                       bottom: Responsive.isMobileSmall(context)
    //                           ? 60
    //                           : Responsive.isMobileMedium(context)
    //                               ? 90
    //                               : Responsive.isMobileLarge(context)
    //                                   ? 100
    //                                   : Responsive.isTabletPortrait(context)
    //                                       ? 95
    //                                       : 90,
    //                       left: 0,
    //                       right: 0,
    //                       child: Container(
    //                         padding: EdgeInsets.symmetric(
    //                           horizontal: 8.0,
    //                           vertical: Responsive.isTabletLandscape(context)
    //                               ? 0.0
    //                               : 2.0,
    //                         ),
    //                         color: Colors.white38,
    //                         child: Row(
    //                           mainAxisAlignment: MainAxisAlignment.start,
    //                           children: [
    //                             Icon(
    //                               Icons.my_location,
    //                               color: Colors.grey[900],
    //                               size: Responsive.isMobileSmall(context) ||
    //                                       Responsive.isMobileMedium(context) ||
    //                                       Responsive.isMobileLarge(context)
    //                                   ? 24
    //                                   : Responsive.isTabletPortrait(context)
    //                                       ? 32
    //                                       : 35,
    //                               semanticLabel: '',
    //                             ),
    //                             SizedBox(width: 5),
    //                             AutoSizeText(
    //                               locationAddress,
    //                               style: TextStyle(
    //                                   fontWeight: FontWeight.w500,
    //                                   fontSize: Responsive.isMobileSmall(context)
    //                                       ? 13
    //                                       : Responsive.isMobileMedium(context)
    //                                           ? 14
    //                                           : Responsive.isMobileLarge(context)
    //                                               ? 15
    //                                               : 19),
    //                               maxLines: 2,
    //                             ),
    //                           ],
    //                         ),
    //                       ),
    //                     )
    //                   : SizedBox(),

    //               !autoCaptureFace
    //                   ? Positioned(
    //                       bottom: Responsive.isMobileSmall(context)
    //                           ? 5
    //                           : Responsive.isMobileMedium(context)
    //                               ? 10
    //                               : Responsive.isMobileLarge(context)
    //                                   ? 10
    //                                   : Responsive.isTabletPortrait(context)
    //                                       ? 10
    //                                       : 5,
    //                       left: 10,
    //                       child: SlidingWidget(
    //                         shadow: BoxShadow(
    //                           color: Colors.white30,
    //                           blurRadius: 2,
    //                           spreadRadius: 5.0,
    //                         ),
    //                         width: size.width * 0.73,
    //                         height: Responsive.isMobileSmall(context)
    //                             ? 60
    //                             : Responsive.isMobileMedium(context) ||
    //                                     Responsive.isMobileLarge(context)
    //                                 ? 60
    //                                 : Responsive.isTabletPortrait(context)
    //                                     ? 70
    //                                     : 70,
    //                         // backgroundColor: Color.fromARGB(204, 163, 187, 193),
    //                         backgroundColor: Color.fromARGB(255, 174, 205, 233),
    //                         foregroundColor: Colors.white,
    //                         iconColor: Colors.blue,
    //                         stickToEnd: true,
    //                         label: action_text,
    //                         labelStyle: GoogleFonts.lato(
    //                           color: Colors.black,
    //                           fontWeight: FontWeight.w600,
    //                           fontSize: Responsive.isMobileSmall(context)
    //                               ? 16
    //                               : Responsive.isMobileMedium(context) ||
    //                                       Responsive.isMobileLarge(context)
    //                                   ? 18
    //                                   : 20,
    //                         ),
    //                         action: () {
    //                           try {
    //                             saveAction(imageFile!.path,
    //                                 userObj['FaceCheckAccuracy'], "No");
    //                           } catch (e) {
    //                             // If an error occurs, log the error to the console.
    //                             // print(e);
    //                           }
    //                         },
    //                         child: Icon(
    //                           Icons.arrow_forward_ios_sharp,
    //                           color: Colors.blue,
    //                           size: 30,
    //                           shadows: [
    //                             Shadow(color: Colors.blue, blurRadius: 2.0)
    //                           ],
    //                         ),
    //                         backgroundColorEnd:
    //                             Color.fromARGB(204, 163, 187, 193),
    //                       ))
    //                   : SizedBox(width: 1)
    //             ],
    //           ),
    //         ],
    //       ),
    //     ),
    //   );
    // }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic2) {
        if (didPop) {
          return;
        }
        // Navigator.of(context).pushAndRemoveUntil(
        //   MaterialPageRoute(
        //     builder: (_) => NormalCheckin(),
        //   ),
        //   (Route<dynamic> route) => false,
        // );
        if (mounted) {
          setState(() {
            inCameraPreview = true;
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
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
                child: Row(
                  children: [
                    IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios,
                          size: Responsive.isMobileSmall(context)
                              ? 16
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 20
                                  : Responsive.isTabletPortrait(context)
                                      ? 25
                                      : 30,
                          color: screenHeadingColor,
                        ),
                        onPressed: () {
                          // Navigator.of(context).pushReplacement(
                          //   MaterialPageRoute(
                          //     builder: (_) => chec(),
                          //   ),
                          // );
                          if (mounted) {
                            setState(() {
                              inCameraPreview = true;
                            });
                          }
                        }),
                    Expanded(
                      child: Text(
                        'Attendance',
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
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 20, horizontal: 15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Date and Time
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month,
                                  color: iconColors,
                                  size: Responsive.isMobileSmall(context)
                                      ? 20
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 22
                                          : Responsive.isTabletPortrait(context)
                                              ? 25
                                              : 25,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 13
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: iconColors,
                                  size: Responsive.isMobileSmall(context)
                                      ? 20
                                      : Responsive.isMobileMedium(context) ||
                                              Responsive.isMobileLarge(context)
                                          ? 22
                                          : Responsive.isTabletPortrait(context)
                                              ? 25
                                              : 25,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  time,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 13
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 20,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 15),

                        // Name Display
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              color: iconColors,
                              size: Responsive.isMobileSmall(context)
                                  ? 20
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 24
                                      : Responsive.isTabletPortrait(context)
                                          ? 25
                                          : 25,
                            ),
                            SizedBox(width: 5),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 16
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 19
                                        : Responsive.isTabletPortrait(context)
                                            ? 25
                                            : 25,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 25),

                        // Camera Preview Container
                        Container(
                          height: Responsive.isMobileSmall(context)
                              ? 300
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 400
                                  : Responsive.isTabletPortrait(context)
                                      ? 500
                                      : 500,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              color: Colors.grey[200],
                              child: Transform.scale(
                                scale: scale,
                                child: AspectRatio(
                                  aspectRatio: aspectRatio,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        fit: BoxFit.fill,
                                        image: FileImage(
                                          File(imageFile!.path),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),

                        // Location Info
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: iconColors,
                                size: Responsive.isMobileSmall(context)
                                    ? 25
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 30
                                        : Responsive.isTabletPortrait(context)
                                            ? 40
                                            : 40,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  locationAddress,
                                  style: TextStyle(
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 12
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 15
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 20
                                                : 25,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 25),
                        // Slide to Check-in Button

                        SlidingWidget(
                          shadow: BoxShadow(
                            color: Colors.orange.withOpacity(0.2),
                            blurRadius: 5,
                          ),
                          width: size.width,
                          height: Responsive.isMobileSmall(context)
                              ? 60
                              : Responsive.isMobileMedium(context) ||
                                      Responsive.isMobileLarge(context)
                                  ? 62
                                  : Responsive.isTabletPortrait(context)
                                      ? 70
                                      : 70,
                          backgroundColor: actionBtnColor,
                          foregroundColor: Colors.white,
                          iconColor: slidingBarIconColor,
                          stickToEnd: true,
                          label: '        Slide to Check-in/ Check-out',
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: Responsive.isMobileSmall(context)
                                ? 18
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 19
                                    : 25,
                          ),
                          action: () async {
                            try {
                              saveAction(
                                imageFile!.path,
                                userObj['FaceCheckAccuracy'],
                                "No",
                              );
                            } catch (e) {
                              print(e);
                            }
                          },
                          child: Icon(
                            Icons.arrow_forward_ios_sharp,
                            color: iconColors,
                            size: Responsive.isMobileSmall(context)
                                ? 25
                                : Responsive.isMobileMedium(context) ||
                                        Responsive.isMobileLarge(context)
                                    ? 30
                                    : Responsive.isTabletPortrait(context)
                                        ? 40
                                        : 40,
                            shadows: [
                              Shadow(color: Colors.orange, blurRadius: 2.0)
                            ],
                          ),
                          backgroundColorEnd:
                              Color.fromARGB(204, 216, 171, 119),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // getLocation() async {
  //   Geolocator.isLocationServiceEnabled().then((bool firstServiceEnabled) {
  //     if (firstServiceEnabled) {
  //       Geolocator.checkPermission().then((LocationPermission permission) {
  //         if (permission == LocationPermission.denied ||
  //             permission == LocationPermission.deniedForever) {
  //         } else {
  //           getAddress();
  //         }
  //       });
  //     } else {
  //       showOkDialog2(
  //         context,
  //         "Enable Location Service",
  //         "Please enable location service before try this operation",
  //         Icon(
  //           Icons.warning,
  //           color: Colors.red,
  //           size: 60.0,
  //         ),
  //         switchOnLocation,

  // Future<bool> handleLocationPermssion() async {
  //   bool serviceEnabled;
  //   LocationPermission permisision;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     showOkDialog2(
  //       context,
  //       "Enable Location Service",
  //       "Please enable location service before trying this operation",
  //       Icon(
  //         Icons.warning,
  //         color: Colors.red,
  //         size: Responsive.isMobileSmall(context) ||
  //                 Responsive.isMobileMedium(context) ||
  //                 Responsive.isMobileLarge(context)
  //             ? 60
  //             : Responsive.isTabletPortrait(context)
  //                 ? 75
  //                 : 80,
  //       ),
  //       switchOnLocation,
  //     );

  //     return false;
  //   }
  //   permisision = await Geolocator.checkPermission();
  //   if (permisision == LocationPermission.denied) {
  //     permisision = await Geolocator.requestPermission();
  //     if (permisision == LocationPermission.denied) {
  //       showOkDialog2(
  //         context,
  //         "Enable Location Service",
  //         "Location permission denied. Please enable location service before trying this operation",
  //         Icon(
  //           Icons.warning,
  //           color: Colors.red,
  //           size: 60.0,
  //         ),
  //         switchOnLocation,
  //       );
  //       return false;
  //     }
  //   }
  //   if (permisision == LocationPermission.deniedForever) {
  //     showOkDialog2(
  //       context,
  //       "Enable Location Service",
  //       "Location permissions are permanently denied. Please enable location service before trying this operation",
  //       Icon(
  //         Icons.warning,
  //         color: Colors.red,
  //         size: 60.0,
  //       ),
  //       switchOnLocation,
  //     );
  //     return false;
  //   }
  //   return true;
  // }
  Future<void> handleLocationPermssion() async {
    LocationPermission locationPermission;

    locationPermission = await Geolocator.checkPermission();

    if (locationPermission == LocationPermission.denied) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomErrorDialog(
          title: 'Feature is blocked!',
          message: 'Location permissions are denied.',
          onOkPressed: () {
            closeDialog(context);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => HomePage()),
            );
            Geolocator.requestPermission();
          },
          iconData: Icons.block,
        ),
      );
    }
    if (locationPermission == LocationPermission.deniedForever) {
      locationPermission = await Geolocator.requestPermission();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => CustomErrorDialog(
          title: 'Feature is blocked!',
          message: 'Location permissions are permanently denied.',
          onOkPressed: () {
            closeDialog(context);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => HomePage(),
              ),
            );
            Geolocator.requestPermission();
          },
          iconData: Icons.block,
        ),
      );
    }
  }

  Future<void> getUserCurrentPosition() async {
    placemarkFromCoordinates(
            _currentPosition!.latitude, _currentPosition!.longitude,
            localeIdentifier: "en-US")
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        locationAddress =
            '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
      });
    });
  }

  Future<void> saveAction(imagePath, accuracy, hignAccuracy) async {
    showProgressDialog(context);
    String? uniqueID = await UniqueIdentifier.serial;
    MultipartRequest request = MultipartRequest(
      'POST',
      Uri.parse('${ApiService.getMultiFRBaseURL()}/api/multi_face_recognize'),
      // Uri.parse(ApiService.getMultiFRBaseURL() + '/api/recognize'),
    );

    request.files.add(
      await MultipartFile.fromPath(
        'file',
        File(imagePath).path,
        contentType: MediaType('application', 'png'),
      ),
    );

    var now = DateTime.now();
    request.fields['year'] = now.year.toString();
    request.fields['month'] = now.month.toString();
    request.fields['day'] = now.day.toString();
    request.fields['hour'] = now.hour.toString();
    request.fields['minute'] = now.minute.toString();
    request.fields['second'] = now.second.toString();
    request.fields['name'] = userId;
    request.fields['userId'] = userId;
    request.fields['customerId'] = userObj["CustomerId"];
    request.fields['phoneId'] = uniqueID!;
    request.fields['deviceId'] = uniqueID;
    request.fields['action'] = 'NormalCheckin';
    request.fields['lat'] = lat.toString();
    request.fields['long'] = long.toString();
    request.fields['itemId'] = '';
    request.fields['address'] = locationAddress;
    request.fields['data1'] = 'multi';
    request.fields['data2'] = NormalCheckinCheckOutGap.toString();
    request.fields['data3'] = '';
    request.fields['data4'] = userId;
    request.fields['highAccuracy'] = hignAccuracy;
    request.fields['accuracy'] = accuracy.toString();
    request.fields['LocationId'] = locationId;
    request.fields['LocationDistance'] = locationDistance.toString();
    StreamedResponse r = await request.send();
    closeDialog(context);

    print("Code : ${r.statusCode}");

    if (r.statusCode == 200) {
      var respStr = await r.stream.bytesToString();
      print("respStr $respStr");
      var eventsList = jsonDecode(respStr);

      if (mounted) {
        setState(() {
          successEventList.add(1);
          events = eventsList;
          startSlider = true;
        });
      }

      // ------------ Success Count Shared Preferences -------------//
      setState(() {
        successCount = successCount + 1;
      });

      _storage.setInt('SuccessCount', successCount);
      // ------------ Success Count Shared Preferences -------------//

      if (autoCaptureFace) {
        startTimer();
      } else {
        // await getNormalAttendanceConfirmationScreen(
        //   context,
        //   events,
        //   reTryRecognition,
        //   okRecognition,
        // )
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StatusOverlayDialog(
            events: events,
            onRetry: reTryRecognition,
            onOk: okRecognition,
          ),
        ).then((val) {
          if (mounted) {
            setState(() {
              inCameraPreview = true;
            });
          }
        });
      }
    } else if (r.statusCode == 1001) {
      var respStr = await r.stream.bytesToString();

      var eventsList = jsonDecode(respStr);
      if (mounted) {
        setState(() {
          events = eventsList;
          startSlider = true;
        });
      }

      if (autoCaptureFace) {
        startErrorWaitTimer();
      }
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialogTwo(
          title: 'No Matching Face Found.',
          message: 'No images identified in the image',
          onOkPressed: moveToCheckinCamera,
          iconData: MdiIcons.faceRecognition,
          onRetryPressed: () {},
          autoCaptureFace: autoCaptureFace,
          retry: false,
        ),
      );
    } else if (r.statusCode == 409) {
      var respStr = await r.stream.bytesToString();

      var eventsList = jsonDecode(respStr);
      if (mounted) {
        setState(() {
          events = eventsList;
          startSlider = true;
        });
      }

      if (autoCaptureFace) {
        startErrorWaitTimer();
      }
      showDialog(
        context: context,
        builder: (context) => CustomErrorDialogTwo(
          title: 'Duplicate Attendance',
          message: 'A checkin has been marked for this user today',
          onOkPressed: moveToCheckinCamera,
          iconData: MdiIcons.faceRecognition,
          onRetryPressed: () {},
          autoCaptureFace: autoCaptureFace,
          retry: false,
        ),
      );

      if (mounted) {
        setState(() {
          inCameraPreview = false;
        });
      }
    } else {
      r.stream.transform(utf8.decoder).join().then((String content) {
        print("content $content");

        if (content.indexOf('people matched') > 0 ||
            content.indexOf('Could not find any faces') > 0) {
          // ------------ No Match Count Shared Preferences -------------//
          if (mounted) {
            setState(() {
              noMatchCount = noMatchCount + 1;
            });
          }
          _storage.setInt('NoMatchCount', noMatchCount);
          // ------------ No Match Count Shared Preferences -------------//

          if (autoCaptureFace) {
            startErrorWaitTimer();
          }
          showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'No Matching Faces Detected.',
              message:
                  'Sorry, we cannot find any faces that match your face image. Please try another image.',
              onOkPressed: moveToCheckinCamera,
              iconData: MdiIcons.faceRecognition,
            ),
          );
        } else if (content.indexOf('There are no faces') > 0 ||
            content.indexOf('list index out of range') > 0 ||
            content.indexOf('Error occurred') > 0 ||
            content.indexOf("'NoneType' has no len()") > 0) {
          // ------------ Failed Count Shared Preferences -------------//
          setState(() {
            failedCount = failedCount + 1;
          });
          _storage.setInt('FailedCount', failedCount);
          // ------------ Failed Count Shared Preferences -------------//

          if (autoCaptureFace) {
            startErrorWaitTimer();
          }
          showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'No Faces Detected.',
              message:
                  'Sorry. We cannot find any faces in the image. Please try another image.',
              onOkPressed: moveToCheckinCamera,
              iconData: MdiIcons.faceRecognition,
            ),
          );
        } else {
          if (autoCaptureFace) {
            startErrorWaitTimer();
          }

          print(r.statusCode);
          showDialog(
            context: context,
            builder: (context) => CustomErrorDialog(
              title: 'Error occured.!',
              message:
                  'Something went wrong with the connection to the server. Please make sure your internet connection is enabled or if the issue still persists, please contact iCheck.',
              onOkPressed: moveToCheckinCamera,
              iconData: MdiIcons.serverNetwork,
            ),
          );
        }
      });
    }
    // }
  }
  // }

  startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if ((events.length == 1 && counter >= sliderWait) || !startSlider) {
        cancelTimer();
        if (mounted) {
          setState(() {
            events = [];
            inCameraPreview = true;
            counter = 0;
          });
        }
      }
      counter = counter + 1;
    });
  }

  cancelTimer() {
    timer?.cancel();
  }

  startErrorWaitTimer() {
    errorWaitTimer =
        Timer.periodic(Duration(seconds: 1), (errorWaitTimer) async {
      if (counter >= errorWait) {
        cancelErrorWaitTimer();
        Navigator.of(context, rootNavigator: true).pop('dialog');
        if (mounted) {
          setState(() {
            events = [];
            inCameraPreview = true;
            counter = 0;
          });
        }
      }
      counter = counter + 1;
    });
  }

  cancelErrorWaitTimer() {
    errorWaitTimer?.cancel();
  }

  void okRecognition() {
    closeDialog(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return HomePage();
      }),
    );
  }

  void reTryRecognition() {
    closeDialog(context);
    saveAction(imageFile!.path, userObj['FaceCheckReTryAccuracy'], "Yes");
  }

  void moveToCheckinCamera() {
    closeDialog(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => NormalCheckin(),
      ),
      (route) => true,
    );
  }
}
