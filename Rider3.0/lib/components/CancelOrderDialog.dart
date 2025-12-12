// import 'package:flutter/material.dart';
// import 'package:flutter_mobx/flutter_mobx.dart';
// import '../utils/Colors.dart';
// import '../utils/Common.dart';
// import '../utils/Extensions/StringExtensions.dart';
// import '../../main.dart';
// import '../utils/DataProvider.dart';
// import '../utils/Extensions/AppButtonWidget.dart';
// import '../utils/Extensions/LiveStream.dart';
// import '../utils/Extensions/app_common.dart';
// import '../utils/Extensions/app_textfield.dart';
//
// class CancelOrderDialog extends StatefulWidget {
//   static String tag = '/CancelOrderDialog';
//
//   final Function(String)? onCancel;
//
//   CancelOrderDialog({this.onCancel});
//
//   @override
//   CancelOrderDialogState createState() => CancelOrderDialogState();
// }
//
// class CancelOrderDialogState extends State<CancelOrderDialog> {
//   GlobalKey<FormState> formKey = GlobalKey<FormState>();
//
//   TextEditingController reasonController = TextEditingController();
//   String? reason;
//
//   List<String> cancelReasonList = getCancelReasonList();
//
//   @override
//   void initState() {
//     super.initState();
//     init();
//   }
//
//   Future<void> init() async {
//     LiveStream().on('UpdateLanguage', (p0) {
//       cancelReasonList.clear();
//       cancelReasonList.addAll(getCancelReasonList());
//       setState(() {});
//     });
//   }
//
//   @override
//   void setState(fn) {
//     if (mounted) super.setState(fn);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       content: Form(
//         key: formKey,
//         child: Stack(
//           children: [
//             Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(language.cancelRide, style: boldTextStyle(size: 18)),
//                     InkWell(
//                       onTap: () {
//                         Navigator.pop(context);
//                       },
//                       child: Icon(Icons.clear),
//                     ),
//                   ],
//                 ),
//                 SizedBox(height: 16),
//                 DropdownButtonFormField<String>(
//                   value: reason,
//                   isExpanded: true,
//                   decoration: inputDecoration(context, label: language.selectReason,alignWithHint: false),
//                   items: cancelReasonList.map((e) {
//                     return DropdownMenuItem(
//                       alignment: Alignment.topLeft,
//                       value: e,
//                       child: Text(e),
//                     );
//                   }).toList(),
//                   onChanged: (String? val) {
//                     reason = val;
//                     setState(() {});
//                   },
//                   validator: (value) {
//                     if (value == null) return language.thisFieldRequired;
//                     return null;
//                   }
//                 ),
//                 SizedBox(height: 16),
//                 if (reason.validate().trim() == language.others)
//                   AppTextField(
//                     controller: reasonController,
//                     textFieldType: TextFieldType.OTHER,
//                     decoration: inputDecoration(context, label: language.writeReasonHere),
//                     maxLines: 3,
//                     minLines: 3,
//                     validator: (value) {
//                       if (value!.isEmpty) return language.thisFieldRequired;
//                       return null;
//                     },
//                   ),
//                 SizedBox(height: 16),
//                 Align(
//                   alignment: Alignment.centerRight,
//                   child: AppButtonWidget(
//                     onTap: () {
//                       if (formKey.currentState!.validate()) {
//                         widget.onCancel?.call(reason!.validate().trim() != language.others ? reason.validate() : reasonController.text);
//                       }
//                     },
//                     text: language.submit,
//                     color: primaryColor,
//                     textStyle: boldTextStyle(color: Colors.white),
//                     width: MediaQuery.of(context).size.width,
//                   ),
//                 )
//               ],
//             ),
//             Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../../main.dart';
import '../utils/DataProvider.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/LiveStream.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';

class CancelOrderDialog extends StatefulWidget {
  static String tag = '/CancelOrderDialog';

  final Function(String)? onCancel;

  CancelOrderDialog({this.onCancel});

  @override
  CancelOrderDialogState createState() => CancelOrderDialogState();
}

