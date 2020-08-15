import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:doctorapp/Controllers/ChatController.dart';
import 'package:doctorapp/src/utils/settings.dart';
import 'package:flutter/material.dart';

var receiver_name,receiver_photo;

class VoiceCallPage extends StatefulWidget {

  /// non-modifiable channel name of the page
  final String channelName;

  /// non-modifiable client role of the page
  final ClientRole role;

  final name,photo;

  /// Creates a call page with given channel name.
  VoiceCallPage({Key key, this.channelName, this.role,this.name,this.photo}) : super(key: key)
  {
    receiver_name = name;
    receiver_photo = photo;
  }

  @override
  _VoiceCallPageState createState()=> _VoiceCallPageState();
}

class _VoiceCallPageState extends State<VoiceCallPage> {
  static final _users = <int>[];
  final _infoStrings = <String>[];
  bool muted = false;
  Timer _timmerInstance;
  int _start = 0;
  String _timmer = '';

  void startTimmer() {
    var oneSec = Duration(seconds: 1);
    _timmerInstance = Timer.periodic(
        oneSec,
            (Timer timer) => setState(() {
          if (_start < 0) {
            _timmerInstance.cancel();
          } else {
            _start = _start + 1;
            _timmer = getTimerTime(_start);
          }
        }));
  }


  String getTimerTime(int start) {
    int minutes = (start ~/ 60);
    String sMinute = '';
    if (minutes.toString().length == 1) {
      sMinute = '0' + minutes.toString();
    } else
      sMinute = minutes.toString();

    int seconds = (start % 60);
    String sSeconds = '';
    if (seconds.toString().length == 1) {
      sSeconds = '0' + seconds.toString();
    } else
      sSeconds = seconds.toString();

    return sMinute + ':' + sSeconds;
  }

  @override
  void initState() {
    super.initState();
    // initialize agora sdk
    initialize();
    startTimmer();
  }

  @override
  void dispose() {

    // clear users
    _users.clear();
    // destroy sdk
    AgoraRtcEngine.leaveChannel();
    AgoraRtcEngine.destroy();
    _timmerInstance.cancel();
    super.dispose();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }
    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await AgoraRtcEngine.enableWebSdkInteroperability(true);
    await AgoraRtcEngine.joinChannel(null, widget.channelName, null, 0);
  }

  Future<void> _initAgoraRtcEngine() async {
    await AgoraRtcEngine.create(APP_ID);
    await AgoraRtcEngine.enableAudio();
    await AgoraRtcEngine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await AgoraRtcEngine.setClientRole(widget.role);
  }

  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onError = (dynamic code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    };
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          padding: EdgeInsets.all(50.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                height: 10.0,
              ),
              Text(
                'VOICE CALL',
                style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w300,
                    fontSize: 15),
              ),
              SizedBox(
                height: 20.0,
              ),
              Text(
                receiver_name,
                style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 20),
              ),
              SizedBox(
                height: 20.0,
              ),
              Text(
                _timmer,
                style: TextStyle(
                    color: Colors.deepPurpleAccent,
                    fontWeight: FontWeight.w300,
                    fontSize: 15),
              ),
              SizedBox(
                height: 20.0,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(200.0),
                child: Image.network(
                  receiver_photo.toString(),
                  height: 200.0,
                  width: 200.0,
                ),
              ),
              SizedBox(
                height: 50.0,
              ),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  FunctionalButton(
                    title: 'End Call',
                    icon:  Icons.call_end,
                    iconColor: Colors.red,
                    onPressed: ()
                    {
                      ChatController().deleteActiveCall(widget.channelName, 'audiocall');
                      Navigator.pop(context);
                    },

                  ),
                  FunctionalButton(
                    title: 'Mute',
                    iconColor: Colors.deepPurpleAccent,
                    icon:  muted ? Icons.mic_off : Icons.mic,
                    onPressed: ()
                    {
                      setState(() {
                        muted = !muted;
                      });
                      AgoraRtcEngine.muteLocalAudioStream(muted);
                    },
                  ),
                ],
              ),
              SizedBox(
                height: 120.0,
              ),

            ],
          ),
        ),
      ),
    );
  }
}

class FunctionalButton extends StatefulWidget {
  final title;
  final icon;
  final iconColor;
  final Function() onPressed;

  const FunctionalButton({Key key, this.title, this.icon, this.onPressed, this.iconColor})
      : super(key: key);

  @override
  _FunctionalButtonState createState() => _FunctionalButtonState();
}

class _FunctionalButtonState extends State<FunctionalButton> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        RawMaterialButton(
          onPressed: widget.onPressed,
          splashColor: Colors.deepPurpleAccent,
          fillColor: Colors.white,
          elevation: 10.0,
          shape: CircleBorder(),
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Icon(
              widget.icon,
              size: 30.0,
              color: widget.iconColor,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 2.0),
          child: Text(
            widget.title,
            style: TextStyle(fontSize: 15.0, color: widget.iconColor),
          ),
        )
      ],
    );
  }
}