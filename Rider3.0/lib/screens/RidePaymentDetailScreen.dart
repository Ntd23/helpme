import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:taxi_booking/utils/Extensions/context_extension.dart';
import '../model/FRideBookingModel.dart';
import '../service/RideService.dart';
import '../utils/Common.dart';
import '../utils/Extensions/StringExtensions.dart';
import '../utils/Extensions/app_common.dart';
import '../../main.dart';
import '../../model/CurrentRequestModel.dart';
import '../../model/OrderHistory.dart';
import '../../model/RiderModel.dart';
import '../../network/RestApis.dart';
import '../../screens/RideHistoryScreen.dart';
import '../../utils/Colors.dart';
import '../../utils/Constants.dart';
import '../../utils/Extensions/AppButtonWidget.dart';
import '../utils/Extensions/app_textfield.dart';
import '../utils/images.dart';
import 'DashBoardScreen.dart';

class RidePaymentDetailScreen extends StatefulWidget {
  final int? rideId;
  //
  RidePaymentDetailScreen({this.rideId});

  @override
  RidePaymentDetailScreenState createState() => RidePaymentDetailScreenState();
}

class RidePaymentDetailScreenState extends State<RidePaymentDetailScreen> {
  List<RideHistory> rideHistory = [];
  RideService rideService = RideService();
  CurrentRequestModel? currentData;
  bool isCashPayment = true;
  bool isShow = false;
  bool currentScreen = true;
  bool navigateDone = false;
  RiderModel? riderModel;
  Payment? paymentData;

  bool isPaymentDone = false;

  TextEditingController tipController = TextEditingController();
  bool isMoreTip = false;
  bool paymentPressed = false;
  int currentIndex = -1;
  bool isTipShow = true;

  @override
  void initState() {
    super.initState();
    init();
  }

  void init() async {
    // appStore.setLoading(true);
    getCurrentRide();
  }

  getCurrentRide() async {
    Future.delayed(Duration.zero,() {
      appStore.setLoading(true);
      getCurrentRideRequest().then((value) async {
        appStore.setLoading(false);
        currentData = value;
        // mqttForUser();
        await orderDetailApi();
        setState(() {});
      }).catchError((error) {
        exportedLog(file_name: "getCurrentRideRequest",logMessage: "ERROR:${error}");
        appStore.setLoading(false);
        throw error;
        log(error.toString());
      });
    },);
  }

  Future<void> savePaymentApi() async {
    if(paymentPressed==true) return;
    paymentPressed=true;
    appStore.setLoading(true);
    Map req = {
      "id": currentData!.payment!.id,
      "rider_id": currentData!.payment!.riderId,
      "ride_request_id": currentData!.payment!.rideRequestId,
      "datetime": DateTime.now().toString(),
      "total_amount": currentData!.payment!.totalAmount!,
      "payment_type": WALLET,
      "txn_id": "",
      "payment_status": PAID,
      "transaction_detail": ""
    };
    await savePayment(req).then((value) async {
      appStore.setLoading(false);
      await rideService.updateStatusOfRide(rideID: currentData!.payment!.rideRequestId, req: {"on_stream_api_call": 0, /*"payment_status": PAID*/});
      // launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
      orderDetailApi();

      // Future.delayed((Duration(seconds: 2))).then((value) async {
      //   await rideService.deleteRide(rideID: currentData!.payment!.rideRequestId);
      // });
    }).catchError((error) {
      isShow = true;
      setState(() {});
      appStore.setLoading(false);
      log(error.toString());
      toast(error.toString());
    });
  }

  Future<void> rideRequest() async {
    appStore.setLoading(true);
    Map req = {
      "payment_type": isCashPayment ? CASH : WALLET,
      "is_change_payment_type": 1,
    };
    log(req);
    await rideRequestUpdate(request: req, rideId: currentData!.payment!.rideRequestId).then((value) async {
      await rideService.updateStatusOfRide(rideID: currentData!.payment!.rideRequestId, req: {/*"tips": 1,*/ "on_stream_api_call": 0,"payment_type":isCashPayment ? CASH : WALLET,});
      appStore.setLoading(false);
      init();
    }).catchError((error) {
      appStore.setLoading(false);
      log(error.toString());
    });
  }

