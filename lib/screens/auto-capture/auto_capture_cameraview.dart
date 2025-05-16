import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/screens/auto-capture/face_detector_painter.dart';
import 'package:vcheck_face_recognition_app/screens/home/home_page.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../main.dart';

enum ScreenMode { liveFeed, gallery }

class AutoCaptureCameraView extends StatefulWidget {
  AutoCaptureCameraView({
    Key? key,
    required this.onImage,
    this.initialDirection = CameraLensDirection.front,
  }) : super(key: key);

  final Function(XFile inputImage) onImage;
  final CameraLensDirection initialDirection;

  @override
  _AutoCaptureCameraViewState createState() => _AutoCaptureCameraViewState();
}

class _AutoCaptureCameraViewState extends State<AutoCaptureCameraView> {
  ScreenMode _mode = ScreenMode.liveFeed;
  CameraController? _cameraController;
  File? _image;
  double minZoomLevel = 1.0;
  double maxZoomLevel = 1.0;
  double _zoomSliderVal = 1.0;
  double _fixedZoomVal = 1.0;
  FaceDetector faceDetector =
      GoogleMlKit.vision.faceDetector(FaceDetectorOptions(
    enableContours: true,
    enableClassification: true,
  ));
  bool isBusy = false;
  int faceFoundStatus = 0;
  Timer? timer;
  int counter = 0;
  CustomPaint? customPaint;
  InputImage? inputImage;
  CameraDescription? firstCamera;
  int _cameraIndex = 0;
  late SharedPreferences _storage;
  Map<String, dynamic>? userObj;
  String officeTime = "";
  String officeDate = "";
  double countDownStart = 5;
  bool isZoomLevelsInitialized = false;

  @override
  void initState() {
    super.initState();
    startLiveFeed();
    getSharedPrefreences();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    // _cameraController!.dispose();
    // super.dispose();
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        _cameraController!.stopImageStream();
      }
      _cameraController!.dispose();
      _cameraController = null;
    }
    faceDetector.close(); // Also close the face detector
    timer?.cancel();
    WakelockPlus.disable(); // Disable wakelock if no longer needed
    super.dispose();
  }

  Future<void> getSharedPrefreences() async {
    _storage = await SharedPreferences.getInstance();

    double? captureWaitPref = _storage.getDouble('CaptureWait');
    double? zoomSliderValue = _storage.getDouble('zoomSliderValue');
    double? fixedZoomVal = _storage.getDouble('fixedZoomVal');

    setState(() {
      print("zoomSliderValue  $zoomSliderValue");
      print("fixedZoomVal  $fixedZoomVal");
      print("captureWaitPref  $captureWaitPref");

      countDownStart = captureWaitPref ?? 5;
      _zoomSliderVal = zoomSliderValue ?? 1.0;
      _fixedZoomVal = fixedZoomVal ?? 0.0;
    });
    print("countDownStart  $countDownStart");
  }

  Future<void> startLiveFeed() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        if (cameras.length > 1) {
          firstCamera = cameras[1];
          _cameraIndex = 1;
        } else {
          firstCamera = cameras.first;
          _cameraIndex = 0;
        }

        _cameraController = CameraController(
          firstCamera!,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        await _cameraController!.getMinZoomLevel().then((value) {
          minZoomLevel = value;
          _zoomSliderVal = _zoomSliderVal.clamp(minZoomLevel, maxZoomLevel);
          _fixedZoomVal = _fixedZoomVal.clamp(minZoomLevel, maxZoomLevel);
        });

        await _cameraController!.getMaxZoomLevel().then((value) {
          maxZoomLevel = value;
          _zoomSliderVal = _zoomSliderVal.clamp(minZoomLevel, maxZoomLevel);
          _fixedZoomVal = _fixedZoomVal.clamp(minZoomLevel, maxZoomLevel);
        });

        setState(() {
          isZoomLevelsInitialized = true;
        });

        _cameraController!
            .setZoomLevel(_fixedZoomVal.clamp(minZoomLevel, maxZoomLevel));

        // _cameraController?.startImageStream(_processCameraImage());
        _cameraController?.startImageStream(_processCameraImage);
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future _getImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      _processPickedFile(pickedFile);
    } else {
      print('No image selected.');
    }
    setState(() {});
  }

  Future _processPickedFile(XFile pickedFile) async {
    if (mounted) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
    inputImage = InputImage.fromFilePath(pickedFile.path);
  }

  Future _processCameraImage(CameraImage image) async {
    bool locationServiceEnabled;
    locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    if (cameras.length > 1) {
      firstCamera = cameras[1];
      _cameraIndex = 1;
    } else {
      firstCamera = cameras.first;
      _cameraIndex = 0;
    }
    final imageRotation =
        InputImageRotationValue.fromRawValue(firstCamera!.sensorOrientation) ??
            InputImageRotation.rotation0deg;

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.nv21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    if (isBusy) return;
    isBusy = true;
    final faces = await faceDetector.processImage(inputImage!);
    if (mounted &&
        faces.length > 0 &&
        faceFoundStatus == 0 &&
        locationServiceEnabled == true) {
      setState(() {
        faceFoundStatus = 1;
      });
      startTimer();
    } else if (mounted &&
        faces.length == 0 &&
        faceFoundStatus == 1 &&
        locationServiceEnabled == true) {
      cancelTimer();
      if (mounted) {
        setState(() {
          counter = 0;
          faceFoundStatus = 0;
        });
      }
    }
    print('Found ${faces.length} faces');
    if (inputImage!.inputImageData?.size != null &&
        inputImage!.inputImageData?.imageRotation != null) {
      final painter = FaceDetectorPainter(
          faces,
          inputImage!.inputImageData!.size,
          inputImage!.inputImageData!.imageRotation);
      customPaint = CustomPaint(painter: painter);
    } else {
      customPaint = null;
    }
    isBusy = false;
    if (mounted) {
      setState(() {});
    }

    print("camera index is $_cameraIndex");
    //
  }

