// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:temperaturemonitor/widgets.dart';
import 'dart:convert';

import 'dart:io';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert' show utf8;
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:country_list_pick/country_list_pick.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

//import 'package:vibration/vibration.dart';
bool en_dis;
bool en_dis_A;
bool en_dis_S;
bool en_dis_V;
//bool en_dis = localStorage.getBool("value_C_name");
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
          //use MaterialApp() widget like this
          home: HomeUI() //create new widget class for this 'home' to
          // escape 'No MediaQuery widget found' error
          );
    });
  }
}

class FlutterBlueApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new WillPopScope(
        onWillPop: () async => false,
        child: new Scaffold(
            body: StreamBuilder<BluetoothState>(
                stream: FlutterBlue.instance.state,
                initialData: BluetoothState.unknown,
                builder: (c, snapshot) {
                  final state = snapshot.data;
                  if (state == BluetoothState.on) {
                    //BluetoothDeviceState.disconnected;
                    return FindDevicesScreen();
                  }
                  return BluetoothOffScreen(state: state);
                })));
  }
}

class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key key, this.state}) : super(key: key);

  final BluetoothState state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state.toString().substring(15)}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle1
                  .copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class FindDevicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find Devices'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            FlutterBlue.instance.startScan(timeout: Duration(seconds: 4)),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              StreamBuilder<List<BluetoothDevice>>(
                stream: Stream.periodic(Duration(seconds: 2))
                    .asyncMap((_) => FlutterBlue.instance.connectedDevices),
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map((d) => ListTile(
                            title: Text(d.name),
                            subtitle: Text(d.id.toString()),
                            trailing: StreamBuilder<BluetoothDeviceState>(
                              stream: d.state,
                              initialData: BluetoothDeviceState.disconnected,
                              builder: (c, snapshot) {
                                if (snapshot.data ==
                                    BluetoothDeviceState.connected) {}
                                return Text(snapshot.data.toString());
                              },
                            ),
                          ))
                      .toList(),
                ),
              ),
              StreamBuilder<List<ScanResult>>(
                stream: FlutterBlue.instance.scanResults,
                initialData: [],
                builder: (c, snapshot) => Column(
                  children: snapshot.data
                      .map(
                        (r) => ScanResultTile(
                          result: r,
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute(builder: (context) {
                            r.device.connect();
                            return SensorPage(device: r.device);
                          })),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBlue.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data) {
            return FloatingActionButton(
              child: Icon(Icons.stop),
              onPressed: () => FlutterBlue.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: Icon(Icons.search),
                onPressed: () => FlutterBlue.instance
                    .startScan(timeout: Duration(seconds: 4)));
          }
        },
      ),
    );
  }
}

class HomeUI extends StatefulWidget {
  final double temperature;
  final double humidity;
  const HomeUI({Key key, this.temperature, this.humidity}) : super(key: key);
  @override
  _HomeUIState createState() => _HomeUIState();
}

bool connected = false;
var title_val;