  Future<void> orderDetailApi() async {
    // appStore.setLoading(true);
    await rideDetail(orderId: widget.rideId).then((value) {
      // appStore.setLoading(false);
      riderModel = value.data;
      if (value.payment != null) {
        currentData!.payment=value.payment;
        paymentData = value.payment;
      }
      rideHistory = value.rideHistory!;
      setState(() {});
      if(paymentData!=null && paymentData!.paymentStatus=="paid"){
        isPaymentDone=true;
        // paymentSuccessShown=true;
        if(navigateDone==true) return;
        navigateDone=true;
        Future.delayed(Duration(seconds: 3),() {
          launchScreen(getContext, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
          isPaymentDone=false;
          // setState(() {});
        },);
      }

    }).catchError((error) {
      exportedLog(file_name: "rideDetail",logMessage: "ERROR:${error}");
      throw error;
      toast(error.toString());
      // appStore.setLoading(false);
    });
  }

  // mqttForUser() async {
  //   client.setProtocolV311();
  //   client.logging(on: true);
  //   client.keepAlivePeriod = 120;
  //   client.autoReconnect = true;
  //
  //   try {
  //     await client.connect();
  //   } on NoConnectionException catch (e) {
  //     debugPrint(e.toString());
  //     client.connect();
  //   }
  //
  //   if (client.connectionStatus!.state == MqttConnectionState.connected) {
  //     client.onSubscribed = onSubscribed;
  //
  //     debugPrint('connected');
  //   } else if (client.connectionStatus!.state == MqttConnectionState.disconnected) {
  //     client.connect();
  //     debugPrint('connected');
  //   } else if (client.connectionStatus!.state == MqttConnectionState.disconnecting) {
  //     client.connect();
  //     debugPrint('connected');
  //   } else if (client.connectionStatus!.state == MqttConnectionState.faulted) {
  //     client.connect();
  //     debugPrint('connected');
  //   }
  //
  //   void onconnected() {
  //     debugPrint('connected');
  //   }
  //
  //   client.subscribe(mMQTT_UNIQUE_TOPIC_NAME + 'ride_request_status_' + sharedPref.getInt(USER_ID).toString(), MqttQos.atLeastOnce);
  //
  //   client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
  //     final MqttPublishMessage recMess = c![0].payload as MqttPublishMessage;
  //
  //     final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
  //
  //     if (jsonDecode(pt)['success_type'] == 'payment_status_message') {
  //       setState(() {
  //         isPaymentDone = true;
  //       });
  //       Future.delayed(
  //         Duration(seconds: 5),
  //         () {
  //           setState(() {
  //             isPaymentDone = false;
  //           });
  //           launchScreen(context, DashBoardScreen(), isNewTask: true);
  //         },
  //       );
  //     }
  //   });
  //
  //   client.onConnected = onconnected;
  // }

  // void onConnected() {
  //   log('Connected');
  // }
  //
  // void onSubscribed(String topic) {
  //   log('Subscription confirmed for topic $topic');
  // }

  @override
  void setState(fn) {
    if (mounted) super.setState(fn);
  }

  // Future fetchRide() {
  //   return rideService.fetchRideFuture(rideId: widget.rideId).then((value) async {});
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(language.detailScreen, style: boldTextStyle(color: appTextPrimaryColorWhite)),
      ),
      body: StreamBuilder(
          stream: rideService.fetchRide(rideId: widget.rideId),
          builder: (context, snap) {
            if (snap.hasData) {
              List<FRideBookingModel> data=[];
              try{
                data = snap.data!.docs.map((e) => FRideBookingModel.fromJson(e.data() as Map<String, dynamic>)).toList();
              }catch(e){
                data=[];
              }

              if(data.length==0){
                Future.delayed(
                  Duration(seconds: 2),
                      () {
                    if(currentScreen==false) return;
                    currentScreen=false;
                    orderDetailApi();
                    // if(context!=null){
                    //   launchScreen(context, DashBoardScreen(), isNewTask: true);
                    // }
                  },
                );
              }
              if (data.isNotEmpty && data[0].paymentStatus.toString() == PAID && data[0].status.toString() == COMPLETED) {
                // print("CheckLastBug:${data.isNotEmpty}---${data[0].paymentStatus}--${data[0].status}--==${data[0].toJson()}");
                // rideService.updateStatusOfRide(rideID: widget.rideId, req: {"on_stream_api_call": 0});
                isPaymentDone = true;
                Future.delayed(
                  Duration(seconds: 3),
                  () {
                    isPaymentDone = false;
                    if(currentScreen==false) return;
                    currentScreen=false;
                    // launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
                    // print("Line261");
                    orderDetailApi();
                    // if(context!=null){
                    //   launchScreen(context, DashBoardScreen(), isNewTask: true);
                    // }
                  },
                );

                // Future.delayed((Duration(seconds: 10))).then((value) async {
                //   await rideService.deleteRide(rideID: currentData!.payment!.rideRequestId);
                // });
              }

              return Stack(
                children: [
                  currentData != null
                      ? SingleChildScrollView(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              addressComponent(),
                              SizedBox(height: 12),
                              paymentDetailWidget(),
                              SizedBox(height: 12),
                              priceDetailWidget(),
                              SizedBox(height: 12),
                              if (currentData!.payment != null && currentData!.payment!.paymentStatus != COMPLETED && isShow)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(language.payment, style: boldTextStyle()),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: inkWellWidget(
                                            onTap: () {
                                              isCashPayment = true;
                                              setState(() {});
                                            },
                                            child: scheduleOptionWidget(context, isCashPayment, 'images/ic_cash.png', language.cash),
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: inkWellWidget(
                                            onTap: () {
                                              isCashPayment = false;
                                              setState(() {});
                                            },
                                            child: scheduleOptionWidget(context, !isCashPayment, 'images/ic_credit_card.png', language.wallet),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Center(
                                      child: AppButtonWidget(
                                        text: language.updatePaymentStatus,
                                        textStyle: boldTextStyle(color: Colors.white),
                                        color: primaryColor,
                                        onTap: () {
                                          isShow = false;
                                          rideRequest();
                                        },
                                      ),
                                    )
                                  ],
                                ),
                              SizedBox(height: 8),
                              // if (currentData!.payment != null && data.length>0 && data[0].paymentStatus.toString() != PAID )
                            ],
                          ),
                        )
                      : Observer(builder: (context) {
                          return Visibility(
                            visible: appStore.isLoading,
                            child: loaderWidget(),
                          );
                        }),
                  Visibility(
                      visible: isPaymentDone,
                      child: Center(
                        child: Container(
                            // width: 250,
                            //     height: 200,
                              width: context.width(),
                                margin: EdgeInsets.symmetric(horizontal: 40),
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(defaultRadius),
                                  boxShadow: [
                                    BoxShadow(color: primaryColor.withOpacity(0.4), blurRadius: 10, spreadRadius: 0, offset: Offset(0.0, 0.0)),
                                  ],
                                ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(paymentSuccessful, width: 120, height: 120, fit: BoxFit.contain),
                                Text("${language.paymentSuccess}",style: boldTextStyle(color: Colors.green,size: 24),)
                              ],
                            )),
                          // child: Container(
                          //     width: 250,
                          //     height: 200,
                          //     decoration: BoxDecoration(
                          //       color: Colors.white,
                          //       borderRadius: BorderRadius.circular(defaultRadius),
                          //       boxShadow: [
                          //         BoxShadow(color: Colors.grey.withOpacity(0.4), blurRadius: 10, spreadRadius: 0, offset: Offset(0.0, 0.0)),
                          //       ],
                          //     ),
                          //     child: Lottie.asset(paymentSuccessful, width: 450, height: 450, fit: BoxFit.contain))
                      )),
                ],
              );
            } else
              {
                return SizedBox();
              }
          }),
      bottomNavigationBar: currentData!=null && currentData!.payment!=null?Padding(
        padding: EdgeInsets.all(16),
        child: AppButtonWidget(
          text: getButtonText(),
          width: MediaQuery.of(context).size.width,
          onTap: () {
            if (currentData!.payment!.paymentStatus == COMPLETED) {
              orderDetailApi();
              // launchScreen(context, DashBoardScreen(), isNewTask: true, pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == CASH) {
              toast(language.waitingForDriverConformation);
            } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == WALLET) {
              savePaymentApi();
            }
          },
        ),
      ):SizedBox(),
    );
  }

  String? getButtonText() {
    if (currentData!.payment!.paymentStatus == COMPLETED) {
      return language.continueNewRide;
    } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == CASH) {
      return language.waitingForDriverConformation;
    } else if (currentData!.payment!.paymentStatus != COMPLETED && currentData!.payment!.paymentType == WALLET) {
      return language.payToPayment;
    }
    return '';
  }

  Widget addressComponent() {
    if(riderModel==null){
      return SizedBox();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withOpacity(0.5).withOpacity(0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Ionicons.calendar, color: textSecondaryColorGlobal, size: 16),
                  SizedBox(width: 4),
                  Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text('${printDate(riderModel!.createdAt.validate())}', style: primaryTextStyle(size: 14)),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(language.rideId, style: boldTextStyle(size: 16)),
                  SizedBox(width: 8),
                  Text('#${riderModel!.id}', style: boldTextStyle(size: 16)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Text('${language.lblDistance} ${riderModel!.distance!.toStringAsFixed(2)} ${riderModel!.distanceUnit.toString()}', style: boldTextStyle(size: 14)),
          SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.near_me, color: Colors.green, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.startTime != null) Text(riderModel!.startTime != null ? printDate(riderModel!.startTime!) : '', style: secondaryTextStyle(size: 12)),
                        if (riderModel!.startTime != null) SizedBox(height: 4),
                        Text(riderModel!.startAddress.validate(), style: primaryTextStyle(size: 14)),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  SizedBox(width: 10),
                  SizedBox(
                    height: 30,
                    child: DottedLine(
                      direction: Axis.vertical,
                      lineLength: double.infinity,
                      lineThickness: 1,
                      dashLength: 2,
                      dashColor: primaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.red, size: 18),
                  SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (riderModel!.endTime != null) Text(riderModel!.endTime != null ? printDate(riderModel!.endTime!) : '', style: secondaryTextStyle(size: 12)),
                        if (riderModel!.endTime != null) SizedBox(height: 4),
                        Text(riderModel!.endAddress.validate(), style: primaryTextStyle(size: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          inkWellWidget(
            onTap: () {
              launchScreen(context, RideHistoryScreen(rideHistory: rideHistory), pageRouteAnimation: PageRouteAnimation.SlideBottomTop);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.viewHistory, style: secondaryTextStyle()),
                Icon(Entypo.chevron_right, color: dividerColor, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget paymentDetailWidget() {
    if(riderModel==null){
      return SizedBox();
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withOpacity(0.5).withOpacity(0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.paymentDetails, style: boldTextStyle(size: 16)),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.via, style: primaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentType.validate()), style: boldTextStyle()),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(language.status, style: primaryTextStyle()),
              Text(paymentStatus(riderModel!.paymentStatus.validate()), style: boldTextStyle(color: paymentStatusColor(riderModel!.paymentStatus.validate()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget priceDetailWidget() {
    if(riderModel==null){
      return SizedBox();
    }
    // print("CHeck Minimum FareAMount::${riderModel!.minimumFare}");
    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: dividerColor.withOpacity(0.5).withOpacity(0.5)),
        borderRadius: radius(),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(language.priceDetail, style: boldTextStyle(size: 16)),
          SizedBox(height: 12),
          riderModel!.subtotal! <= riderModel!.minimumFare!
              ? totalCount(title: language.minimumFare, amount: riderModel!.minimumFare)
              : Column(
                  children: [
                    totalCount(title: language.basePrice, amount: riderModel!.baseFare,space:8),
                    // SizedBox(height: 8),
                    totalCount(title:language.distancePrice, amount: riderModel!.perDistanceCharge,space: 8),
                    // SizedBox(height: 8),
                    totalCount(title:language.minutePrice, amount: riderModel!.perMinuteDriveCharge,space: 8),
                    // SizedBox(height: 8),
                    totalCount(title: language.waitingTimePrice, amount: riderModel!.perMinuteWaitingCharge),
                    // totalCount(title: language.basePrice, amount: riderModel!.baseFare),
                    // SizedBox(height: 8),
                    // totalCount(title: language.distancePrice, amount: riderModel!.perDistanceCharge),
                    // SizedBox(height: 8),
                    // totalCount(title: language.minutePrice, amount: riderModel!.perMinuteDriveCharge),
                    // SizedBox(height: 8),
                    // totalCount(title: language.waitingTimePrice, amount: riderModel!.perMinuteWaitingCharge),
                  ],
                ),
          SizedBox(height: 8),
          if (riderModel!.couponData != null && riderModel!.couponDiscount != 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(language.couponDiscount, style: secondaryTextStyle()),
                Text(
                  "- " + printAmount(riderModel!.couponDiscount!.toStringAsFixed(digitAfterDecimal)),
                  style: boldTextStyle(color: Colors.green, size: 14),
                ),
              ],
            ),
          if (riderModel!.couponData != null && riderModel!.couponDiscount != 0) SizedBox(height: 8),
          if (riderModel!.tips != null) totalCount(title: language.tip, amount: riderModel!.tips),
          if (riderModel!.tips != null) SizedBox(height: 8),
          if (riderModel!.extraCharges!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(language.additionalFees, style: boldTextStyle()),
                SizedBox(height: 8),
                ...riderModel!.extraCharges!.map((e) {
                  return Padding(
                    padding: EdgeInsets.only(top: 4, bottom: 4),
                    child: totalCount(title: e.key.validate(), amount: e.value),
                  );
                }).toList()
              ],
            ),
          Divider(height: 16, thickness: 1),
          riderModel!.tips != null
              ? totalCount(title: language.total, amount: riderModel!.subtotal! + riderModel!.tips!, isTotal: true)
              : totalCount(title: language.total, amount: riderModel!.subtotal, isTotal: true),
        ],
      ),
    );
  }
}
