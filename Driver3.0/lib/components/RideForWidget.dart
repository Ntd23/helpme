import 'package:flutter/material.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/app_common.dart';

class Rideforwidget extends StatelessWidget {
  String name,contact;
  Rideforwidget({super.key,required this.name,required this.contact});

  @override
  Widget build(BuildContext context) {
    return Container(
      // padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(top: 0),
      // decoration: BoxDecoration(
      //   color: Colors.white,
      //   boxShadow: [
      //     BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1),
      //   ],
      //   borderRadius: BorderRadius.circular(defaultRadius),
      // ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${language.ridingPerson}', style: secondaryTextStyle(size: 14)),
                // SizedBox(height: 4),
                // Divider(color: Colors.grey.shade300,thickness: 0.7,height: 4,endIndent: 10,),
                Text('${name.validate().capitalizeFirstLetter()}', style: boldTextStyle()),
              ],
            ),
          ),
          inkWellWidget(
            onTap: () {
              launchUrl(Uri.parse('tel:${contact}'), mode: LaunchMode.externalApplication);
            },
            child: chatCallWidget(Icons.call),
          ),
        ],
      ),
    );
    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1),
        ],
        borderRadius: BorderRadius.circular(defaultRadius),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${language.rideFor}', style: boldTextStyle(size: 14)),
                // SizedBox(height: 4),
                Divider(color: Colors.grey.shade300,thickness: 0.7,height: 4,endIndent: 10,),
                Text('${name}', style: secondaryTextStyle()),
              ],
            ),
          ),
          inkWellWidget(
            onTap: () {
              launchUrl(Uri.parse('tel:${contact}'), mode: LaunchMode.externalApplication);
            },
            child: chatCallWidget(Icons.call),
          ),
        ],
      ),
    );
  }
}