class _HomeUIState extends State<HomeUI> {
  //final SensorPageState s_p = new SensorPageState();
  var playing = 0;
  var playing_ios = 0;
  var stop_pressed = 0;
  bool _isVisible = false;
  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    //print("Running Test ....");
    localStorage = await SharedPreferences.getInstance();
    if (localStorage != null) {
      //print("Local storage not null future 1");
      //print(en_dis);
      setState(() {
        en_dis = localStorage.getBool("value_C_name");
        en_dis_A = localStorage.getBool("alarm_switch_val");
        en_dis_S = localStorage.getBool("sound_switch_val");
        en_dis_V = localStorage.getBool("vibration_switch_val");
        custom_App_name.text = localStorage.getString("custom_App_name");
        title_val = localStorage.getString("custom_App_name");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //init();

    print("en_dis_A");
    print(en_dis_A);
    print("en_dis_S");
    print(en_dis_S);
    print("en_dis_V");
    print(en_dis_V);
    //print('object 1');
    if (Platform.isIOS) {
      if (widget.temperature != null &&
          widget.temperature >= 37.7 &&
          stop_pressed == 0) {
        IosSounds.electronic;
        //Vibration.vibrate();
        if (playing_ios == 0) {
          _isVisible = true;
          playing_ios = 1;
        }
        //print('object 2');
        // playing = 1;
      } else if (widget.temperature != null &&
          widget.temperature < 37.7 &&
          stop_pressed == 0) {
        FlutterRingtonePlayer.stop();
        //print('object 3');
        // playing = 0;
        playing_ios = 0;
        stop_pressed = 0;
        _isVisible = false;
      }
    } else if (Platform.isAndroid) {
      if (widget.temperature != null &&
          widget.temperature >= 37.7 &&
          stop_pressed == 0 &&
          en_dis_A == true) {
        if (playing == 0 && en_dis_S == true) {
          FlutterRingtonePlayer.playAlarm();
          playing = 1;
        }
        if (Vibration.hasVibrator() != null && en_dis_V == true) {
          Vibration.vibrate();
        }
        if (playing_ios == 0) {
          _isVisible = true;
          playing_ios = 1;
        }
        //print('object 2');
      } else if (widget.temperature != null && widget.temperature < 37.7) {
        FlutterRingtonePlayer.stop();

        //print('object 3');
        playing = 0;
        playing_ios = 0;
        stop_pressed = 0;
        Vibration.cancel();
        _isVisible = false;
      }
    }
    return new WillPopScope(
      // print("ssss");
      onWillPop: () async => false,
      child: new Scaffold(
        appBar: AppBar(
            title: (en_dis == false || en_dis == null) //title_val
                ? Text('Float Thermometer')
                : Text(title_val),
            // title: Text(title_val),
            centerTitle: true,
            automaticallyImplyLeading: false),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(
            bottom: 5,
          ),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(5.w, 6.h),
                    textStyle: TextStyle(
                        fontSize: 15.sp,
                        decorationThickness: 80,
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()),
                    );
                  },
                  child: const Text('Register'),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(150, 50),
                  textStyle: TextStyle(
                      fontSize: 15.sp,
                      decorationThickness: 80,
                      fontWeight: FontWeight.bold),
                ),
                child: connected ? Text("Disconnect") : Text("Connect"),
                onPressed: () {
                  setState(() {});
                  if (connected == true) {
                    //connect = false;
                    //print(connected);
                    Navigator.of(context).pop();
                  } else {
                    //connect = true;
                    // print(connected);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => (FlutterBlueApp())),
                    );
                  }
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(5.w, 6.h),
                  textStyle: TextStyle(
                      fontSize: 15.sp,
                      decorationThickness: 80,
                      fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingPage()),
                  );
                },
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
        body: Center(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 2.h),
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        "Status : ",
                        style: TextStyle(color: Colors.blue, fontSize: 20.sp),
                      ),
                      Text(
                        (widget.temperature == null)
                            ? 'No device'
                            : (widget.temperature < 32.2)
                                ? 'Too Cool'
                                : (widget.temperature >= 32.2 &&
                                        widget.temperature <= 37.7)
                                    ? 'Just Right'
                                    : 'Too Hot',
                        style: TextStyle(
                          color: (widget.temperature == null)
                              ? HexColor('#4FC3F7')
                              : (widget.temperature < 32.2)
                                  ? HexColor('#4FC3F7')
                                  : (widget.temperature >= 32.2 &&
                                          widget.temperature <= 37.7)
                                      ? HexColor('#6DA100')
                                      : HexColor('#f22222'),
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 1.h),
                child: Container(
                  width: double.infinity,
                  child: Column(
                    children: [
                      SleekCircularSlider(
                        appearance: CircularSliderAppearance(
                            customWidths: CustomSliderWidths(
                                trackWidth: 4,
                                progressBarWidth: 5,
                                shadowWidth: 10),
                            customColors: CustomSliderColors(
                                trackColor: (widget.temperature == null)
                                    ? HexColor('#4FC3F7')
                                    : (widget.temperature < 32.2)
                                        ? HexColor('#4FC3F7')
                                        : (widget.temperature >= 32.2 &&
                                                widget.temperature <= 37.7)
                                            ? HexColor('#6DA100')
                                            : HexColor('#f22222'),
                                progressBarColor: (widget.temperature == null)
                                    ? HexColor('#4FC3F7')
                                    : (widget.temperature < 32.2)
                                        ? HexColor('#4FC3F7')
                                        : (widget.temperature >= 32.2 &&
                                                widget.temperature <= 37.7)
                                            ? HexColor('#6DA100')
                                            : HexColor('#f22222'),
                                shadowColor: HexColor('#ffb74d'),
                                shadowMaxOpacity: 0.5, //);
                                shadowStep: 20),
                            infoProperties: InfoProperties(
                                bottomLabelStyle: TextStyle(
                                    color: HexColor('#4FC3F7'),
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600),
                                bottomLabelText: 'Temperature',
                                mainLabelStyle: TextStyle(
                                    color: (widget.temperature == null)
                                        ? HexColor('#4FC3F7')
                                        : (widget.temperature < 32.2)
                                            ? HexColor('#4FC3F7')
                                            : (widget.temperature >= 32.2 &&
                                                    widget.temperature <= 37.7)
                                                ? HexColor('#6DA100')
                                                : HexColor('#f22222'),
                                    fontSize: 30.sp,
                                    fontWeight: FontWeight.w600),
                                modifier: (double value) {
                                  if (selectedRadio == 1 &&
                                      '${widget.temperature}' != 'null') {
                                    return '${widget.temperature.toStringAsFixed(1)} ˚C';
                                  } else if (selectedRadio == 2 &&
                                      '${widget.temperature}' != 'null') {
                                    return '${((widget.temperature) * (9 / 5) + 32).toStringAsFixed(1)} ˚F';
                                  }
                                  return ' No device \n connected';
                                }),
                            startAngle: 90,
                            angleRange: 360,
                            size: 35.h,
                            animationEnabled: true),
                        min: 0,
                        max: (selectedRadio == 1) ? 100 : 212,
                        initialValue: (widget.temperature == null
                            ? 0
                            : widget.temperature),
                      ),
                      SizedBox(
                        height: 3.h,
                      ),
                      Visibility(
                        visible: _isVisible,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: Size(5.w, 6.h),
                            textStyle: TextStyle(
                                fontSize: 15.sp,
                                decorationThickness: 80,
                                fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            FlutterRingtonePlayer.stop();
                            Vibration.cancel();
                            stop_pressed = 1;
                            _isVisible = false;
                          },
                          child: const Text('Stop Alarm'),
                        ),
                      ),
                      SizedBox(
                        height: 3.h,
                      ),
                      SleekCircularSlider(
                        appearance: CircularSliderAppearance(
                            customWidths: CustomSliderWidths(
                                trackWidth: 4,
                                progressBarWidth: 2,
                                shadowWidth: 10),
                            customColors: CustomSliderColors(
                                trackColor: (widget.humidity == null)
                                    ? HexColor('#f22222')
                                    : (widget.humidity >= 0 &&
                                            widget.humidity <= 40)
                                        ? HexColor('#f22222')
                                        : (widget.humidity >= 40 &&
                                                widget.humidity <= 75)
                                            ? HexColor('#ffd500')
                                            : HexColor('#6DA100'),
                                progressBarColor: (widget.humidity == null)
                                    ? HexColor('#f22222')
                                    : (widget.humidity >= 0 &&
                                            widget.humidity <= 40)
                                        ? HexColor('#f22222')
                                        : (widget.humidity >= 40 &&
                                                widget.humidity <= 75)
                                            ? HexColor('#ffff00')
                                            : HexColor('#6DA100'),
                                shadowColor: HexColor('#ffb74d'),
                                /*(widget.humidity == null)
                                    ? HexColor('#f22222')
                                    : (widget.humidity >= 0 &&
                                            widget.humidity <= 40)
                                        ? HexColor('#f22222')
                                        : (widget.humidity >= 40 &&
                                                widget.humidity <= 75)
                                            ? HexColor('#ffd500')
                                            : HexColor('#6DA100'),*/
                                shadowMaxOpacity: 0.5, //);
                                shadowStep: 20),
                            infoProperties: InfoProperties(
                                bottomLabelStyle: TextStyle(
                                    color: HexColor('#4FC3F7'),
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w600),
                                bottomLabelText: 'Battery',
                                mainLabelStyle: TextStyle(
                                    color: HexColor('#54826D'),
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.w600),
                                modifier: (double value) {
                                  if ('${widget.temperature}' != 'null') {
                                    return '${widget.humidity} %';
                                  }
                                  return '0 %';
                                }),
                            startAngle: 90,
                            angleRange: 360,
                            size: 23.h,
                            animationEnabled: true),
                        min: 0,
                        max: 100,
                        initialValue:
                            (widget.humidity == null ? 0 : widget.humidity),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Create a Form widget.
class MyCustomForm extends StatefulWidget {
  const MyCustomForm({Key key}) : super(key: key);

  @override
  MyCustomFormState createState() {
    return MyCustomFormState();
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class MyCustomFormState extends State<MyCustomForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  String c_name = 'United States';
  final _formKey = GlobalKey<FormState>();
  final controllerFirstName = TextEditingController();
  final controllerLastName = TextEditingController();
  final controllerEmail = TextEditingController();
  final controllerState = TextEditingController();
  final controllerCountry = TextEditingController();
  final controllerHowdis = TextEditingController();
  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        //alignment: AlignmentDirectional.center,
        children: [
          const SizedBox(height: 14),
          TextFormField(
            controller: controllerFirstName,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                labelText: 'First Name'),
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter First Name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controllerLastName,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                labelText: 'Last Name'),
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Last Name';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controllerEmail,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                labelText: 'Email'),
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter Email';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controllerState,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                labelText: 'State'),
            // The validator receives the text that the user has entered.
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter State';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          CountryListPick(
            appBar: AppBar(
              backgroundColor: Colors.amber,
              title: Text('Pick your country'),
            ),
            theme: CountryTheme(
              isShowFlag: true,
              isShowTitle: true,
              isShowCode: false,
              isDownIcon: true,
              showEnglishName: false,
              labelColor: Colors.blueAccent,
            ),
            initialSelection: 'US',
            onChanged: (CountryCode code) {
              this.setState(() {
                c_name = code.name;
              });
              // print(code.name);
              // print("c_name");
              //print(c_name);

              //print(code.code);
              //print(code.dialCode);
              //print(code.flagUri);
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: controllerHowdis,
            decoration: InputDecoration(
                contentPadding: EdgeInsets.fromLTRB(5, 5, 0, 0),
                labelText: 'How discovered Project?'),
            // The validator receives the text that the user has entered.
          ),
          Expanded(
            child: Align(
              alignment: FractionalOffset.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(bottom: 0),

                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(175, 50),
                    textStyle: TextStyle(fontSize: 20),
                  ),
                  child: Text('Register'),
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      sendEmail();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Registered Successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
                // Your elements here
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future sendEmail({
    String f_name = '',
    String l_name = '',
    String in_email = '',
    String m_number = '',
    String state_in = '',
    String country_u = '',
    String how_dis = '',
    String email = 'octathorndemo@gmail.com',
  }) async {
    f_name = controllerFirstName.text;

    if (f_name == null || f_name.isEmpty) {
      return null;
    }

    l_name = controllerLastName.text;
    in_email = controllerEmail.text;
    state_in = controllerState.text;
    country_u = c_name;

    how_dis = controllerHowdis.text;
    final serviceId = 'service_8v8ew55';
    final templateId = 'template_4lwoqyt';
    final userId = 'user_txD20oqKhmKNTXSh7X5Nm';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': userId,
        'template_params': {
          'user_email': email,
          // 'to_email': 'other.email@gmail.com',
          'user_firstname': f_name,
          'user_lastname': l_name,
          'user_inemail': in_email,
          'user_state': state_in,
          'user_country': country_u,
          'discovered': how_dis,
        },
      }),
    );

    //print(response.body);
  }

  Widget buildTextField({
    //String title,
    TextEditingController controller,
    int maxLines = 1,
    bool vale = true,
    String labelText,
  }) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: vale,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: labelText,
            ),
          ),
        ],
      );
}

