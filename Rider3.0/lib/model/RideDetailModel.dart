import '../model/ComplaintModel.dart';
import '../model/DriverRatting.dart';
import '../model/OrderHistory.dart';
import '../model/RiderModel.dart';

import 'CurrentRequestModel.dart';

class RideDetailModel {
  RiderModel? data;
  List<RideHistory>? rideHistory;
  DriverRatting? driverRatting;
  DriverRatting? riderRatting;
  ComplaintModel? complaintModel;
  Payment? payment;
  String? invoice_url;
  String? invoice_name;

  RideDetailModel({this.data, this.rideHistory, this.driverRatting, this.riderRatting, this.complaintModel, this.payment,this.invoice_url,this.invoice_name});

  factory RideDetailModel.fromJson(Map<String, dynamic> json) {
    return RideDetailModel(
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
    return data;
  }
}
