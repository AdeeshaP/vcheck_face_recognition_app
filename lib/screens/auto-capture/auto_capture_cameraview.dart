import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class AutoCaptureCameraView extends StatefulWidget {
  const AutoCaptureCameraView(
      {super.key, required this.onImage, required this.initialDirection});

  final Function(XFile inputImage) onImage;
  final CameraLensDirection initialDirection;

  @override
  State<AutoCaptureCameraView> createState() => _AutoCaptureCameraViewState();
}

class _AutoCaptureCameraViewState extends State<AutoCaptureCameraView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
