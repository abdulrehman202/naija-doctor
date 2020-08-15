import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'LoginController.dart';

class ChatController {
  final _firestore = Firestore.instance;

  ChatController() {
//    user = LoginController().getCurrentUser();
  }

  addZero(var temp)
  {
    if(temp<10)
    {
      temp = '0${temp}';
    }

    return temp;
  }

  Future<void> sendMessage(String Message, String receiverUID, String type) async {
    LoginController controller = new LoginController();
    FirebaseUser user = await controller.getCurrentUser();

    var day,month,year,hour,minute,am_pm = 'am';

    day = addZero(DateTime.now().day);
    month = addZero(DateTime.now().month);
    year = DateTime.now().year % 2000;
    minute = addZero(DateTime.now().minute);
    hour = DateTime.now().hour;

    if(hour>12)
    {
      hour = hour % 12;
      am_pm = 'pm';
    }

    hour = addZero(hour);

    print(user.uid);
    print(receiverUID);
    _firestore
        .collection('chat')
        .document(user.uid.toString())
        .collection(receiverUID)
        .add({
      'text': Message,
      'senderID': user.email,
      'type': type,
      'time': '${day}/${month}/${year} ${hour}:${minute} ${am_pm}',
      'time_stamp':Timestamp.now(),
    });

    _firestore
        .collection('chat')
        .document(receiverUID)
        .collection(user.uid)
        .add({
      'text': Message,
      'senderID': user.email,
      'type': type,
      'time': '${day}/${month}/${year} ${hour}:${minute} ${am_pm}',
      'time_stamp':Timestamp.now(),
    });
  }
  Future<void> deleteActiveCall(String receiverUID, String type) async {
    LoginController controller = new LoginController();
    FirebaseUser user = await controller.getCurrentUser();

    QuerySnapshot value = await Firestore.instance
        .collection('chat')
        .document(user.uid.toString())
        .collection(receiverUID)
        .where('type',isEqualTo: type)
        .getDocuments();

    for (DocumentSnapshot element in value.documents)
    {
      await Firestore.instance
          .collection('chat')
          .document(user.uid.toString())
          .collection(receiverUID)
          .document(element.documentID).delete();
    }

    QuerySnapshot value1 = await Firestore.instance
        .collection('chat')
        .document(receiverUID)
        .collection(user.uid.toString())
        .where('type',isEqualTo: type)
        .getDocuments();

    for (DocumentSnapshot element in value1.documents)
    {
      await Firestore.instance
          .collection('chat')
          .document(receiverUID)
          .collection(user.uid.toString())
          .document(element.documentID).delete();
    }
  }
  Future<void> sendImage(File file, String receiverUID) async {
    LoginController controller = new LoginController();
    FirebaseUser user = await controller.getCurrentUser();

    StorageReference storageReference = FirebaseStorage.instance.ref().child(
        '${user.uid}/${receiverUID}/${DateTime.now().toIso8601String()}');
    StorageUploadTask uploadTask = storageReference.putFile(file);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      sendMessage(
          downloadUrl,
          receiverUID,
          'image');
    },
    );
 }
  Future<bool> isAnyCall(String receiverUID,String type)async {
    LoginController controller = new LoginController();
    FirebaseUser user = await controller.getCurrentUser();

    QuerySnapshot value = await Firestore.instance
        .collection('chat')
        .document(user.uid.toString())
        .collection(receiverUID)
        .where('type',isEqualTo: type)
        .getDocuments();

    if(value.documents.length>0)
    {
      return true;
    }

    return false;
  }
}
