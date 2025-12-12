import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:taxi_driver/main.dart';
import 'package:taxi_driver/screens/DetailScreen.dart';
import 'package:taxi_driver/screens/DashboardScreen.dart';
import 'package:taxi_driver/utils/Extensions/StringExtensions.dart';
import '../Services/RideService.dart';
import '../components/RideForWidget.dart';
import '../model/CurrentRequestModel.dart';
import '../network/RestApis.dart';
import '../utils/Colors.dart';
import '../utils/Common.dart';
import '../utils/Constants.dart';
import '../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_common.dart';
import '../utils/Extensions/app_textfield.dart';

class ReviewScreen extends StatefulWidget {
  final int rideId;
  final CurrentRequestModel currentData;

  ReviewScreen({required this.rideId, required this.currentData});

  @override
  ReviewScreenState createState() => ReviewScreenState();
}

class ReviewScreenState extends State<ReviewScreen> {
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController reviewController = TextEditingController();

  num rattingData = 0;
  Payment? paymentData;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {}

  Future<void> userReviewData() async {
    if (formKey.currentState!.validate()) {
      hideKeyboard(context);
      if (rattingData == 0) return toast(language.pleaseSelectRating);
      formKey.currentState!.save();
      hideKeyboard(context);
      appStore.setLoading(true);
      Map req = {
        "ride_request_id": widget.rideId,
        "rating": rattingData,
        "comment": reviewController.text.trim(),
      };
      await ratingReview(request: req).then((value) {
        getRiderCheck();
        appStore.setLoading(false);
      }).catchError((error) {
        appStore.setLoading(false);
        log(error.toString());
      });
    }
  }

  // Future<void> userSkipReviewData() async {
  //   hideKeyboard(context);
  //   appStore.setLoading(true);
  //   Map req = {
  //     "ride_request_id": widget.rideId,
  //     "rating": 0,
  //     "comment": "",
  //   };
  //   await ratingReview(request: req).then((value) {
  //     getRiderCheck();
  //     appStore.setLoading(false);
  //   }).catchError((error) {
  //     appStore.setLoading(false);
  //     log(error.toString());
  //   });
  // }

  Future<void> getRiderCheck() async {
    appStore.setLoading(false);
    await rideDetail(rideId: widget.rideId).then((value) {
      RideService rideService = RideService();
      rideService.updateStatusOfRide(rideID:  widget.rideId,req: {'on_rider_stream_api_call': 0});
      if (value.payment != null && value.payment!.paymentStatus == PENDING) {
        launchScreen(context, DetailScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      } else {
        launchScreen(context, DashboardScreen(), pageRouteAnimation: PageRouteAnimation.Slide, isNewTask: true);
      }
    }).catchError((error) {
      appStore.setLoading(false);

      toast(error.toString());
    });
  }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(language.riderReview,maxLines: 1, style: boldTextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 16),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text('${language.howWasYourRide}', style: boldTextStyle()),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(35),
                        child: commonCachedNetworkImage(widget.currentData.rider!.profileImage.validate(), fit: BoxFit.fill, height: 70, width: 70),
                      ),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // SizedBox(height: 8),
                          Text('${widget.currentData.rider!.firstName.validate().capitalizeFirstLetter()} ${widget.currentData.rider!.lastName.validate().capitalizeFirstLetter()}', style: boldTextStyle()),
                          Text(widget.currentData.rider!.email.validate(), style: secondaryTextStyle()),
                        ],
                      ),
                    ],
                  ),
                  if(widget.currentData.onRideRequest!=null && widget.currentData.onRideRequest!.otherRiderData!=null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Rideforwidget(name:widget.currentData.onRideRequest!.otherRiderData!.name.validate(),contact:widget.currentData.onRideRequest!.otherRiderData!.conatctNumber.validate()),
                    ),
                  // Container(
                  //   padding: EdgeInsets.all(8),
                  //   margin: EdgeInsets.only(top: 16),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     boxShadow: [
                  //       BoxShadow(color: Colors.black.withOpacity(0.2), spreadRadius: 1),
                  //     ],
                  //     borderRadius: BorderRadius.circular(defaultRadius),
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     mainAxisSize: MainAxisSize.max,
                  //     crossAxisAlignment: CrossAxisAlignment.center,
                  //     children: [
                  //       Expanded(
                  //         child: Column(
                  //           crossAxisAlignment: CrossAxisAlignment.start,
                  //           children: [
                  //             Text('${language.rideFor}', style: boldTextStyle(size: 14)),
                  //             // SizedBox(height: 4),
                  //             Divider(color: Colors.grey.shade300,thickness: 0.7,height: 4,),
                  //             Text('${widget.currentData.onRideRequest!.otherRiderData!.name.validate()}', style: secondaryTextStyle()),
                  //           ],
                  //         ),
                  //       ),
                  //       // inkWellWidget(
                  //       //   onTap: () {
                  //       //     launchUrl(Uri.parse('tel:${widget.currentData.onRideRequest!.otherRiderData!.conatctNumber}'), mode: LaunchMode.externalApplication);
                  //       //     // if (servicesListData!.isRideForOther == 1) {
                  //       //     //   launchUrl(Uri.parse('tel:${servicesListData!.otherRiderData!.conatctNumber}'), mode: LaunchMode.externalApplication);
                  //       //     // } else {
                  //       //     //   launchUrl(Uri.parse('tel:${servicesListData!.riderContactNumber}'), mode: LaunchMode.externalApplication);
                  //       //     // }
                  //       //   },
                  //       //   child: chatCallWidget(Icons.call),
                  //       // ),
                  //     ],
                  //   ),
                  // ),
                  SizedBox(height: 16),
                  RatingBar.builder(
                    direction: Axis.horizontal,
                    glow: false,
                    allowHalfRating: false,
                    wrapAlignment: WrapAlignment.spaceBetween,
                    itemCount: 5,
                    itemPadding: EdgeInsets.symmetric(horizontal: 8),
                    itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                    onRatingUpdate: (rating) {
                      rattingData = rating;
                    },
                  ),
                  SizedBox(height: 16),
                  Text(language.addReviews, style: boldTextStyle(color: primaryColor)),
                  SizedBox(height: 16),
                  AppTextField(
                    controller: reviewController,
                    decoration: inputDecoration(context, label: language.writeYourComments),
                    textFieldType: TextFieldType.NAME,
                    textInputAction: TextInputAction.done,
                    minLines: 2,
                    maxLines: 5,
                  ),
                  SizedBox(height: 16),
                  AppButtonWidget(
                    text: language.submit,
                    width: MediaQuery.of(context).size.width,
                    onTap: () {
                      userReviewData();
                    },
                  ),
                  SizedBox(height: 8),
                  // AppButtonWidget(
                  //   text: language.skip,
                  //   width: MediaQuery.of(context).size.width,
                  //   // child: Text("skip"),
                  //   color: Colors.white,
                  //   textColor: primaryColor,
                  //   shapeBorder: RoundedRectangleBorder(side: BorderSide(color: primaryColor),borderRadius: BorderRadius.circular(defaultRadius)),
                  //   onTap: () {
                  //     userSkipReviewData();
                  //   },
                  // ),

                ],
              ),
            ),
          ),
          Observer(builder: (context) {
            return Visibility(
              visible: appStore.isLoading,
              child: loaderWidget(),
            );
          })
        ],
      ),
    );
  }
}
