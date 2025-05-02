import 'package:flutter/material.dart';

// ignore: must_be_immutable
class GetProcessingStatusView extends StatefulWidget {
  GetProcessingStatusView({
    super.key,
    required this.sliderWait,
    required this.errorWait,
    required this.events,
    required this.startSlider,
    required this.lastSliderIndex,
  });

  double sliderWait, errorWait;
  int lastSliderIndex;
  final List<dynamic> events;
  bool startSlider;

  @override
  State<GetProcessingStatusView> createState() =>
      _GetProcessingStatusViewState();
}

class _GetProcessingStatusViewState extends State<GetProcessingStatusView> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
