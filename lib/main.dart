import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vcheck_face_recognition_app/screens/home/home_page.dart';

List<CameraDescription> cameras = <CameraDescription>[];

Future<void> clearAppCache() async {
  try {
    // Clear external cache
    final tempDir = await getTemporaryDirectory();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }

    // Clear external storage files
    final appDir = await getApplicationDocumentsDirectory();
    if (appDir.existsSync()) {
      appDir.deleteSync(recursive: true);
    }

    // 3️⃣ Clear application support directory (extra stored files)
    final supportDir = await getApplicationSupportDirectory();
    if (supportDir.existsSync()) {
      supportDir.deleteSync(recursive: true);
    }
    print("Cache Cleared!");
  } catch (e) {
    print("Error clearing cache: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await clearAppCache(); // Ensures old cache is cleared before launching app

  cameras = await availableCameras();

  Map<Permission, PermissionStatus> permissions = await [
    Permission.camera,
    Permission.location,
  ].request();

  if ((permissions[Permission.camera] == PermissionStatus.granted ||
          permissions[Permission.camera] == PermissionStatus.restricted ||
          permissions[Permission.camera] ==
              PermissionStatus.permanentlyDenied) &&
      (permissions[Permission.location] == PermissionStatus.granted ||
          permissions[Permission.location] == PermissionStatus.restricted ||
          permissions[Permission.location] ==
              PermissionStatus.permanentlyDenied)) {
    // await RunTime.setupCamera();

    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.pink),
        home: MyApp(),
      ),
    );
  } else {
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(primarySwatch: Colors.pink),
        home: NoPermissionGranted(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'vCheck',
       theme: ThemeData(
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage()
    );
  }
}


class NoPermissionGranted extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(50.0), // here the desired height
          child: AppBar(
            title: Text(
              'vCheck',
              style: TextStyle(color: Colors.black),
            ),
            centerTitle: true,
            backgroundColor: Colors.white,
          )),
      body: Container(
        height: MediaQuery.of(context).size.height + 24,
        child: SingleChildScrollView(
          child: new Column(
            children: <Widget>[
              SizedBox(height: 100),
              Text(
                "This application need all asked permissions granted to function properly. So please grant the permission before start it again.",
                style: TextStyle(fontSize: 20.0),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 30),
              SizedBox(
                width: 2250,
                height: 60,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.white)),
                  ),
                  onPressed: () async {
                    Map<Permission, PermissionStatus> permissions = await [
                      Permission.camera,
                      Permission.location,
                    ].request();

                    if ((permissions[Permission.camera] ==
                                PermissionStatus.granted ||
                            permissions[Permission.camera] ==
                                PermissionStatus.restricted ||
                            permissions[Permission.camera] ==
                                PermissionStatus.permanentlyDenied) &&
                        (permissions[Permission.location] ==
                                PermissionStatus.granted ||
                            permissions[Permission.location] ==
                                PermissionStatus.restricted ||
                            permissions[Permission.location] ==
                                PermissionStatus.permanentlyDenied)) {
                      // RunTime.setupCamera();

                      runApp(
                        MaterialApp(
                          theme: ThemeData(primarySwatch: Colors.pink),
                          home: MyApp(),
                        ),
                      );
                    }
                  },
                  label: Text(
                    "Try Permission Again",
                    style: TextStyle(fontSize: 20.0),
                  ),
                  icon: Icon(Icons.security, size: 50.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
