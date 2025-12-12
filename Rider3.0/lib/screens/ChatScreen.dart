import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:paginate_firestore/paginate_firestore.dart';
import 'package:taxi_booking/screens/DashBoardScreen.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';
import '../model/LoginResponse.dart';
import '../utils/Common.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../../main.dart';
import '../../service/ChatMessagesService.dart';
import '../../utils/Colors.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/app_common.dart';
import '../model/ChatMessageModel.dart';
import '../model/FileModel.dart';
import '../components/ChatItemWidget.dart';

class ChatScreen extends StatefulWidget {
  final UserModel? userData;
  final int ride_id;
  final bool? show_history;
  ChatScreen({this.userData, required this.ride_id,this.show_history});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String id = '';
  var messageCont = TextEditingController();
  var messageFocus = FocusNode();
  bool isMe = false;

  @override
  void initState() {
    super.initState();
    if(widget.show_history==true){
      chatMessageService = ChatMessageService();
    }else{
      init();
    }
  }

  UserModel sender = UserModel(
    username: sharedPref.getString(USER_NAME),
    profileImage: sharedPref.getString(USER_PROFILE_PHOTO),
    uid: sharedPref.getString(UID),
    playerId: sharedPref.getString(PLAYER_ID),
  );

  init() async {
    id = sharedPref.getString(UID)!;

    chatMessageService = ChatMessageService();
    chatMessageService.setUnReadStatusToTrue(senderId: sender.uid!, receiverId: widget.userData!.uid.validate());
    setState(() {});
  }


  @override
  void dispose() {
    try{
      chatMessageService.setUnReadStatusToTrue(senderId: sender.uid!, receiverId: widget.userData!.uid.validate());
    }catch(e){

    }
    super.dispose();
  }

