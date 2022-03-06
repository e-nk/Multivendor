import 'dart:async';
import 'dart:io';
import 'package:app/src/config.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
//import 'package:path/path.dart' as p;
//import 'package:path_provider/path_provider.dart';
import 'package:scoped_model/scoped_model.dart';
import 'splash/splash.dart';
import 'src/app.dart';
import 'src/data/gallery_options.dart';
import 'src/functions.dart';
import 'src/models/app_state_model.dart';
import 'src/models/snackbar_activity.dart';
import 'src/resources/api_provider.dart';
import 'src/themes/app_theme.dart';
import 'src/ui/intro/intro_slider.dart';

//Directory _appDocsDir;

void setOverrideForDesktop() {
  if (kIsWeb) return;

  if (Platform.isMacOS) {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  } else if (Platform.isLinux || Platform.isWindows) {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
  } else if (Platform.isFuchsia) {
    debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  }
}

void main() async {
  setOverrideForDesktop();
  AppStateModel model = AppStateModel();
  WidgetsFlutterBinding.ensureInitialized();
  //SharedPreferences.setMockInitialValues({});
  await Firebase.initializeApp();
  await model.getLocalData();
  await model.fetchAllBlocks();
  //Uncomment If you want to show splash screen for long time
  //await Future.delayed(Duration(seconds: 5));
  //UnComment when SSL site not working
  HttpOverrides.global = new MyHttpOverrides();
  //UnComment when Using Dynamic Splash
  //_appDocsDir = await getApplicationDocumentsDirectory();

  /// Update the iOS foreground notification presentation options to allow
  /// heads up notifications.
  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final AppStateModel model = AppStateModel();
  MyApp({Key key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final apiProvider = ApiProvider();
  Timer _timer;
  int _start = 0;
  var splashIndex = ['0', '1', '2', '3', '4', '5'];
  final _messangerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    apiProviderInt();
    //Firebase.initializeApp();
    //splashIndex.shuffle();
    //startTimer();
    widget.model.messageStream.listen((event) => _manageMessage(event));
    super.initState();
  }

  File fileFromDocsDir(String filename) {
    //TODO Uncomment when using dynamic splash
    //String pathName = p.join(_appDocsDir.path, filename);
    //return File(pathName);
  }

  void apiProviderInt() async {
    await apiProvider.init();
    await widget.model.fetchAllBlocks();
    setState(() {});
    await widget.model.updateAllBlocks();
    setState(() {});
    //widget.model.getCustomerDetails();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    return ModelBinding(
      initialModel: GalleryOptions(
        themeMode: widget.model.themeMode,
        customTextDirection: CustomTextDirection.localeBased,
        textScaleFactor: 1,
        locale: widget.model.appLocale,
        platform: defaultTargetPlatform,
      ),
      child: Builder(
        builder: (context) {
          return ScopedModel<AppStateModel>(
              model: widget.model,
              child: Builder(
                  builder: (context) {
                    /*if (widget.model.hasSeenIntro == null) {
                      return MaterialApp(
                          debugShowCheckedModeBanner: false,
                          home: IntroScreen(onFinish: () {
                            widget.model.setIntroScreenSeen();
                            widget.model.hasSeenIntro = true;
                            setState(() {});
                          })
                      );
                    } else */if (widget.model.blocks != null && _start == 0) {
                      return MaterialApp(
                          scaffoldMessengerKey: _messangerKey,
                          localizationsDelegates: [
                            GlobalCupertinoLocalizations.delegate,
                            GlobalMaterialLocalizations.delegate,
                            GlobalWidgetsLocalizations.delegate,
                          ],
                          supportedLocales: GalleryOptions.supportedLocales,
                          locale: GalleryOptions.of(context).locale,
                          title: Config().appName,
                          debugShowCheckedModeBanner: false,
                          themeMode: GalleryOptions.of(context).themeMode,
                          theme: widget.model.blocks.blockTheme.light.copyWith(
                            platform: GalleryOptions.of(context).platform,
                          ),
                          /*theme: GalleryOptions.of(context).locale == Locale('ar')
                              ? GalleryThemeData.lightArabicThemeData(context, widget.model.blocks.theme).copyWith(
                            platform: GalleryOptions.of(context).platform,
                          ) : GalleryThemeData.lightThemeData(context, widget.model.blocks.theme).copyWith(
                            platform: GalleryOptions.of(context).platform,
                          ),*/
                          darkTheme: GalleryOptions.of(context).locale == Locale('ar')
                              ? GalleryThemeData.darkArabicThemeData.copyWith(
                            platform: GalleryOptions.of(context).platform,
                          ) : GalleryThemeData.darkThemeData(context, widget.model.blocks.theme).copyWith(
                            platform: GalleryOptions.of(context).platform,
                          ),
                          home: App()
                      );
                    } else {
                      return MaterialApp(
                        debugShowCheckedModeBanner: false,
                        theme: ThemeData(primaryColor: Colors.white, appBarTheme: AppBarTheme(elevation: 0)),
                        darkTheme: ThemeData(primaryColor: Colors.white, appBarTheme: AppBarTheme(elevation: 0)),
                        home: Material(
                            child: Builder(
                              builder: (context) {
                                return Scaffold(
                                  body: AnnotatedRegion<SystemUiOverlayStyle>(
                                    value: SystemUiOverlayStyle.dark,
                                    child: Center(
                                        child: Container(
                                            child: Image.asset('assets/images/splash.png', fit: BoxFit.contain))
                                    ),
                                  ),
                                );
                              }
                            )
                        ),
                      );
                      //For dinamic splash not used because issues in pathprovider in recent flutter update
                      return Material(
                        child: Stack(
                          children: [
                            Container(
                                height: MediaQuery.of(context).size.height,
                                child: Image(
                                    fit: BoxFit.fitHeight,
                                    image: NetworkToFileImage(
                                        url: '',
                                        file: fileFromDocsDir(
                                            "splash" + splashIndex[0] + ".jpg"),
                                        debug: true))),
                            widget.model.blocks != null
                                ? Positioned(
                              top: 20,
                              right: 20,
                              child: FlatButton(
                                child: Text('SKIP 0' + _start.toString()),
                                onPressed: () => cancelTimer(),
                              ),
                            )
                                : Container()
                          ],
                        ),
                      );
                    }
                }
              ));
        },
      ),
    );
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) => setState(
        () {
          if (_start < 1) {
            cancelTimer();
          } else {
            _start = _start - 1;
          }
        },
      ),
    );
  }

  void cancelTimer() {
    _timer.cancel();
    setState(() {
      _start = 0;
    });
  }

  _manageMessage(SnackBarActivity event) {
    if(event.show) {
      final snackBar = SnackBar(
          duration: event.duration,
          backgroundColor: event.success ? Colors.green :  Colors.red,
          content: Wrap(
            children: [
              Container(
                child: Text(
                  parseHtmlString(event.message),
                  maxLines: 6,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              event.loading ? Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16, 0),
                child: Container(
                    height: 20,
                    width: 20,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2))
                ),
              ) : Container(),
            ],
          ));
      _messangerKey.currentState.showSnackBar(snackBar);
    } else {
      _messangerKey.currentState.hideCurrentSnackBar();
    }
  }
}

class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}
