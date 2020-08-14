import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:doctorapp/Controllers/LoginController.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:doctorapp/main.dart';
import 'package:emoji_picker/emoji_picker.dart';
import 'package:doctorapp/WColors.dart';
import 'package:doctorapp/Controllers/ChatController.dart';
import 'package:image_picker/image_picker.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:doctorapp/src/pages/call.dart';
import 'package:doctorapp/src/pages/full_photo.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'Classes/DoctorAppointments.dart';
import 'Controllers/ChatController.dart';
import 'src/pages/audio_call.dart';

DoctorAppointments apt;
bool receive;

Future<void> getUID()
async {

  LoginController controller = new LoginController();
  FirebaseUser user=await controller.getCurrentUser();
  uid = user.uid;
  uemail=user.email;
}
String receiver,uid,uemail,receiver_name,receiver_pic;
var channel_id;

class ChatScreen extends StatelessWidget {

  ChatScreen(String rid,String name,String picURL)
  {
    receiver = rid;
    getUID();
    receiver_name = name;
    receiver_pic = picURL;
    channel_id = TextEditingController();
    receive = false;
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(

      theme: ThemeData(
        primaryColor: Color(0xFF4E45FF),
        accentColor: Color(0xFF4E45FF),
      ),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        //'/signup': (BuildContext context) => new SignupPage(),
      },
      home: new ChatScreenPage(),

    );
  }
}

class ChatScreenPage extends StatefulWidget {

  @override
  _ChatScreenPageState createState() => new _ChatScreenPageState();
}

class _ChatScreenPageState extends State<ChatScreenPage> {


  /// if channel textField is validated to have error
  bool _validateError = false;
  ClientRole _role = ClientRole.Broadcaster;
  MediaQueryData queryData;
  WColors myColors;
  var msgController = new TextEditingController();
  Category category;
  OnEmojiSelected onEmojiSelected;


//  @override
//  void dispose() {
//    channel_id.dispose();
//    super.dispose();
//  }
//
//  @override
//  void initState() {
//    super.initState();
//  }