Widget buildTextField({
  //String title,
  TextEditingController controller,
  int maxLines = 1,
  bool vale2 = true,
  String labelText,
}) =>
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        TextFormField(
          enabled: vale2,
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            border: UnderlineInputBorder(),
            labelText: labelText,
          ),
        ),
      ],
    );

class HexColor extends Color {
  static int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));
}

class RegisterPage extends StatelessWidget {
  final controllerFirstName = TextEditingController();
  final controllerLastName = TextEditingController();
  final controllerEmail = TextEditingController();
  final controllerState = TextEditingController();
  final controllerCountry = TextEditingController();
  final controllerHowdis = TextEditingController();

  String lableName = "First Name";

  RegisterPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text("Registeration Page"),
          backgroundColor: Colors.blueAccent,
          centerTitle: true,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(
            bottom: 5,
          ),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[],
          ),
        ),
        body: MyCustomForm(),
      );
}

class SettingPage extends StatelessWidget {
  const SettingPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        elevation: 0.0,
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: Size(5.w, 5.h),
                textStyle: TextStyle(
                    fontSize: 15.sp,
                    decorationThickness: 80,
                    fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => About_us()),
                );
              },
              child: const Text('About Us'),
            ),
          ],
        ),
      ),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text("App Customization"),
        centerTitle: true,
      ),
      body: Column(
        children: [MyStatefulWidget()],
      ),
    );
  }
}