class CancelOrderDialogState extends State<CancelOrderDialog> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController reasonController = TextEditingController();
  String? reason;
  int selectedReason=0;
  List<String> cancelReasonList = getCancelReasonList();
  late FocusNode myFocusNode;
  @override
  void initState() {
    myFocusNode=FocusNode();
    super.initState();
    init();
  }


  @override
  void dispose() {
    myFocusNode.dispose();
    super.dispose();
  }

  Future<void> init() async {
    LiveStream().on('UpdateLanguage', (p0) {
      cancelReasonList.clear();
      cancelReasonList.addAll(getCancelReasonList());
      setState(() {});
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: [
        Padding(
          padding:EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: SizedBox(
            // height: context.height()/2,
            child: Padding(
              padding: const EdgeInsets.only(left: 0,right: 0,top: 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(language.cancelRide, style: boldTextStyle(size: 18)),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.clear),
                        ),
                      ],
                    ),
                  ),
                  SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    // padding: EdgeInsets.only(top: 16),
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for(int i=0;i<cancelReasonList.length;i++)
                            RadioListTile(value:i, groupValue: selectedReason, onChanged: (value) {
                              selectedReason=value??-1;
                              if (selectedReason!=-1 && cancelReasonList[selectedReason]==language.others){
                                myFocusNode.requestFocus();
                              }
                              setState(() {});
                            },title: Text(cancelReasonList[i]),activeColor: primaryColor,contentPadding: EdgeInsets.zero,visualDensity: VisualDensity(
                              vertical: VisualDensity.minimumDensity,
                              horizontal: VisualDensity.minimumDensity
                            ),materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,),

                          // DropdownButtonFormField<String>(
                          //       value: reason,
                          //       isExpanded: true,
                          //       decoration: inputDecoration(context, label: "language.selectReason"),
                          //       items: cancelReasonList.map((e) {
                          //         return DropdownMenuItem(
                          //           alignment: Alignment.topLeft,
                          //           value: e,
                          //           child: Text(e),
                          //         );
                          //       }).toList(),
                          //       onChanged: (String? val) {
                          //         reason = val;
                          //         setState(() {});
                          //       },
                          //       validator: (value) {
                          //         if (value == null) return language.thisFieldRequired;
                          //         return null;
                          //       }
                          //   ),
                          //   SizedBox(height: 16),
                          if (selectedReason!=-1 && cancelReasonList[selectedReason]==language.others)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: AppTextField(
                                focus: myFocusNode,
                                controller: reasonController,
                                textFieldType: TextFieldType.OTHER,
                                maxLength: 1000,
                                decoration: inputDecoration(context, label: language.writeReasonHere),
                                maxLines: 3,
                                minLines: 3,
                                validator: (value) {
                                  if (value!.isEmpty) return language.thisFieldRequired;
                                  return null;
                                },
                              ),
                            ),
                          if (selectedReason!=-1 && cancelReasonList[selectedReason]==language.others)
                            SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: AppButtonWidget(
                        onTap: () {
                          if (formKey.currentState!.validate()) {
                            widget.onCancel?.call(selectedReason!=-1 && cancelReasonList[selectedReason]!=language.others? cancelReasonList[selectedReason].validate() : reasonController.text);
                            // widget.onCancel?.call(reason!.validate().trim() != "Other" ? reason.validate() : reasonController.text);
                          }
                        },
                        text: language.submit,
                        color: primaryColor,
                        textStyle: boldTextStyle(color: Colors.white),
                        width: MediaQuery.of(context).size.width,
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
    return AlertDialog(
      content: Form(
        key: formKey,
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(language.cancel, style: boldTextStyle(size: 18)),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.clear),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                    value: reason,
                    isExpanded: true,
                    decoration: inputDecoration(context, label: "language.selectReason"),
                    items: cancelReasonList.map((e) {
                      return DropdownMenuItem(
                        alignment: Alignment.topLeft,
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                    onChanged: (String? val) {
                      reason = val;
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null) return language.thisFieldRequired;
                      return null;
                    }
                ),
                SizedBox(height: 16),
                if (reason.validate().trim() == "Other")
                  AppTextField(
                    controller: reasonController,
                    textFieldType: TextFieldType.OTHER,
                    decoration: inputDecoration(context, label: "write reason here"),
                    maxLines: 3,
                    minLines: 3,
                    validator: (value) {
                      if (value!.isEmpty) return language.thisFieldRequired;
                      return null;
                    },
                  ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButtonWidget(
                    onTap: () {
                      if (formKey.currentState!.validate()) {
                        widget.onCancel?.call(reason!.validate().trim() != "Other" ? reason.validate() : reasonController.text);
                      }
                    },
                    text: language.submit,
                    color: primaryColor,
                    textStyle: boldTextStyle(color: Colors.white),
                    width: MediaQuery.of(context).size.width,
                  ),
                )
              ],
            ),
            Observer(builder: (context) => Visibility(visible: appStore.isLoading, child: Positioned.fill(child: loaderWidget()))),
          ],
        ),
      ),
    );
  }
}