//  void _processCameraImage(CameraImage image) async {
//     bool locationServiceEnabled;
//     locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

//     final WriteBuffer allBytes = WriteBuffer();
//     for (Plane plane in image.planes) {
//       allBytes.putUint8List(plane.bytes);
//     }
//     final bytes = allBytes.done().buffer.asUint8List();

//     final Size imageSize =
//         Size(image.width.toDouble(), image.height.toDouble());

//     if (cameras.length > 1) {
//       firstCamera = cameras[1];
//       _cameraIndex = 1;
//     } else {
//       firstCamera = cameras.first;
//       _cameraIndex = 0;
//     }
//     final imageRotation =
//         InputImageRotationValue.fromRawValue(firstCamera!.sensorOrientation) ??
//             InputImageRotation.rotation0deg;

//     final inputImageFormat =
//         InputImageFormatValue.fromRawValue(image.format.raw) ??
//             InputImageFormat.nv21;

//     if (image.planes.length != 1) return null;
//     final plane = image.planes.first;

//     inputImage = InputImage.fromBytes(
//         bytes: plane.bytes,
//         metadata: InputImageMetadata(
//           size: imageSize,
//           rotation: imageRotation,
//           format: inputImageFormat,
//           bytesPerRow: plane.bytesPerRow,
//         ));

//     if (isBusy) return;

//     isBusy = true;

//     final faces = await faceDetector.processImage(inputImage!);

//     if (mounted &&
//         faces.length > 0 &&
//         faceFoundStatus == 0 &&
//         locationServiceEnabled == true) {
//       setState(() {
//         faceFoundStatus = 1;
//       });
//       startTimer();
//     } else if (mounted &&
//         faces.length == 0 &&
//         faceFoundStatus == 1 &&
//         locationServiceEnabled == true) {
//       cancelTimer();
//       if (mounted) {
//         setState(() {
//           counter = 0;
//           faceFoundStatus = 0;
//         });
//       }
//     }
//     print('Found ${faces.length} faces');
//     if (inputImage!.metadata?.size != null &&
//         inputImage!.metadata?.rotation != null) {
//       final painter = FaceDetectorPainter(
//           faces, inputImage!.metadata!.size, inputImage!.metadata!.rotation);
//       customPaint = CustomPaint(painter: painter);
//     } else {
//       customPaint = null;
//     }
//     isBusy = false;
//     if (mounted) {
//       setState(() {});
//     }