  @override
  Widget build(BuildContext context) {

    queryData = MediaQuery.of(context);
    myColors = new WColors();
    var widthD = queryData.size.width;
    var heightD = queryData.size.height;

    return new  Scaffold(

            appBar: AppBar(
              leading: IconButton(
                icon: Icon(Icons.keyboard_backspace),
                onPressed: ()
                {
                  Navigator.pop(context);
                },
              ),
              title: Row(
                children: <Widget>[
                  /*GestureDetector(
                child: Container(
                  child: Icon(Icons.arrow_back, color: myColors.appBarIcons),
                  alignment: Alignment.topLeft,
                  width: 40,
                ),
                onTap: () {
                  _navigateToBackScreen(context);
                },
              ),*/
                  GestureDetector(
                    child: ClipOval(
                      //borderRadius: BorderRadius.circular(100.0),
                      child: Image.network(
                        receiver_pic,
                        width: 40,
                        height: 40,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),

                  Flexible(
                    child: Container(
                      margin: EdgeInsets.only(left: 10),
                      child: Text(
                        receiver_name,
                        style: TextStyle(
                          fontFamily: 'Oxygen',
                          fontSize: 19,
                          color: myColors.appBarIcons,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ),

                ],
              ),
              automaticallyImplyLeading: true,
              actions: <Widget>[
                IconButton(
                  icon: Icon(
                    Icons.phone,
                    size: 24,
                  ),
                  color: myColors.appBarIcons,
                  onPressed: _joinAudioCall,
                ),
                IconButton(
                  icon: Icon(
                    Icons.videocam,
                    size: 24,
                  ),
                  color: myColors.appBarIcons,
                  onPressed:_joinVideoCall,
//
//                    !receive ? ChatController().sendMessage(uid, receiver, 'videocall'): {},

//                    onJoin();
//                  }
                ),
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: 24,
                  ),
                  color: myColors.appBarIcons,
//                  onPressed:,
//                  onJoin,
                ),
              ],
            ),
            resizeToAvoidBottomPadding: false,
            backgroundColor: const Color(0xffffffff),
            body:
              Transform.translate(
                offset: Offset(0.0,-1*MediaQuery.of(context).viewInsets.bottom),
                child: SafeArea(
                  child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    MessageStream(),
                    BottomAppBar(
                        color: Color(0xfffffffc),
                        child: Container(
                          margin: EdgeInsets.fromLTRB(0, 10, 0, 10),
                          child: Row(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.fromLTRB(7, 0, 0, 2),
                                padding: EdgeInsets.all(0),
                                width: 30.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.attach_file,
                                    size: 22,
                                  ),
                                  color: myColors.bottomBarIcons,
                                  onPressed: () async {
                                    print('attach');
                                    List<File> files = await FilePicker.getMultiFile(
                                      type: FileType.custom,
                                      allowedExtensions: [ 'pdf', 'doc'],
                                    ).then((value) {} );
                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(0),
                                width: 30.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.image,
                                    size: 22,
                                  ),
                                  color: myColors.bottomBarIcons,
                                  onPressed: () async {
                                    await ImagePicker.pickImage(source: ImageSource.gallery).then((image) {
                                      setState(() {
                                        ChatController().sendImage(image, receiver);
                                      });
                                    });
                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(0),
                                width: 30.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    size: 22,
                                  ),
                                  color: myColors.bottomBarIcons,
                                  onPressed: () async {
                                    await ImagePicker.pickImage(source: ImageSource.camera).then((image) {
                                      setState(() {
                                        ChatController().sendImage(image, receiver);
                                      });
                                    });


                                  },
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.all(0),
                                width: 30.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.mic,
                                    size: 24,
                                  ),
                                  color: myColors.bottomBarIcons,
                                  onPressed: (){
                                    print('mic');
                                  },
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  //padding: EdgeInsets.fromLTRB(5, 0, 0, 0),
                                  margin: EdgeInsets.fromLTRB(5, 0, 2, 0),
                                  height: 45,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(38.0),
                                    color: const Color(0xfff7f7f7),
                                    border: Border.all(
                                        width: 0.3, color: const Color(0xff707070)),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      SizedBox(
                                        width: 10,
                                      ),
                                      SizedBox(
                                        width: 175,
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: TextField(
                                            controller: msgController,

                                            style: TextStyle(
                                              fontFamily: 'Oxygen',
                                              fontSize: 15,
                                              color: Colors.black,

                                            ),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hoverColor: Colors.yellow,
                                              hintText: 'Write your message here',
                                              hintStyle: TextStyle(
                                                fontSize: 14,
                                                color: const Color(0xffa0a0a0),

                                              ),
                                            ),
                                            maxLines: null,
                                            keyboardType: TextInputType.text,

                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.fromLTRB(0, 0, 15, 0),
                                padding: EdgeInsets.all(0),
                                width: 20.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.send,
                                    size: 24,
                                  ),
                                  color: myColors.appBar,
                                  onPressed:()
                                  {
                                    sendMessage(msgController.text.toString());
                                    msgController.clear();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Visibility(
                      visible: false,
                      child: TextField(
                        controller: channel_id,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> onJoin() async {
    // update input validation
    setState(()
    {
     receive ? channel_id.text = receiver : channel_id.text = uid;
    }

    );
    if (channel_id.text.isNotEmpty) {
      await _handleCameraAndMic();

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelName: channel_id.text,
            role: _role,
          ),
        ),
      );
     }
    }

  Future<void> onJoinAudioCall() async {

    // update input validation
    setState(() {
      receive ? channel_id.text = receiver : channel_id.text = uid;
    });
    if (channel_id.text.isNotEmpty) {
      // await for camera and mic permissions before pushing video page
      await _handleMic();
      // push video page with given channel name
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VoiceCallPage(
            channelName: channel_id.text,
            role: _role,
            name: receiver_name,
            photo: receiver_pic,
          ),
        ),
      );

      ChatController().deleteActiveCall(receiver, 'audiocall');
    }
  }

  Future<void> _handleCameraAndMic() async {
    await PermissionHandler().requestPermissions(
      [PermissionGroup.camera, PermissionGroup.microphone],
    );
  }

  Future<void> _handleMic() async {
    await PermissionHandler().requestPermissions(
      [ PermissionGroup.microphone],
    );
  }

  void sendMessage(String text)
  {
    ChatController chatController = new ChatController();
    chatController.sendMessage(text,receiver,'text');
  }

  Future<void> _joinVideoCall() async {


    if((await ChatController().isAnyCall(receiver, 'videocall')) == false)
    {
      receive = false;
      ChatController().sendMessage(uid,receiver, 'videocall');
    }

    else
      {
        receive = true;
      }

    onJoin();
    ChatController().deleteActiveCall(receiver, 'videocall');

  }

  void _joinAudioCall() async {

    if((await ChatController().isAnyCall(receiver, 'audiocall')) == false)
    {
    receive = false;
    ChatController().sendMessage(uid,receiver, 'audiocall');
    }

    else
    {
    receive = true;
    }

    onJoinAudioCall();
    ChatController().deleteActiveCall(receiver, 'audiocall');
  }
}

void _navigateToBackScreen(BuildContext context) {
  Navigator.of(context).push(MaterialPageRoute(builder: (context) => Login()));
}

class MessageBubble extends StatelessWidget{

  MessageBubble({this.text, this.isMe,this.isText, this.time});

  var text,time;
  final bool isMe,isText;

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end: CrossAxisAlignment.start,
        children: <Widget>[
          Material(
            borderRadius: isMe ? BorderRadius.only(topLeft: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ) : BorderRadius.only(topRight: Radius.circular(30.0),
              bottomLeft: Radius.circular(30.0),
              bottomRight: Radius.circular(30.0),
            ),
            elevation: 5.0,
            color: isMe ? Color(0xFF4E45FF) : Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 10.0,horizontal: 20.0),
              child: isText
                  ? Text('$text',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black54,
                  fontSize: 15.0,
                ),
              )
                  :  Container(
                child: FlatButton(
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlueAccent),
                        ),
                        width: 200.0,
                        height: 200.0,
                        padding: EdgeInsets.all(70.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(8.0),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Material(
                        child: Image.asset(
                          'images/dr.jpeg',
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      ),
                      imageUrl: text,
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  onPressed: () {
                    Navigator.push(
                        context, MaterialPageRoute(builder: (context) => FullPhoto(url: text)));
                  },
                  padding: EdgeInsets.all(0),
                ),
//                margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
              )
            ),
          ),
          Text(time.toString()),
        ],
      ),
      );
  }
}

