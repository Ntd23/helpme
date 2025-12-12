import 'package:taxi_driver/model/ComplaintModel.dart';
import 'package:taxi_driver/model/DriverRatting.dart';
import 'package:taxi_driver/model/RideHistory.dart';
import 'package:taxi_driver/model/RiderModel.dart';

import 'CurrentRequestModel.dart';

class RideDetailModel {
  RiderModel? data;
  List<RideHistory>? rideHistory;
  DriverRatting? driverRatting;
  DriverRatting? riderRatting;
  ComplaintModel? complaintModel;
  Payment? payment;
  var estimated_price;
  String? invoice_url;
  String? invoice_name;

  RideDetailModel({this.data, this.rideHistory,this.invoice_name,this.invoice_url, this.driverRatting, this.riderRatting, this.complaintModel,this.payment,this.estimated_price});

  factory RideDetailModel.fromJson(Map<String, dynamic> json) {
    return RideDetailModel(
        estimated_price :json['estimated_price'],
      data: json['data'] != null ? RiderModel.fromJson(json['data']) : null,
      invoice_url: json['invoice_url'] != null ? json['invoice_url'] : null,
      invoice_name: json['invoice_name'] != null ? json['invoice_name'] : null,
      rideHistory: json['ride_history'] != null ? (json['ride_history'] as List).map((i) => RideHistory.fromJson(i)).toList() : null,
      driverRatting: json['driver_rating'] != null ? DriverRatting.fromJson(json['driver_rating']) : null,
      riderRatting: json['rider_rating'] != null ? DriverRatting.fromJson(json['rider_rating']) : null,
      complaintModel: json['complaint'] != null ? ComplaintModel.fromJson(json['complaint']) : null,
      payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,

    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    if (this.data != null) {
      data['data'] = this.data!.toJson();
    }
    if (this.rideHistory != null) {
      data['ride_history'] = this.rideHistory!.map((v) => v.toJson()).toList();
    }
    if (this.driverRatting != null) {
      data['driver_rating'] = this.driverRatting!.toJson();
    }
    if (this.riderRatting != null) {
      data['rider_rating'] = this.riderRatting!.toJson();
    }
    if (this.complaintModel != null) {
      data['complaint'] = this.complaintModel!.toJson();
    }
    if (this.payment != null) {
      data['payment'] = this.payment!.toJson();
    }
    if (this.invoice_name != null) {
      data['invoice_name'] = this.invoice_name;
    }
    if (this.invoice_url != null) {
      data['invoice_url'] = this.invoice_url;
    }
    data['estimated_price'] = this.estimated_price;
    return data;
  }
}