//     print("camera index is $_cameraIndex");
//     //
//   }

  startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (counter > countDownStart && faceFoundStatus == 1) {
        //Capture
        faceFoundStatus = 2;
        if (faceFoundStatus == 2) {
          cancelTimer();
        }
        counter = 0;
        try {
          await _cameraController!.stopImageStream();
        } catch (error) {}
        var imageFile = await _cameraController!.takePicture();
        widget.onImage(imageFile);
      } else {
        if (mounted) {
          setState(() {
            counter++;
          });
        }
      }
    });
  }

  cancelTimer() {
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
          (route) => false,
        );
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: Responsive.isMobileSmall(context) ||
                  Responsive.isMobileMedium(context)
              ? 45
              : Responsive.isMobileLarge(context)
                  ? 55
                  : Responsive.isTabletPortrait(context)
                      ? 80
                      : 90,
          leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: screenHeadingColor),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return HomePage();
                  }),
                  (route) => false,
                );
              }),
          title: Text(
            'Keep your face focused',
            style: TextStyle(
              color: screenHeadingColor,
              fontSize: Responsive.isMobileSmall(context) ||
                      Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 21
                  : Responsive.isTabletPortrait(context)
                      ? 40
                      : 50,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
        ),
        body: _body(),
      ),
    );
  }

  Widget _body() {
    Widget body;
    if (_mode == ScreenMode.liveFeed) {
      body = _liveFeedBody();
    } else {
      body = _galleryBody();
    }
    return body;
  }

  Widget _liveFeedBody() {
    print("min zoom level is $minZoomLevel");
    print("max zoom level is $maxZoomLevel");
    print(" zoom slider val is $_zoomSliderVal");
    if (_cameraController == null ||
        _cameraController!.value.isInitialized == false) {
      return Container();
    } else {
      return Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CameraPreview(_cameraController!),
            if (customPaint != null) customPaint!,
            // Orange Slider
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Container(
                        //   width: 20,
                        //   height: 20,
                        //   decoration: BoxDecoration(
                        //     color: Colors.deepOrange,
                        //     shape: BoxShape.circle,
                        //   ),
                        // ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              activeTrackColor: Colors.deepOrange,
                              inactiveTrackColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.deepOrange,
                              thumbShape: RoundSliderThumbShape(
                                enabledThumbRadius: 12,
                              ),
                              overlayColor: Colors.deepOrange.withOpacity(0.2),
                            ),
                            child: Slider(
                              max: maxZoomLevel,
                              min: minZoomLevel,
                              value: _zoomSliderVal,
                              onChanged: (newSliderValue) {
                                if (mounted) {
                                  setState(() {
                                    _zoomSliderVal = newSliderValue;
                                    _fixedZoomVal = _zoomSliderVal;
                                    _storage.setDouble(
                                        'zoomSliderValue', _zoomSliderVal);
                                    _cameraController!
                                        .setZoomLevel(_zoomSliderVal);
                                  });
                                }
                              },
                              divisions:
                                  (maxZoomLevel - minZoomLevel).toInt() < 1
                                      ? null
                                      : (maxZoomLevel - minZoomLevel).toInt(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      "Adjust zoom level using the slider above.\n ← Zoom out | Zoom in →",
                      style: TextStyle(
                        color: actionBtnTextColor,
                        fontSize: Responsive.isMobileSmall(context)
                            ? 12
                            : Responsive.isMobileMedium(context) ||
                                    Responsive.isMobileLarge(context)
                                ? 14
                                : Responsive.isTabletPortrait(context)
                                    ? 16
                                    : 17,
                      ),
                      textAlign: TextAlign.center,
                    )
                  ],
                ),
              ),
            ),

            counter > 0
                ? Positioned(
                    top: 10,
                    right: 10,
                    child: CircleAvatar(
                      radius: MediaQuery.of(context).size.width / 6,
                      backgroundColor: actionBtnColor,
                      child: Center(
                        child: Text(
                          '${((countDownStart - counter + 1).toInt())}',
                          style: GoogleFonts.lato(
                            textStyle:
                                Theme.of(context).textTheme.displayMedium,
                            fontSize: MediaQuery.of(context).size.width / 6,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ))
                : SizedBox(width: 1),
          ],
        ),
      );
    }
  }

  Widget _galleryBody() {
    return ListView(shrinkWrap: true, children: [
      _image != null
          ? SizedBox(
              height: 400,
              width: 400,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.file(_image!),
                  if (customPaint != null) customPaint!,
                ],
              ),
            )
          : Icon(Icons.image, size: 200),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('From Gallery'),
          onPressed: () => _getImage(ImageSource.gallery),
        ),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: ElevatedButton(
          child: Text('Take a picture'),
          onPressed: () => _getImage(ImageSource.camera),
        ),
      ),
    ]);
  }
}