class About_us extends StatelessWidget {
  const About_us({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
          elevation: 0.0,
          color: Colors.transparent,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text("Powered by  "),
            Text("OCTATHORN",
                style: const TextStyle(fontWeight: FontWeight.bold))
          ])),
      appBar: AppBar(
        centerTitle: true,
        title: const Text('About Us'),
      ),
      body: Center(
        child: const Text('Open route'),
      ),
    );
  }
}

class MyStatefulWidget extends StatefulWidget {
  const MyStatefulWidget({Key key}) : super(key: key);

  @override
  State<MyStatefulWidget> createState() => MyStatefulWidgetState();
}

final custom_App_name = TextEditingController();
int selectedRadio = 1;
SharedPreferences localStorage;

class MyStatefulWidgetState extends State<MyStatefulWidget> {
  bool value_C_name;
  bool alarm_switch_val;
  bool sound_switch_val;
  bool vibration_switch_val;

  void intiState() {
    super.initState();
  }

  setSelectedRadio(int val) {
    setState(() {
      selectedRadio = val;
    });
  }

  int check = 0;

  Future init() async {
    //print("Running Test ....");
    localStorage = await SharedPreferences.getInstance();
    if (localStorage != null && check == 0) {
      check = 1;
      //print("Local storage not null futre 2");
      setState(() {
        if (localStorage.getString("selectedRadio") != null) {
          selectedRadio = int.tryParse(localStorage.getString("selectedRadio"));
        }
        value_C_name = localStorage.getBool("value_C_name");
        alarm_switch_val = localStorage.getBool("alarm_switch_val");
        sound_switch_val = localStorage.getBool("sound_switch_val");
        vibration_switch_val = localStorage.getBool("vibration_switch_val");
        //print("In Init");
        en_dis = localStorage.getBool("value_C_name");
        en_dis_A = localStorage.getBool("alarm_switch_val");
        en_dis_S = localStorage.getBool("sound_switch_val");
        en_dis_V = localStorage.getBool("vibration_switch_val");
        custom_App_name.text = localStorage.getString("custom_App_name");
        //print("value_C_name");
        //print(custom_App_name.text);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    init();
    if (en_dis == null) {
      setState(() {
        en_dis = false;
        value_C_name = false;
      });
    }
    if (en_dis_A == null) {
      setState(() {
        en_dis_A = false;
        alarm_switch_val = true;
        print("en_dis null");
      });
    }
    if (en_dis_S == null) {
      setState(() {
        en_dis_S = false;
        sound_switch_val = true;
      });
    }
    if (en_dis_V == null) {
      setState(() {
        en_dis_V = false;
        vibration_switch_val = true;
      });
    }
    if (value_C_name == null) {
      setState(() {
        //en_dis = false;
        value_C_name = false;
      });
    }
    if (en_dis == false) {
      setState(() {});
    }
    if (alarm_switch_val == null) {
      setState(() {
        alarm_switch_val = true;
        print("alarm_switch_val null");
      });
    }
    if (sound_switch_val == null) {
      setState(() {
        sound_switch_val = true;
      });
    }
    if (vibration_switch_val == null) {
      setState(() {
        vibration_switch_val = true;
      });
    }
    print("After If");
    print("alarm_switch_val");
    print(alarm_switch_val);
    return Column(
      children: <Widget>[
        const SizedBox(height: 20),
        Column(
          children: <Widget>[
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: EdgeInsets.all(15),
                child: Text(
                  'Temperature Display',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
        RadioListTile(
          title: const Text('Degree Celsius: ° C'),
          value: 1,
          groupValue: selectedRadio,
          onChanged: (val) {
            setState(() {
              setSelectedRadio(val);
            });
            //await UserSimplePreferences.setTempunit(selectedRadio);
            localStorage.setString("selectedRadio", selectedRadio.toString());
            //print("\value radio");
            //print(localStorage.getString("selectedRadio"));
          },
        ),
        RadioListTile(
          title: const Text('Degree Fahrenheit: ° F'),
          value: 2,
          groupValue: selectedRadio,
          onChanged: (val) {
            setState(() {
              setSelectedRadio(val);
            });
            //await UserSimplePreferences.setTempunit(selectedRadio);
            localStorage.setString("selectedRadio", selectedRadio.toString());
            //print("\value radio");
            //print(localStorage.getString("selectedRadio"));
          },
        ),
        const Divider(
          color: Colors.black,
          height: 25,
          thickness: 0.5,
          //indent: 5,
          //endIndent: 5,
        ),
        SwitchListTile(
          title: const Text(
            'Custom App Name',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            textAlign: TextAlign.left,
          ),
          value: value_C_name,
          onChanged: (bool value) {
            if (en_dis == null) {
              setState(() {
                en_dis = false;
                title_val = "Float Temperature";
              });
              //print("if true null");
            }

            if (en_dis == false) {
              setState(() {
                en_dis = true;
                title_val = custom_App_name.text;
                //print(title_val);
              });
              //print("if true false");
            } else if (en_dis == true && custom_App_name.text.isNotEmpty) {
              setState(() {
                en_dis = true;
                title_val = "Float Temperature";
              });
              Widget cancelButton = TextButton(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              );
              if (custom_App_name.text.isNotEmpty) {
                value = true;
                //print("is not empty");
                AlertDialog alert = AlertDialog(
                  title: Text("Error"),
                  content: Text("Please clear the Text feild"),
                  actions: [
                    cancelButton,
                  ],
                );
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return alert;
                  },
                );
              } else {
                value = false;
              }
              //print("if true true");
              //print(title_val);
            } else if (en_dis == true && custom_App_name.text.isEmpty) {
              setState(() {
                en_dis = false;
                title_val = "Float Temperature";
              });
            }

            setState(() {
              value_C_name = value;
            });
            //  print("value");
            // print(value);
            //print("en_dis");
            // print(en_dis);
            localStorage.setBool("value_C_name", value);
            //localStorage.setString("custom_App_name", custom_App_name.text);
          },
        ),
        TextFormField(
          controller: custom_App_name,
          enabled: en_dis,
          onChanged: (value) {
            setState(() {
              title_val = custom_App_name.text;
            });
            //await UserSimplePreferences.setTempunit(selectedRadio);
            localStorage.setString("custom_App_name", value);
            //print("\value custom_App_name");
            //print(localStorage.getString("custom_App_name"));
          },

          decoration: InputDecoration(
            contentPadding: EdgeInsets.fromLTRB(5, 5, 0, 0),
          ),
          // The validator receives the text that the user has entered.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter Last Name';
            }
            return null;
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: EdgeInsets.all(15),
            child: Text(
              'Notifications',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ),
        ),
        SwitchListTile(
          title: const Text('High Temperature Alarm'),
          value: alarm_switch_val,
          onChanged: (bool value) {
            if (en_dis_A == null) {
              en_dis_A = true;
            }
            if (en_dis_A == true) {
              en_dis_A = false;
            } else if (en_dis_A == false) {
              en_dis_A = true;
            }
            setState(() {
              alarm_switch_val = value;
            });
            localStorage.setBool("alarm_switch_val", value);
          },
          secondary: const Icon(Icons.alarm),
        ),
        SwitchListTile(
          title: const Text('Sound'),
          value: sound_switch_val,
          onChanged: (bool value) {
            if (en_dis_S == null) {
              en_dis_S = true;
            }
            if (en_dis_S == true) {
              en_dis_S = false;
            } else if (en_dis_S == false) {
              en_dis_S = true;
            }
            setState(() {
              sound_switch_val = value;
            });
            localStorage.setBool("sound_switch_val", value);
          },
          secondary: const Icon(Icons.ring_volume_outlined),
        ),
        SwitchListTile(
          title: const Text('Vibration'),
          value: vibration_switch_val,
          onChanged: (bool value) {
            if (en_dis_V == null) {
              en_dis_V = true;
            }
            if (en_dis_V == true) {
              en_dis_V = false;
            } else if (en_dis_V == false) {
              en_dis_V = true;
            }
            setState(() {
              vibration_switch_val = value;
            });
            localStorage.setBool("vibration_switch_val", value);
          },
          secondary: const Icon(Icons.vibration),
        ),
      ],
    );
  }
}

class SensorPage extends StatefulWidget {
  const SensorPage({Key key, this.device}) : super(key: key);
  final BluetoothDevice device;

  @override
  SensorPageState createState() => SensorPageState();
}

class SensorPageState extends State<SensorPage> {
  String service_uuid = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  String charaCteristic_uuid = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  bool isReady;
  Stream<List<int>> stream;
  List _temphumidata;
  double _temp = 0;
  double _humidity = 0;
  @override
  void initState() {
    super.initState();
    isReady = false;
    connectToDevice();
  }

  void dispose() {
    widget.device.disconnect();
    super.dispose();
  }

  connectToDevice() async {
    if (widget.device == null) {
      _pop();
      return;
    }

    new Timer(const Duration(seconds: 15), () {
      if (!isReady) {
        disconnectFromDevice();
        _pop();
      }
    });

    await widget.device.connect();
    connected = true;
    discoverServices();
  }

  disconnectFromDevice() {
    if (widget.device == null) {
      _pop();

      return;
    }

    widget.device.disconnect();
    connected = false;
  }

  discoverServices() async {
    if (widget.device == null) {
      _pop();
      return;
    }

    List<BluetoothService> services = await widget.device.discoverServices();
    services.forEach((service) {
      if (service.uuid.toString() == service_uuid) {
        service.characteristics.forEach((characteristic) {
          if (characteristic.uuid.toString() == charaCteristic_uuid) {
            characteristic.setNotifyValue(!characteristic.isNotifying);
            stream = characteristic.value;

            setState(() {
              isReady = true;
            });
          }
        });
      }
    });

    if (!isReady) {
      _pop();
    }
  }
  /*
  Future<bool> onWillPop() {
    return showDialog(
        context: context,
        builder: (context) =>
            new AlertDialog(
              title: Text('Are you sure?'),
              content: Text('Do you want to disconnect device and go back?'),
              actions: <Widget>[
                new ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => (HomeUI())),
                      );
                    },
                    child: new Text('No')),
                new ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => (FlutterBlueApp())),
                      );
                    },
                    child: new Text('Yes')),
              ],
            ) ??
            false);
  }
  */

  _pop() {
    Navigator.of(context).pop(true);
  }

  String _dataParser(List<int> dataFromDevice) {
    return utf8.decode(dataFromDevice);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async => true,
        child: new Scaffold(
            body: Container(
                child: !isReady
                    ? Center(
                        child: Text(
                          "Waiting...",
                          style: TextStyle(fontSize: 24, color: Colors.red),
                        ),
                      )
                    : Container(
                        child: StreamBuilder<List<int>>(
                          stream: stream,
                          builder: (BuildContext context,
                              AsyncSnapshot<List<int>> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              // geting data from bluetooth
                              var currentValue = _dataParser(snapshot.data);
                              // print("Current Value");
                              // print(currentValue);
                              if (currentValue == null || currentValue == "") {
                                //print("Hello 234");
                              } else {
                                _temphumidata = currentValue.split(",");
                                if (_temphumidata[0] != "nan" ||
                                    _temphumidata[0] != null) {
                                  _temp = double.parse(_temphumidata[0]);
                                } else {
                                  _temphumidata[0] = 0.0;
                                }
                                if (_temphumidata[0] != "nan" ||
                                    _temphumidata[1] != null) {
                                  _humidity = double.parse(_temphumidata[1]);
                                } else {
                                  _temphumidata[1] = 0.0;
                                }
                              }
                              //connect = false;
                              return HomeUI(
                                humidity: _humidity,
                                temperature: _temp,
                              );
                            } else {
                              return Text('Check the stream');
                            }
                          },
                        ),
                      ))));
    //);
  }
}