class MessageStream extends StatelessWidget{

  MessageStream();

  @override
  Widget build(BuildContext context) {

    // TODO: implement build
    return StreamBuilder<QuerySnapshot>(

      stream: Firestore.instance
          .collection('chat')
          .document(uid.toString())
          .collection(receiver.toString())
          .orderBy('time_stamp')
          .snapshots(),
      builder: (context,snapshot){
        if(snapshot.hasData)
        {
          final messages = snapshot.data.documents.reversed;
          List<MessageBubble> messageWidgets = [];
          for(var message in  messages)
          {
            final msgText = message.data['text'];
            final msgSender = message.data['senderID'];
            final msgType = message.data['type'];
            final msgTime = message.data['time'];

            var msgBubble;

            print('User id: ${uid.toString()}');
            print('Receiver id: ${receiver.toString()}');
            print(msgType.toString());

            channel_id.text = uid;

             if(msgType == 'audiocall' || msgType=='videocall')
            {
              if(msgSender!=uemail)
              {
                Fluttertoast.showToast(
                  msg: "You have an incoming ${msgType}. Tap on ${msgType} icon at top to join",
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.CENTER,
                  timeInSecForIosWeb: 1,
                  textColor: Colors.white,
                  fontSize: 12.0,
                  backgroundColor: Colors.black54,
                );
              }
            }

            else
              {
                msgBubble = MessageBubble(text: msgText, isMe: msgSender == uemail, isText: msgType == 'text',time: msgTime);
                messageWidgets.add(msgBubble);
              }
          }
          return Expanded(
            child: ListView(
              reverse: true,
              children:  messageWidgets,
            ),
          );
        }
        else
        {
          return Center(
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}