import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcheck_face_recognition_app/constants/constants.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/menu/about_us.dart';
import 'package:vcheck_face_recognition_app/screens/menu/help.dart';
import 'package:vcheck_face_recognition_app/screens/menu/settings.dart';
import 'package:vcheck_face_recognition_app/screens/menu/terms_condition.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  late SharedPreferences _storage;
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  // Location coordinates for Sri Lanka address
  static LatLng _companyLocation = LatLng(6.896372574204375, 79.8576333140073);

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
    _markers.add(
      Marker(
        markerId: MarkerId('company_location'),
        position: _companyLocation,
        infoWindow: InfoWindow(
          title: 'Auradot (Pvt) Ltd.',
          snippet: '410/118 Bauddhaloka Mawatha, Colombo 00700',
        ),
      ),
    );
  }

  void _openMap() async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${_companyLocation.latitude},${_companyLocation.longitude}';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  Future<void> getSharedPrefs() async {
    _storage = await SharedPreferences.getInstance();
  }

  // SIDE MENU BAR UI
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

  Future<void> _makeHotLineCall() async {
    String phoneNumber = "+94773420983";
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri, mode: LaunchMode.externalNonBrowserApplication);
  }

  Future<void> _makeLandLineCall() async {
    String phoneNumber = "+94117109911";
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri, mode: LaunchMode.externalNonBrowserApplication);
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _sendEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'contact@icheck.ai',
      query: encodeQueryParameters(<String, String>{
        'subject': 'Add Subject',
        'body': 'Write something...!',
      }),
    );

    launchUrl(emailLaunchUri);
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColors,
                  size: Responsive.isMobileSmall(context)
                      ? 22
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 25
                          : Responsive.isTabletPortrait(context)
                              ? 28
                              : 30,
                ),
              ),
              SizedBox(width: 15),
              Text(
                title,
                style: TextStyle(
                  fontSize: Responsive.isMobileSmall(context)
                      ? 16
                      : Responsive.isMobileMedium(context) ||
                              Responsive.isMobileLarge(context)
                          ? 18
                          : Responsive.isTabletPortrait(context)
                              ? 22
                              : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          ...children,
        ],
      ),
    );
  }

  Widget _buildText(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          fontSize: Responsive.isMobileSmall(context)
              ? 14
              : Responsive.isMobileMedium(context) ||
                      Responsive.isMobileLarge(context)
                  ? 16
                  : Responsive.isTabletPortrait(context)
                      ? 20
                      : 20,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildClickableContact(
      String label, String value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: Responsive.isMobileSmall(context)
                  ? 14
                  : Responsive.isMobileMedium(context) ||
                          Responsive.isMobileLarge(context)
                      ? 16
                      : Responsive.isTabletPortrait(context)
                          ? 20
                          : 20,
              color: numberColors,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic) {
        if (didPop) {
          return;
        }

        Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
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
        body: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: IconButton(
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
                        ),
                        Expanded(
                          flex: 10,
                          child: Text(
                            'Contact Us',
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 22
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 26
                                      : Responsive.isTabletPortrait(context)
                                          ? 28
                                          : 32,
                              fontWeight: FontWeight.bold,
                              color: screenHeadingColor,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(""),
                        )
                      ],
                    ),
                    SizedBox(height: 10),
                    // Text(
                    //   'Your feedback is very valuable to us!',
                    //   style: TextStyle(
                    //     fontSize: Responsive.isMobileSmall(context)
                    //         ? 14
                    //         : Responsive.isMobileMedium(context) ||
                    //                 Responsive.isMobileLarge(context)
                    //             ? 16
                    //             : Responsive.isTabletPortrait(context)
                    //                 ? 20
                    //                 : 20,
                    //     color: Colors.grey.shade600,
                    //   ),
                    // ),
                    // SizedBox(height: 30),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    _buildContactCard(
                      icon: Icons.business,
                      title: 'Company',
                      children: [
                        _buildText('Auradot (Pvt) Ltd.'),
                        _buildText('410/118, Bauddhaloka Mawatha,'),
                        _buildText('Colombo 00700, Sri Lanka'),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildContactCard(
                      icon: Icons.phone,
                      title: 'Phone Numbers',
                      children: [
                        _buildClickableContact(
                          'Hotline',
                          '+94 773 420 983',
                          () => _makeHotLineCall(),
                        ),
                        SizedBox(height: 10),
                        _buildClickableContact(
                          'Landline',
                          '+94 117 109 911',
                          () => _makeLandLineCall(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _buildContactCard(
                      icon: Icons.email,
                      title: 'Email',
                      children: [
                        _buildClickableContact(
                          'Email Us',
                          'contact@icheck.ai',
                          () => _sendEmail(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Map
                    Container(
                      height: Responsive.isMobileSmall(context)
                          ? 150
                          : Responsive.isMobileMedium(context) ||
                                  Responsive.isMobileLarge(context)
                              ? 175
                              : Responsive.isTabletPortrait(context)
                                  ? 200
                                  : 250,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: GestureDetector(
                          onDoubleTap: _openMap,
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _companyLocation,
                              zoom: 10,
                            ),
                            markers: _markers,
                            onMapCreated: (GoogleMapController controller) {
                              mapController = controller;
                            },
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
      ),
    );
  }
}
