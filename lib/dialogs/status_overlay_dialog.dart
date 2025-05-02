import 'package:flutter/material.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';

class StatusOverlayDialog extends StatelessWidget {
  final List<dynamic> events;
  final VoidCallback onRetry;
  final VoidCallback onOk;

  StatusOverlayDialog({
    Key? key,
    required this.events,
    required this.onRetry,
    required this.onOk,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int successCount =
        events.where((element) => element['StatusCode'] == 200).length;
    int duplicateCount =
        events.where((element) => element['StatusCode'] == 409).length;
    int failedCount =
        events.where((element) => element['StatusCode'] == 500).length;
    int notMatchedCount =
        events.where((element) => element['StatusCode'] == 404).length;

    return SafeArea(
      child: Material(
        color: Colors.white,
        child: Column(
          children: [
            // Stats Summary
            Container(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatBox(
                      'Success', '${successCount}', Colors.green, context),
                  _buildStatBox(
                      'Duplicates', '${duplicateCount}', Colors.grey, context),
                  _buildStatBox('No Matches', '${notMatchedCount}',
                      Colors.orange, context),
                  _buildStatBox(
                      'Failed', '${failedCount}', Colors.red, context),
                ],
              ),
            ),

            // Scrollable Status Cards
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final item = events[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      // color: Colors.green.shade100,
                      color:
                          getRecordBackgroundColor(events[index]['StatusCode']),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(
                              'https://ucmamyihfa.execute-api.us-east-2.amazonaws.com/dev/services-file?bucket=icheckfaceimages&image=' +
                                  item['ProfileImage']
                                      .replaceAll('./train_img/trained/', ''),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['Code'] +
                                      " - " +
                                      (item['FirstName'] ?? "") +
                                      " " +
                                      (item['LastName'] ?? ""),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Event: ${item['Action']}',
                                  style: TextStyle(
                                    // color: Colors.grey.shade700,
                                    color: getFontColor(item['StatusCode']),
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 15
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 22
                                                : 25,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Status: ${getRecordStatusText(item['StatusCode'])}',
                                  style: TextStyle(
                                    color: getFontColor2(item['StatusCode']),
                                    fontWeight: FontWeight.w500,
                                    fontSize: Responsive.isMobileSmall(context)
                                        ? 15
                                        : Responsive.isMobileMedium(context) ||
                                                Responsive.isMobileLarge(
                                                    context)
                                            ? 16
                                            : Responsive.isTabletPortrait(
                                                    context)
                                                ? 22
                                                : 25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Bottom Buttons
            Container(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withOpacity(0.9),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onOk,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: actionBtnColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  getFontColor(code) {
    if (code == 409) {
      return Colors.black;
    } else if (code == 404) {
      return Colors.black;
    } else if (code == 500) {
      return Colors.white;
    } else {
      return Colors.grey.shade800;
    }
  }

  getFontColor2(code) {
    if (code == 409) {
      return Colors.grey;
    } else if (code == 404) {
      return Colors.red;
    } else if (code == 500) {
      return Colors.red;
    } else {
      return Colors.green;
    }
  }

  getRecordBackgroundColor(code) {
    if (code == 409) {
      return Colors.grey[400];
    } else if (code == 404) {
      return Colors.red[400];
    } else if (code == 500) {
      return Colors.red.shade100;
    } else {
      return Colors.green[100];
    }
  }

  String getRecordStatusText(code) {
    if (code == 409) {
      return "Check in already registered today";
    } else if (code == 404) {
      return "Could not find a matched check in";
    } else if (code == 500) {
      return "Failed registration";
    } else {
      return "Success";
    }
  }

  Widget _buildStatBox(
      String title, String count, Color color, BuildContext context) {
    return Container(
      width: 80,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 24
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 26
                      : Responsive.isTabletPortrait(context)
                          ? 35
                          : 30,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// Data class for status items
class StatusData {
  final String name;
  final String event;
  final String status;
  final String imageUrl;

  StatusData({
    required this.name,
    required this.event,
    required this.status,
    required this.imageUrl,
  });
}