  sendMessage({FilePickerResult? result}) async {
    if (result == null) {
      if (messageCont.text.trim().isEmpty) {
        messageFocus.requestFocus();
        return;
      }
    }
    ChatMessageModel data = ChatMessageModel();
    data.receiverId = widget.userData!.uid;
    data.senderId = sender.uid;
    data.message = messageCont.text;
    data.isMessageRead = false;
    data.msg_topic = widget.ride_id.toString();
    data.createdAt = DateTime.now().millisecondsSinceEpoch;

    if (widget.userData!.uid == sharedPref.getString(UID)) {
      //
    }
    if (result != null) {
      if (result.files.single.path!.isNotEmpty) {
        data.messageType = MessageType.IMAGE.name;
      } else {
        data.messageType = MessageType.TEXT.name;
      }
    } else {
      data.messageType = MessageType.TEXT.name;
    }
    String f_name=sharedPref.getString(FIRST_NAME)??'';
    String l_name=sharedPref.getString(LAST_NAME)??'';
    notificationService.sendPushNotifications(f_name==''?
    sharedPref.getString(USER_NAME)!:f_name+" $l_name", messageCont.text, receiverPlayerId: widget.userData!.playerId).catchError(log);
    messageCont.clear();
    setState(() {});
    return await chatMessageService.addMessage(data).then((value) async {
      if (result != null) {
        FileModel fileModel = FileModel();
        fileModel.id = value.id;
        fileModel.file = File(result.files.single.path!);
        fileList.add(fileModel);

        setState(() {});
      }

      await chatMessageService.addMessageToDb(value, data, sender, widget.userData, image: result != null ? File(result.files.single.path!) : null).then((value) {
        //
      });

      userService.fireStore
          .collection(USER_COLLECTION)
          .doc(sharedPref.getInt(USER_ID).toString())
          .collection(CONTACT_COLLECTION)
          .doc(widget.userData!.uid)
          .update({'lastMessageTime': DateTime.now().millisecondsSinceEpoch}).catchError((e) {
        log(e);
      });
      userService.fireStore
          .collection(USER_COLLECTION)
          .doc(widget.userData!.uid)
          .collection(CONTACT_COLLECTION)
          .doc(sharedPref.getInt(USER_ID).toString())
          .update({'lastMessageTime': DateTime.now().millisecondsSinceEpoch}).catchError((e) {
        log(e);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async{
        if(Navigator.canPop(context)){
          return true;
        }else{
          launchScreen(getContext, DashBoardScreen(),isNewTask: true);
          return  false;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              GestureDetector(
                onTap: () {
                  if(Navigator.canPop(context)){
                    Navigator.pop(context);
                  }else{
                    launchScreen(getContext, DashBoardScreen(),isNewTask: true);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Icon(Icons.arrow_back, color: Colors.white),
                ),
              ),
              SizedBox(width: 10),
              if(widget.show_history!=true)
              ClipRRect(
                  borderRadius: BorderRadius.all(radiusCircular(20)),
                  child: commonCachedNetworkImage(widget.userData!.profileImage.validate(),fit: BoxFit.cover,height: 40,width: 40)),
              // CircleAvatar(backgroundImage: NetworkImage(widget.userData!.profileImage.validate()), minRadius: 20),
              SizedBox(width: 10),
              if(widget.show_history!=true)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(widget.userData!.firstName.validate().capitalizeFirstLetter()+" ${widget.userData!.lastName.validate()}", style: TextStyle(color: Colors.white)),
              ),
              if(widget.show_history==true)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("Ride #${widget.ride_id} Messages", style: boldTextStyle(color: Colors.white)),
                ),
            ],
          ),
          backgroundColor: primaryColor,
        ),
        body: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Stack(
            children: [
              Container(
                padding: EdgeInsets.only(bottom: widget.show_history==true?20:76),
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: PaginateFirestore(
                  reverse: true,
                  isLive: true,
                  padding: EdgeInsets.only(left: 8, top: 8, right: 8, bottom: 0),
                  physics: BouncingScrollPhysics(),
                  query: widget.show_history==true?chatMessageService.rideSpecificChatMessagesWithPagination(rideId: widget.ride_id.toString()):chatMessageService.chatMessagesWithPagination(currentUserId: sharedPref.getString(UID), receiverUserId: widget.userData!.uid.validate(),filter_msg:widget.ride_id),
                  itemsPerPage: PER_PAGE_CHAT_COUNT,
                  shrinkWrap: true,
                  onEmpty: Offstage(),
                  itemBuilderType: PaginateBuilderType.listView,
                  itemBuilder: (context, snap, index) {
                    ChatMessageModel data = ChatMessageModel.fromJson(snap[index].data() as Map<String, dynamic>);
                    data.isMe = data.senderId == sender.uid;
                    // if(data.isMessageRead==false && data.isMe!=true){
                    //   //   here set message is read
                    //   try{
                    //     chatMessageService.setSingleMessageRead(senderId: sender.uid!, receiverId: widget.userData!.uid!,chatId: data.id!);
                    //   }catch(e){
                    //
                    //   }
                    // }
                    return ChatItemWidget(data: data);
                  },
                ),
              ),
              if(widget.show_history!=true)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Visibility(
                  visible: widget.show_history==true?false:true,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: radius(),
                      color: Theme.of(context).cardColor,
                      boxShadow: [
                        BoxShadow(
                          spreadRadius: 0.5,
                          blurRadius: 0.5,
                        ),
                      ],
                    ),
                    padding: EdgeInsets.only(left: 8, right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageCont,
                            decoration: InputDecoration(
                              focusColor: primaryColor,
                              border: InputBorder.none,
                              hintText: language.writeMessage,
                              hintStyle: secondaryTextStyle(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                            cursorColor: appStore.isDarkMode ? Colors.white : Colors.black,
                            focusNode: messageFocus,
                            textCapitalization: TextCapitalization.sentences,
                            keyboardType: TextInputType.multiline,
                            minLines: 1,
                            style: primaryTextStyle(),
                            textInputAction: mIsEnterKey ? TextInputAction.send : TextInputAction.newline,
                            onSubmitted: (s) {
                              sendMessage();
                            },
                            cursorHeight: 20,
                            maxLines: 5,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.send, color: primaryColor),
                          onPressed: () {
                            sendMessage();
                          },
                        )
                      ],
                    ),
                    width: MediaQuery.of(context).size.width,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
