import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vcheck_face_recognition_app/constants/dimensions.dart';
import 'package:vcheck_face_recognition_app/screens/enroll/code_verification.dart';
import 'package:vcheck_face_recognition_app/screens/menu/contact_us.dart';
import 'package:vcheck_face_recognition_app/screens/menu/help.dart';
import 'package:vcheck_face_recognition_app/screens/menu/settings.dart';
import 'package:vcheck_face_recognition_app/screens/menu/terms_condition.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../constants/constants.dart';

class AboutUs extends StatefulWidget {
  const AboutUs({super.key});

  @override
  State<AboutUs> createState() => _AboutUsState();
}

class _AboutUsState extends State<AboutUs> {
   late SharedPreferences _storage;

  @override
  void initState() {
    super.initState();
    getSharedPrefs();
  }

  @override
  void dispose() {
    super.dispose();
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

  YoutubePlayerController _controller = YoutubePlayerController(
    initialVideoId: 'lNzZ-BshyTY',
    flags: YoutubePlayerFlags(
      autoPlay: false,
      mute: false,
    ),
  );

  Widget youtubeHierarchy() {
    return Container(
      child: Align(
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.fill,
          child: YoutubePlayer(
            controller: _controller,
            showVideoProgressIndicator: true,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
     Size size = MediaQuery.of(context).size;

    return OrientationBuilder(
        builder: (BuildContext context, Orientation orientation) {
      if (orientation == Orientation.landscape) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, dynamic) {
            if (didPop) {
              return;
            }

            Navigator.of(context).pop();
          },
          child: Scaffold(
            body: youtubeHierarchy(),
          ),
        );
      } else {
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
            body: Column(
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
                          "About vCheck",
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

                // Company Description Card
                Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome to vCheck',
                            style: TextStyle(
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 20
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 24
                                        : Responsive.isTabletPortrait(context)
                                            ? 25
                                            : 28,
                                fontWeight: FontWeight.bold,
                                // color: Color(0xFF1976D2),
                                color: screenHeadingColor.withOpacity(0.8)),
                          ),
                          SizedBox(height: 16),
                          Text(
                            "vCheck is focused on non-contact AI driven biometric multi-facial recognition for people management. Our comprehensive suite of products combines facial recognition and thermographic imaging together with Artificial Intelligence, Cloud Computing and Geo Fencing, collectively simplified to provide the assurance and protection any organization would wish for and is affordable to any small office to large distributed. ",
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 15
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 16
                                      : Responsive.isTabletPortrait(context)
                                          ? 18
                                          : 20,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                Container(
                  margin: EdgeInsets.all(5),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 2.0),
                  child: youtubeHierarchy(),
                ),
                // Version Info Card
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 5.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Current Version',
                            style: TextStyle(
                              fontSize: Responsive.isMobileSmall(context)
                                  ? 16
                                  : Responsive.isMobileMedium(context) ||
                                          Responsive.isMobileLarge(context)
                                      ? 18
                                      : Responsive.isTabletPortrait(context)
                                          ? 20
                                          : 22,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              // color: Color(0xFF1976D2),
                              color: iconColors,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '2.0.1',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: Responsive.isMobileSmall(context)
                                    ? 13
                                    : Responsive.isMobileMedium(context) ||
                                            Responsive.isMobileLarge(context)
                                        ? 15
                                        : Responsive.isTabletPortrait(context)
                                            ? 18
                                            : 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });
  
  }
}