import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/CodModel.dart';
import 'package:emartconsumer/model/FlutterWaveSettingDataModel.dart';
import 'package:emartconsumer/model/MercadoPagoSettingsModel.dart';
import 'package:emartconsumer/model/PayFastSettingData.dart';
import 'package:emartconsumer/model/PayStackSettingsModel.dart';
import 'package:emartconsumer/model/RazorPayFailedModel.dart';
import 'package:emartconsumer/model/StripePayFailedModel.dart';
import 'package:emartconsumer/model/TaxModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/createRazorPayOrderModel.dart';
import 'package:emartconsumer/model/getPaytmTxtToken.dart';
import 'package:emartconsumer/model/offer_model.dart';
import 'package:emartconsumer/model/payStackURLModel.dart';
import 'package:emartconsumer/model/paypalSettingData.dart';
import 'package:emartconsumer/model/paytmSettingData.dart';
import 'package:emartconsumer/model/razorpayKeyModel.dart';
import 'package:emartconsumer/model/stripeSettingData.dart';
import 'package:emartconsumer/rental_service/model/rental_order_model.dart';
import 'package:emartconsumer/rental_service/rental_booking_screen.dart';
import 'package:emartconsumer/rental_service/rental_service_dash_board.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/paystack_url_genrater.dart';
import 'package:emartconsumer/services/rozorpayConroller.dart';
import 'package:emartconsumer/ui/wallet/MercadoPagoScreen.dart';
import 'package:emartconsumer/ui/wallet/PayFastScreen.dart';
import 'package:emartconsumer/ui/wallet/payStackScreen.dart';
import 'package:emartconsumer/userPrefrence.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe1;
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:http/http.dart' as http;
import 'package:mercadopago_sdk/mercadopago_sdk.dart';
import 'package:paytm_allinonesdk/paytm_allinonesdk.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class RentalPaymentScreen extends StatefulWidget {
  User? driverDetails;
  RentalOrderModel? rentalOrderModel;

  RentalPaymentScreen(
      {Key? key, required this.driverDetails, this.rentalOrderModel})
      : super(key: key);

  @override
  State<RentalPaymentScreen> createState() => _RentalPaymentScreenState();
}

class _RentalPaymentScreenState extends State<RentalPaymentScreen> {
  late Future<List<OfferModel>> coupon;
  late Future<List<OfferModel>> publiccoupon;
  final FireStoreUtils _fireStoreUtils = FireStoreUtils();

  RentalOrderModel? rentalOrderModel;
  User? driverDetails;

  List<OfferModel> couponList = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      driverDetails = widget.driverDetails;
      rentalOrderModel = widget.rentalOrderModel;
    });
    getTexDetails();
    getPaymentSettingData();
    _razorPay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorPay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWaller);
    _razorPay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    publiccoupon = _fireStoreUtils.getOfferByRentalCoupons();
    coupon = _fireStoreUtils.getRentalCoupons();
  }

  bool? taxActive = false;
  bool? isEnableCommission = false;
  double taxAmount = 0.0;
  String taxLable = "";
  String taxType = "";
  String commissionAmount = "";
  String commissionType = "";
  double subTotal = 0.0;
  double driverRate = 0.0;

  double discountAmount = 0.0;
  String discountType = "";
  String discountLable = "";
  String offerCode = "";

  getTexDetails() async {
    int day = daysBetween(rentalOrderModel!.pickupDateTime!.toDate(),
        rentalOrderModel!.dropDateTime!.toDate());
    print("------->" + day.toString());
    if (rentalOrderModel!.bookWithDriver == true) {
      double carRate = double.parse(driverDetails!.carRate) * day;
      subTotal = carRate;
      driverRate = double.parse(driverDetails!.driverRate) * day;
    } else {
      subTotal = double.parse(driverDetails!.carRate) * day;
    }

    await FireStoreUtils()
        .getSectionsById(sectionConstantModel!.id)
        .then((value) {
      print(value!.commissionAmount);

      // taxActive = value.taxActive;
      isEnableCommission = value.isEnableCommission;
      // taxAmount = taxAmount.toString().isNotEmpty ? double.parse(value.taxAmount.toString()) : 0.0;
      // taxLable = value.taxLable.toString();
      // taxType = value.taxType.toString();

      commissionType = value.commissionType.toString();
      commissionAmount = value.commissionAmount.toString();
    });
    //await coupon.then((value) {
    await publiccoupon.then((value) {
      couponList = value;
    });
    setState(() {});
  }

  int daysBetween(DateTime from, DateTime to) {
    print(from);
    print(to);
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return to.difference(from).inDays + 1;
  }

  /* double getTaxAmount() {
    double totalTax = 0.0;
    if (taxActive == true) {
      if (taxType == "percent") {
        totalTax = ((subTotal + driverRate) - discountAmount) * taxAmount / 100;
      } else {
        totalTax = taxAmount;
      }
    }
    return totalTax;
  }*/

  User? comapny;

  placeParcelOrder() async {
    if (driverDetails!.companyId.isNotEmpty) {
      await fireStoreUtils.getUserByIDS(driverDetails!.companyId).then((value) {
        setState(() {
          comapny = value;
        });
      });
    }

    rentalOrderModel = RentalOrderModel(
      authorID: MyAppState.currentUser!.userID,
      author: MyAppState.currentUser,
      pickupAddress: widget.rentalOrderModel!.pickupAddress,
      bookWithDriver: widget.rentalOrderModel!.bookWithDriver,
      dropAddress: widget.rentalOrderModel!.dropAddress,
      dropDateTime: widget.rentalOrderModel!.dropDateTime,
      dropLatLong: widget.rentalOrderModel!.dropLatLong,
      pickupDateTime: widget.rentalOrderModel!.pickupDateTime,
      pickupLatLong: widget.rentalOrderModel!.pickupLatLong,
      adminCommission: commissionAmount,
      adminCommissionType: commissionType,
      discount: discountAmount.toString(),
      discountType: discountType,
      discountLabel: discountLable,
      status: ORDER_STATUS_PLACED,
      paymentMethod: paymentType,
      createdAt: Timestamp.now(),
      // tax: taxAmount.toString(),
      // taxLabel: taxLable,
      // taxType: taxType,
      taxModel: taxList,
      subTotal: subTotal.toString(),
      driverRate: driverRate.toString(),
      driverID: driverDetails!.userID,
      driver: driverDetails,
      company: comapny,
      companyID: driverDetails!.companyId,
      sectionId: sectionConstantModel!.id,
    );

    /* if(taxActive!=null&&taxActive==true){
      rentalOrderModel!.taxType=taxType.toString();
      rentalOrderModel!.tax=taxAmount.toString();
      rentalOrderModel!.taxLabel=taxLable.toString();
    }*/

    await FireStoreUtils()
        .rentalOrderPlace(rentalOrderModel!, getTotalAmount())
        .then((value) async {
      // if (driverDetails!.companyId.isNotEmpty) {
      //   await FireStoreUtils.sendFcmMessage(rentalBooked, comapny!.fcmToken,{});
      // } else {
      Map<String, dynamic> payLoad = <String, dynamic>{
        "type": "rental_order",
        "orderId": widget.rentalOrderModel!.id
      };
      await FireStoreUtils.sendFcmMessage(
          rentalBooked, widget.driverDetails!.fcmToken, payLoad);
      //  }
    });
    await FireStoreUtils.sendRentalBookEmail(orderModel: rentalOrderModel!);
    await FireStoreUtils.sendRentalBookDriverEmail(
        orderModel: rentalOrderModel!);

    final SnackBar snackBar = SnackBar(
      content: Text(
        "Ride successfully booked".tr(),
        textAlign: TextAlign.start,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: Color(COLOR_PRIMARY),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    pushAndRemoveUntil(
        context,
        RentalServiceDashBoard(
          user: MyAppState.currentUser!,
          currentWidget: const RentalBookingScreen(),
          appBarTitle: 'Booking'.tr(),
          drawerSelection: DrawerSelection.Orders,
        ),
        false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _globalKey,
      appBar: AppBar(
        leading: InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
            )),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                margin: const EdgeInsets.only(
                    left: 10, top: 10, right: 10, bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDarkMode(context)
                          ? const Color(DarkContainerBorderColor)
                          : Colors.grey.shade100,
                      width: 1),
                  color: isDarkMode(context)
                      ? const Color(DarkContainerColor)
                      : Colors.white,
                  boxShadow: [
                    isDarkMode(context)
                        ? const BoxShadow()
                        : BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "PickUp",
                      style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800),
                    ).tr(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: Color(COLOR_PRIMARY), size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd hh:mm a').format(
                                rentalOrderModel!.pickupDateTime!.toDate()),
                            style: TextStyle(
                                letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                            color: Color(COLOR_PRIMARY), size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            rentalOrderModel!.pickupAddress.toString(),
                            style: TextStyle(
                                letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
                margin: const EdgeInsets.only(
                    left: 10, top: 10, right: 10, bottom: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: isDarkMode(context)
                          ? const Color(DarkContainerBorderColor)
                          : Colors.grey.shade100,
                      width: 1),
                  color: isDarkMode(context)
                      ? const Color(DarkContainerColor)
                      : Colors.white,
                  boxShadow: [
                    isDarkMode(context)
                        ? const BoxShadow()
                        : BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Drop off",
                      style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w800),
                    ).tr(),
                    const SizedBox(
                      height: 10,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time_rounded,
                            color: Color(COLOR_PRIMARY), size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            DateFormat('yyyy-MM-dd hh:mm a').format(
                                rentalOrderModel!.dropDateTime!.toDate()),
                            style: TextStyle(
                                letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.location_on,
                            color: Color(COLOR_PRIMARY), size: 18),
                        const SizedBox(
                          width: 5,
                        ),
                        Expanded(
                          child: Text(
                            rentalOrderModel!.dropAddress.toString(),
                            style: TextStyle(
                                letterSpacing: 1, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              couponList.isNotEmpty ? buildListPromoCode() : Container(),
              buildPromoCode(),
              buildTotalRow(),
              paymentListView()
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(10),
            backgroundColor: Color(COLOR_PRIMARY),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () async {
            await FireStoreUtils.createPaymentId();
            if (razorPay) {
              paymentType = 'razorpay';
              showLoadingAlert();
              RazorPayController()
                  .createOrderRazorPay(amount: getTotalAmount().toInt())
                  .then((value) {
                if (value == null) {
                  Navigator.pop(context);
                  showAlert(_globalKey.currentContext!,
                      response: "contact-admin".tr(), colors: Colors.red);
                } else {
                  CreateRazorPayOrderModel result = value;
                  openCheckout(
                    amount: getTotalAmount(),
                    orderId: result.id,
                  );
                }
              });
            } else if (payTm) {
              paymentType = 'paytm';
              showLoadingAlert();
              getPaytmCheckSum(context, amount: getTotalAmount());
            } else if (stripe) {
              paymentType = 'stripe';
              showLoadingAlert();
              stripeMakePayment(amount: getTotalAmount().toString());
            } else if (payFast) {
              paymentType = 'payfast';
              showLoadingAlert();
              PayStackURLGen.getPayHTML(
                      payFastSettingData: payFastSettingData!,
                      amount: getTotalAmount()
                          .toStringAsFixed(currencyData!.decimal))
                  .then((value) async {
                bool isDone =
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => PayFastScreen(
                              htmlData: value,
                              payFastSettingData: payFastSettingData!,
                            )));

                print(isDone);
                if (isDone) {
                  Navigator.pop(context);
                  placeParcelOrder();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text(
                      "Payment Successful!!\n",
                    ).tr(),
                    backgroundColor: Colors.green.shade400,
                    duration: const Duration(seconds: 6),
                  ));
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Builder(builder: (context) {
                      return const Text(
                        "Payment UnSuccessful!!\n",
                      ).tr();
                    }),
                    backgroundColor: Colors.red.shade400,
                    duration: const Duration(seconds: 6),
                  ));
                }
              });
            } else if (cod) {
              paymentType = 'cod';
              placeParcelOrder();
            } else if (payStack) {
              paymentType = 'paystack';
              showLoadingAlert();
              payStackPayment(context);
            } else if (flutterWave) {
              setRef();
              paymentType = 'flutterwave';
              _flutterWaveInitiatePayment(context);
            } else if (paypal) {
              paymentType = 'paypal';
              showLoadingAlert();
              //  _makePaypalPayment(amount: getTotalAmount().toString());
              // paypalPaymentSheet(amount: getTotalAmount().toString());
            } else if (wallet && walletBalanceError == false) {
              paymentType = 'wallet';

              placeParcelOrder();
            } else if (mercadoPago) {
              paymentType = 'mercadoPago';
              mercadoPagoMakePayment();
            } else {
              final SnackBar snackBar = SnackBar(
                content: Text(
                  "Select Payment Method".tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                backgroundColor: Color(COLOR_PRIMARY),
              );
              ScaffoldMessenger.of(context).showSnackBar(snackBar);
            }
          },
          child: Text(
            'Continue'.tr(),
            style: TextStyle(
                color: isDarkMode(context) ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18),
          ),
        ),
      ),
    );
  }

  Widget buildTotalRow() {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDarkMode(context)
                ? const Color(DarkContainerBorderColor)
                : Colors.grey.shade100,
            width: 1),
        color: isDarkMode(context)
            ? const Color(DarkContainerColor)
            : Colors.white,
        boxShadow: [
          isDarkMode(context)
              ? const BoxShadow()
              : BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  blurRadius: 5,
                ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Booking summary".tr(),
                      style: const TextStyle(
                          letterSpacing: 1, fontWeight: FontWeight.w600)),
                ],
              )),
          const Divider(
            thickness: 1,
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal".tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    amountShow(amount: subTotal.toString()),
                    style: TextStyle(
                        color: isDarkMode(context)
                            ? const Color(0xffFFFFFF)
                            : const Color(0xff333333),
                        fontSize: 16),
                  ),
                ],
              )),
          const Divider(
            thickness: 1,
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Driver Amount".tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    amountShow(amount: driverRate.toString()),
                    style: TextStyle(
                        color: isDarkMode(context)
                            ? const Color(0xffFFFFFF)
                            : const Color(0xff333333),
                        fontSize: 16),
                  ),
                ],
              )),
          const Divider(
            thickness: 1,
          ),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Discount".tr(),
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    "(-" + amountShow(amount: discountAmount.toString()) + ")",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ],
              )),
          const Divider(
            thickness: 1,
          ),
          Visibility(
            visible: offerCode.isNotEmpty,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Text(
                    "Coupon code :".tr() + "$offerCode",
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(COLOR_PRIMARY),
                        fontSize: 16),
                  ),
                ),
                const Divider(
                  thickness: 1,
                ),
              ],
            ),
          ),

          ListView.builder(
            itemCount: taxList!.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              TaxModel taxModel = taxList![index];
              return Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "${taxModel.title.toString()} (${taxModel.type == "fix" ? amountShow(amount: taxModel.tax) : "${taxModel.tax}%"})",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        Text(
                          amountShow(
                              amount: getTaxValue(
                                      amount: ((subTotal + driverRate) -
                                              discountAmount)
                                          .toString(),
                                      taxModel: taxModel)
                                  .toString()),
                          style: TextStyle(
                              color: isDarkMode(context)
                                  ? const Color(0xffFFFFFF)
                                  : const Color(0xff333333),
                              fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    thickness: 1,
                  ),
                ],
              );
            },
          ),
          /* Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ((taxLable.isNotEmpty) ? taxLable.toString() : "Tax".tr()) + " ${(taxType == "fix") ? "" : "($taxAmount %)"}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    amountShow(amount: getTaxAmount().toString()),
                    style: TextStyle(color: isDarkMode(context) ? const Color(0xffFFFFFF) : const Color(0xff333333), fontSize: 16),
                  ),
                ],
              )),*/
          // const Divider(
          //   color: Color(0xffE2E8F0),
          //   height: 0.1,
          // ),

          Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Order Total".tr(),
                    style: TextStyle(
                        color: isDarkMode(context)
                            ? const Color(0xffFFFFFF)
                            : const Color(0xff333333),
                        fontSize: 16),
                  ),
                  Text(
                    amountShow(amount: getTotalAmount().toString()),
                    style: TextStyle(
                        color: isDarkMode(context)
                            ? const Color(0xffFFFFFF)
                            : const Color(0xff333333),
                        fontSize: 16),
                  ),
                ],
              )),
        ],
      ),
    );
  }

  /*double getTotalAmount() {
    return (subTotal + driverRate) - discountAmount + getTaxAmount();
  }*/
  double getTotalAmount() {
    double taxAmount = 0.0;
    if (taxList != null) {
      for (var element in taxList!) {
        taxAmount = taxAmount +
            getTaxValue(
                amount: ((subTotal + driverRate) - discountAmount).toString(),
                taxModel: element);
      }
    }
    return (subTotal + driverRate) - discountAmount + taxAmount;
  }

  buildListPromoCode() {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDarkMode(context)
                  ? const Color(DarkContainerBorderColor)
                  : Colors.grey.shade100,
              width: 1),
          color: isDarkMode(context)
              ? const Color(DarkContainerColor)
              : Colors.white,
          boxShadow: [
            isDarkMode(context)
                ? const BoxShadow()
                : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
          child: SizedBox(
            height: 85,
            child: ListView.builder(
                itemCount: couponList.length,
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (couponList[index].discountTypeOffer == 'Percentage' ||
                          couponList[index].discountTypeOffer == 'Percent') {
                        discountAmount = subTotal *
                            double.parse(couponList[index].discountOffer!) /
                            100;
                        discountType =
                            couponList[index].discountTypeOffer.toString();
                        discountLable =
                            couponList[index].discountOffer.toString();
                        offerCode = couponList[index].offerCode.toString();
                      } else {
                        discountAmount =
                            double.parse(couponList[index].discountOffer!);
                        discountType =
                            couponList[index].discountTypeOffer.toString();
                        discountLable =
                            couponList[index].discountOffer.toString();
                        offerCode = couponList[index].offerCode.toString();
                      }

                      print(discountAmount);
                      setState(() {});
                    },
                    child: buildOfferItem(couponList, index),
                  );
                }),
          ),
        ),
      ),
    );
  }

  Widget buildOfferItem(List<OfferModel> snapshot, int index) {
    return Container(
      margin: const EdgeInsets.fromLTRB(7, 10, 7, 10),
      height: 85,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(2),
        padding: const EdgeInsets.all(2),
        color: const Color(COUPON_DASH_COLOR),
        strokeWidth: 2,
        dashPattern: const [5],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
              ),
              margin: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Image(
                        image: AssetImage('assets/images/offer_icon.png'),
                        height: 25,
                        width: 25,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        child: Text(
                          snapshot[index].discountTypeOffer == "Fix Price"
                              ? (currencyData!.symbolatright == true)
                                  ? "${snapshot[index].discountOffer}${currencyData!.symbol.toString()} OFF"
                                  : "${currencyData!.symbol.toString()}${snapshot[index].discountOffer} OFF"
                              : "${snapshot[index].discountOffer} % Off",
                          style: const TextStyle(
                              color: Color(GREY_TEXT_COLOR),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        snapshot[index].offerCode!,
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.normal,
                            letterSpacing: 0.5,
                            color: Color(GREY_TEXT_COLOR)),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.only(left: 15, right: 15, top: 3),
                        width: 1,
                        color: const Color(COUPON_DASH_COLOR),
                      ),
                      Text(
                          "valid till ".tr() +
                              getDate(snapshot[index]
                                  .expireOfferDate!
                                  .toDate()
                                  .toString())!,
                          style: const TextStyle(
                              letterSpacing: 0.5, color: Color(0Xff696A75)))
                    ],
                  ),
                ],
              )),
        ),
      ),
    );
  }

  String? getDate(String date) {
    final format = DateFormat("MMM dd, yyyy");
    String formattedDate = format.format(DateTime.parse(date));
    return formattedDate;
  }

  buildPromoCode() {
    return GestureDetector(
      child: Container(
        margin: const EdgeInsets.only(left: 13, top: 10, right: 13, bottom: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isDarkMode(context)
                  ? const Color(DarkContainerBorderColor)
                  : Colors.grey.shade100,
              width: 1),
          color: isDarkMode(context)
              ? const Color(DarkContainerColor)
              : Colors.white,
          boxShadow: [
            isDarkMode(context)
                ? const BoxShadow()
                : BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    blurRadius: 5,
                  ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Image.asset("assets/images/reedem.png", height: 50),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Promo Code".tr(),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(
                          height: 5,
                        ),
                        Text("Apply promo code".tr(),
                            style: const TextStyle(
                                fontSize: 15, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              FloatingActionButton(
                onPressed: () {
                  showModalBottomSheet(
                      isScrollControlled: true,
                      isDismissible: true,
                      context: context,
                      backgroundColor: Colors.transparent,
                      enableDrag: true,
                      builder: (BuildContext context) => sheet());
                },
                mini: true,
                backgroundColor: Colors.blueGrey.shade50,
                elevation: 0,
                child: const Icon(
                  Icons.add,
                  color: Colors.black54,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  TextEditingController txt = TextEditingController(text: '');

  sheet() {
    return Container(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height / 4.3,
            left: 25,
            right: 25),
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(style: BorderStyle.none)),
        child: FutureBuilder<List<OfferModel>>(
            future: coupon,
            initialData: const [],
            builder: (context, snapshot) {
              snapshot = snapshot;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  ),
                );
              }

              // coupon = snapshot.data as Future<List<CouponModel>> ;
              return Column(children: [
                InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      height: 45,
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.white, width: 0.3),
                          color: Colors.transparent,
                          shape: BoxShape.circle),

                      // radius: 20,
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    )),
                const SizedBox(
                  height: 25,
                ),
                Expanded(
                    child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                            padding: const EdgeInsets.only(top: 30),
                            child: const Image(
                              image:
                                  AssetImage('assets/images/redeem_coupon.png'),
                              width: 100,
                            )),
                        Container(
                            padding: const EdgeInsets.only(top: 20),
                            child: Text(
                              'Redeem Your Coupons'.tr(),
                              style: const TextStyle(
                                  color: Color(0XFF2A2A2A), fontSize: 16),
                            )),
                        Center(
                          child: Container(
                              padding: const EdgeInsets.only(
                                  top: 10, left: 22, right: 22),
                              child: const Text(
                                "Voucher or Coupon code",
                                style: TextStyle(
                                    color: Color(0XFF9091A4),
                                    letterSpacing: 0.5,
                                    height: 2),
                              ).tr()),
                        ),
                        Container(
                            padding: const EdgeInsets.only(
                                left: 20, right: 20, top: 20),
                            // height: 120,
                            child: DottedBorder(
                                borderType: BorderType.RRect,
                                radius: const Radius.circular(12),
                                dashPattern: const [4, 2],
                                color: const Color(0XFFB7B7B7),
                                child: ClipRRect(
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(12)),
                                    child: Container(
                                        padding: const EdgeInsets.only(
                                            left: 20,
                                            right: 20,
                                            top: 20,
                                            bottom: 20),
                                        color: const Color(0XFFF1F4F7),
                                        // height: 120,
                                        alignment: Alignment.center,
                                        child: TextFormField(
                                          textAlign: TextAlign.center,
                                          controller: txt,

                                          // textAlignVertical: TextAlignVertical.center,
                                          decoration: InputDecoration(
                                            border: InputBorder.none,
                                            hintText: "Write Coupon Code".tr(),
                                            hintStyle: const TextStyle(
                                                color: Color(0XFF9091A4)),
                                            labelStyle: const TextStyle(
                                                color: Color(0XFF333333)),
                                            //  hintTextDirection: TextDecoration.lineThrough
                                            // contentPadding: EdgeInsets.only(left: 80,right: 30),
                                          ),
                                        ))))),
                        Padding(
                          padding: const EdgeInsets.only(top: 30, bottom: 30),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 100, vertical: 15),
                              backgroundColor: Color(COLOR_PRIMARY),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                for (int a = 0;
                                    a < snapshot.data!.length;
                                    a++) {
                                  OfferModel couponModel = snapshot.data![a];
                                  if (txt.text.toString().toLowerCase() ==
                                      couponModel.offerCode!
                                          .toString()
                                          .toLowerCase()) {
                                    if (couponModel.discountTypeOffer ==
                                            'Percentage' ||
                                        couponModel.discountTypeOffer ==
                                            'Percent') {
                                      discountAmount = (subTotal + driverRate) *
                                          double.parse(
                                              couponModel.discountOffer!) /
                                          100;
                                      discountType = couponModel
                                          .discountTypeOffer
                                          .toString();
                                      discountLable =
                                          couponModel.discountOffer.toString();
                                      offerCode =
                                          couponModel.offerCode.toString();
                                      break;
                                    } else {
                                      discountAmount = double.parse(
                                          couponModel.discountOffer!);
                                      discountType = couponModel
                                          .discountTypeOffer
                                          .toString();
                                      discountLable =
                                          couponModel.discountOffer.toString();
                                      offerCode =
                                          couponModel.offerCode.toString();
                                    }
                                  }
                                }
                              });
                              print(discountAmount);

                              Navigator.pop(context);
                            },
                            child: Text(
                              "REDEEM NOW".tr(),
                              style: TextStyle(
                                  color: isDarkMode(context)
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
                //buildcouponItem(snapshot)
                //  listData(snapshot)
              ]);
            }));
  }

  final Razorpay _razorPay = Razorpay();

  Stream<DocumentSnapshot<Map<String, dynamic>>>? userQuery;
  final fireStoreUtils = FireStoreUtils();
  static FirebaseFirestore fireStore = FirebaseFirestore.instance;
  StripeSettingData? stripeData;
  PaytmSettingData? paytmSettingData;
  PaypalSettingData? paypalSettingData;
  PayStackSettingData? payStackSettingData;
  FlutterWaveSettingData? flutterWaveSettingData;
  PayFastSettingData? payFastSettingData;
  MercadoPagoSettingData? mercadoPagoSettingData;
  CodModel? codModel;

  bool walletBalanceError = false;
  RazorPayModel? razorPayData = UserPreference.getRazorPayData();
  bool cod = false;
  bool payStack = false;
  bool flutterWave = false;
  bool wallet = false;
  bool razorPay = false;
  bool payTm = false;
  bool pay = false;
  bool stripe = false;
  bool paypal = false;
  bool payFast = false;
  bool mercadoPago = false;
  String selectedCardID = '';
  bool isStaging = true;
  bool enableAssist = true;
  bool restrictAppInvoke = false;

  String result = "";

  String paymentOption = 'Pay Via Wallet'.tr();
  String paymentType = "";

  showAlert(BuildContext context123,
      {required String response, required Color colors}) {
    return ScaffoldMessenger.of(context123).showSnackBar(SnackBar(
      content: Text(response),
      backgroundColor: colors,
    ));
  }

  getPaymentSettingData() async {
    userQuery = fireStore
        .collection(USERS)
        .doc(MyAppState.currentUser!.userID)
        .snapshots();
    await UserPreference.getStripeData().then((value) async {
      stripeData = value;
      stripe1.Stripe.publishableKey = stripeData!.clientpublishableKey;
      stripe1.Stripe.merchantIdentifier = PAYID;
      await stripe1.Stripe.instance.applySettings();
    });
    razorPayData = await UserPreference.getRazorPayData();
    paytmSettingData = await UserPreference.getPaytmData();
    paypalSettingData = await UserPreference.getPayPalData();
    payStackSettingData = await UserPreference.getPayStackData();
    flutterWaveSettingData = await UserPreference.getFlutterWaveData();
    payFastSettingData = await UserPreference.getPayFastData();
    mercadoPagoSettingData = await UserPreference.getMercadoPago();
    codModel = await fireStoreUtils.getCod();
    //initPayPal();
    setState(() {});
  }
  /*void initPayPal() async {
    //set debugMode for error logging
    FlutterPaypalNative.isDebugMode = paypalSettingData!.isLive == false ? true : false;
    //initiate payPal plugin
    await _flutterPaypalNativePlugin.init(
      //your app id !!! No Underscore!!! see readme.md for help
      returnUrl: "com.emart.customer://paypalpay",
      //client id from developer dashboard
      clientID: paypalSettingData!.paypalClient,
      //sandbox, staging, live etc
      payPalEnvironment: paypalSettingData!.isLive == true ? FPayPalEnvironment.live : FPayPalEnvironment.sandbox,
      //what currency do you plan to use? default is US dollars
      currencyCode: FPayPalCurrencyCode.usd,
      //action paynow?
      action: FPayPalUserAction.payNow,
    );

    //call backs for payment
    _flutterPaypalNativePlugin.setPayPalOrderCallback(
      callback: FPayPalOrderCallback(
        onCancel: () {
          //user canceled the payment
          Navigator.pop(context);
          ShowToastDialog.showToast("Payment canceled");
        },
        onSuccess: (data) {
          //successfully paid
          //remove all items from queue
          Navigator.pop(context);
          _flutterPaypalNativePlugin.removeAllPurchaseItems();
          ShowToastDialog.showToast("Payment Successfully");
          placeParcelOrder();
        },
        onError: (data) {
          Navigator.pop(context);
          ShowToastDialog.showToast("error: ${data.reason}");
        },
        onShippingChange: (data) {
          Navigator.pop(context);
          ShowToastDialog.showToast("shipping change: ${data.shippingChangeAddress?.adminArea1 ?? ""}");
        },
      ),
    );
  }*/

  Widget paymentListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
            margin: const EdgeInsets.only(left: 15),
            child: Text("Select Payment Method".tr(),
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600))),
        Visibility(
          visible: UserPreference.getWalletData() ?? false,
          child: Column(
            children: [
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: userQuery,
                  builder: (context,
                      AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>>
                          asyncSnapshot) {
                    if (asyncSnapshot.hasError) {
                      return const Text(
                        "error",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ).tr();
                    }
                    if (asyncSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 0.8,
                                color: Colors.white,
                                backgroundColor: Colors.transparent,
                              )));
                    }
                    if (asyncSnapshot.data == null) {
                      return Container();
                    }
                    User userData = User.fromJson(asyncSnapshot.data!.data()!);

                    walletBalanceError =
                        userData.wallet_amount < getTotalAmount()
                            ? true
                            : false;
                    return Column(
                      children: [
                        buildPaymentTile(
                            isVisible: UserPreference.getWalletData() ?? false,
                            selectedPayment: wallet,
                            walletError: walletBalanceError,
                            image: "assets/images/wallet_icon.png",
                            value: "Wallet".tr(),
                            childWidget: Text(
                              amountShow(
                                  amount: userData.wallet_amount.toString()),
                              style: TextStyle(
                                color: walletBalanceError
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            )),
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Visibility(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 0.0),
                                  child: walletBalanceError
                                      ? Text(
                                          "Your wallet doesn't have sufficient balance"
                                              .tr(),
                                          style: const TextStyle(
                                              fontSize: 14, color: Colors.red),
                                        )
                                      : Text(
                                          'Sufficient Balance'.tr(),
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.green),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }),
            ],
          ),
        ),
        buildPaymentTile(
          isVisible: codModel != null ? codModel!.cod : false,
          selectedPayment: cod,
          image: "assets/images/cash.png",
          value: "Cash".tr(),
        ),
        buildPaymentTile(
          isVisible: (stripeData == null) ? false : stripeData!.isEnabled,
          selectedPayment: stripe,
          value: "Stripe".tr(),
        ),
        buildPaymentTile(
          isVisible: razorPayData!.isEnabled,
          selectedPayment: razorPay,
          image: "assets/images/razorpay_@3x.png",
          value: "RazorPay".tr(),
        ),
        buildPaymentTile(
          isVisible:
              (paytmSettingData == null) ? false : paytmSettingData!.isEnabled,
          selectedPayment: payTm,
          image: "assets/images/paytm_@3x.png",
          value: "PayTm".tr(),
        ),
        buildPaymentTile(
          isVisible: (paypalSettingData == null)
              ? false
              : paypalSettingData!.isEnabled,
          selectedPayment: paypal,
          image: "assets/images/paypal_@3x.png",
          value: "PayPal".tr(),
        ),
        buildPaymentTile(
          isVisible: (payFastSettingData == null)
              ? false
              : payFastSettingData!.isEnable,
          selectedPayment: payFast,
          image: "assets/images/payfast.png",
          value: "PayFast".tr(),
        ),
        buildPaymentTile(
          isVisible: (payStackSettingData == null)
              ? false
              : payStackSettingData!.isEnabled,
          selectedPayment: payStack,
          image: "assets/images/paystack.png",
          value: "PayStack".tr(),
        ),
        buildPaymentTile(
          isVisible: (flutterWaveSettingData == null)
              ? false
              : flutterWaveSettingData!.isEnable,
          selectedPayment: paypal,
          image: "assets/images/flutterwave.png",
          value: "FlutterWave".tr(),
        ),
        buildPaymentTile(
          isVisible: (mercadoPagoSettingData == null)
              ? false
              : mercadoPagoSettingData!.isEnabled,
          selectedPayment: mercadoPago,
          image: "assets/images/mercadopago.png",
          value: "Mercado Pago".tr(),
        ),
      ],
    );
  }

  setAllFalse({required String value}) {
    print(value);
    setState(() {
      cod = false;
      stripe = false;
      wallet = false;
      payTm = false;
      razorPay = false;
      payStack = false;
      flutterWave = false;
      pay = false;
      paypal = false;
      payFast = false;
      mercadoPago = false;

      if (value == "Cash") {
        cod = true;
      }
      if (value == "Stripe") {
        stripe = true;
      }
      if (value == "PayTm") {
        payTm = true;
      }
      if (value == "RazorPay") {
        razorPay = true;
      }
      if (value == "Wallet") {
        wallet = true;
      }
      if (value == "PayPal") {
        paypal = true;
      }
      if (value == "PayFast") {
        payFast = true;
      }
      if (value == "PayStack") {
        payStack = true;
      }
      if (value == "FlutterWave") {
        flutterWave = true;
      }
      if (value == "Google Pay") {
        pay = true;
      }
      if (value == "Mercado Pago") {
        mercadoPago = true;
      }
    });
  }

  String? selectedRadioTile;

  ///show payment Options
  buildPaymentTile({
    bool walletError = false,
    Widget childWidget = const Center(),
    required bool isVisible,
    String value = "Stripe",
    image = "assets/images/stripe.png",
    required selectedPayment,
  }) {
    return Visibility(
      visible: isVisible,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: isDarkMode(context)
              ? const Color(DarkContainerColor)
              : Colors.white,
          elevation: selectedRadioTile == value ? 0.5 : 1.2,
          child: RadioListTile(
            controlAffinity: ListTileControlAffinity.trailing,
            value: value,
            groupValue: selectedRadioTile,
            onChanged: walletError != true
                ? (String? value) {
                    setState(() {
                      setAllFalse(value: value!);
                      selectedPayment = true;
                      selectedRadioTile = value;
                    });
                  }
                : (String? value) {},
            selected: selectedPayment,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 6,
            ),

            toggleable: true,
            activeColor: Color(COLOR_PRIMARY),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4.0, horizontal: 10),
                          child: SizedBox(
                            width: 80,
                            height: 35,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 6.0),
                              child: Image.asset(image),
                            ),
                          ),
                        )),
                    const SizedBox(
                      width: 10,
                    ),
                    Text(value,
                        style: TextStyle(
                          color: isDarkMode(context)
                              ? const Color(0xffFFFFFF)
                              : Colors.black,
                        )),
                  ],
                ),
                childWidget
              ],
            ),
            //toggleable: true,
          ),
        ),
      ),
    );
  }

  //RazorPay payment function
  void openCheckout({required amount, required orderId}) async {
    var options = {
      'key': razorPayData!.razorpayKey,
      'amount': amount * 100,
      'name': PAYID,
      'order_id': orderId,
      "currency": currencyData?.code,
      'description': 'wallet Topup',
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': MyAppState.currentUser!.phoneNumber,
        'email': MyAppState.currentUser!.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorPay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  ///Stripe payment function

  Map<String, dynamic>? paymentIntentData;

  Future<void> stripeMakePayment({required String amount}) async {
    try {
      paymentIntentData = await createStripeIntent(amount);
      if (paymentIntentData!.containsKey("error")) {
        Navigator.pop(_globalKey.currentContext!);
        showAlert(_globalKey.currentContext!,
            response: "contact-admin".tr(), colors: Colors.red);
      } else {
        await stripe1.Stripe.instance
            .initPaymentSheet(
                paymentSheetParameters: stripe1.SetupPaymentSheetParameters(
              paymentIntentClientSecret: paymentIntentData!['client_secret'],
              applePay: const stripe1.PaymentSheetApplePay(
                merchantCountryCode: 'US',
              ),
              allowsDelayedPaymentMethods: false,
              googlePay: stripe1.PaymentSheetGooglePay(
                merchantCountryCode: 'US',
                testEnv: true,
                currencyCode: currencyData!.code,
              ),
              style: ThemeMode.system,
              customFlow: true,
              appearance: stripe1.PaymentSheetAppearance(
                colors: stripe1.PaymentSheetAppearanceColors(
                  primary: Color(COLOR_PRIMARY),
                ),
              ),
              merchantDisplayName: 'Emart',
            ))
            .then((value) {});
        setState(() {});
        displayStripePaymentSheet(amount: amount);
      }
    } catch (e, s) {
      print('exception:$e$s');
    }
  }

  displayStripePaymentSheet({required amount}) async {
    try {
      await stripe1.Stripe.instance.presentPaymentSheet().then((value) {
        placeParcelOrder();
        ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
          content: Text("paid successfully".tr()),
          duration: const Duration(seconds: 8),
          backgroundColor: Colors.green,
        ));
        paymentIntentData = null;
        Navigator.pop(_globalKey.currentContext!);
      }).onError((error, stackTrace) {
        Navigator.pop(_globalKey.currentContext!);
        var lo1 = jsonEncode(error);
        var lo2 = jsonDecode(lo1);
        StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
        showDialog(
            context: _globalKey.currentContext!,
            builder: (_) => AlertDialog(
                  content: Text(lom.error.message),
                ));
      });
    } on stripe1.StripeException catch (e) {
      Navigator.pop(_globalKey.currentContext!);
      var lo1 = jsonEncode(e);
      var lo2 = jsonDecode(lo1);
      StripePayFailedModel lom = StripePayFailedModel.fromJson(lo2);
      showDialog(
          context: _globalKey.currentContext!,
          builder: (_) => AlertDialog(
                content: Text(lom.error.message),
              ));
    } catch (e) {
      print('$e');
      Navigator.pop(_globalKey.currentContext!);
      ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
        content: Text("$e"),
        duration: const Duration(seconds: 8),
        backgroundColor: Colors.red,
      ));
    }
  }

  createStripeIntent(
    String amount,
  ) async {
    try {
      Map<String, dynamic> body = {
        'amount': calculateAmount(amount),
        'currency': currencyData!.code,
        'payment_method_types[]': 'card',
        "description": "${MyAppState.currentUser?.userID} Wallet Topup",
        "shipping[name]":
            "${MyAppState.currentUser?.firstName} ${MyAppState.currentUser?.lastName}",
        "shipping[address][line1]": "510 Townsend St",
        "shipping[address][postal_code]": "98140",
        "shipping[address][city]": "San Francisco",
        "shipping[address][state]": "CA",
        "shipping[address][country]": "US",
      };
      print(body);
      var response = await http.post(
          Uri.parse('https://api.stripe.com/v1/payment_intents'),
          body: body,
          headers: {
            'Authorization': 'Bearer ${stripeData?.stripeSecret}',
            //$_paymentIntentClientSecret',
            'Content-Type': 'application/x-www-form-urlencoded'
          });
      print('Create Intent response ===> ${response.body.toString()}');

      return jsonDecode(response.body);
    } catch (err) {
      print('error charging user: ${err.toString()}');
    }
  }

  calculateAmount(String amount) {
    final a = ((double.parse(amount)) * 100).toInt();
    print(a);
    return a.toString();
  }

  ///MercadoPago Payment Method

  Future<Map<String, dynamic>> makePreference() async {
    final mp = MP.fromAccessToken(mercadoPagoSettingData!.accessToken);
    var pref = {
      "items": [
        {
          "title": "Wallet TopUp",
          "quantity": 1,
          "unit_price": double.parse(
              getTotalAmount().toStringAsFixed(currencyData!.decimal))
        }
      ],
      "auto_return": "all",
      "back_urls": {
        "failure": "${GlobalURL}payment/failure",
        "pending": "${GlobalURL}payment/pending",
        "success": "${GlobalURL}payment/success"
      },
    };

    var result = await mp.createPreference(pref);
    return result;
  }

  mercadoPagoMakePayment() {
    makePreference().then((result) async {
      if (result.isNotEmpty) {
        var client_id = result['response']['client_id'];
        var preferenceId = result['response']['id'];
        print("uday");
        print(result);
        print(result['response']['init_point']);

        final bool isDone = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => MercadoPagoScreen(
                    initialURl: result['response']['init_point'])));
        print(isDone);
        print(result.toString());
        print(preferenceId);

        if (isDone) {
          placeParcelOrder();
          ScaffoldMessenger.of(_globalKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment Successful!!\n".tr()),
            backgroundColor: Colors.green,
          ));
        } else {
          Navigator.pop(_globalKey.currentContext!);
          ScaffoldMessenger.of(_globalKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment UnSuccessful!!\n".tr()),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        hideProgress();
        Navigator.pop(_globalKey.currentContext!);
        ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
          content: Text("Error while transaction!".tr()),
          backgroundColor: Colors.red,
        ));
      }
    });
  }

  ///PayPal payment function

  /*final _flutterPaypalNativePlugin = FlutterPaypalNative.instance;
  paypalPaymentSheet({required amount}) {
    //add 1 item to cart. Max is 4!
    if (_flutterPaypalNativePlugin.canAddMorePurchaseUnit) {
      _flutterPaypalNativePlugin.addPurchaseUnit(
        FPayPalPurchaseUnit(
          // random prices
          amount: double.parse(amount),

          ///please use your own algorithm for referenceId. Maybe ProductID?
          referenceId: FPayPalStrHelper.getRandomString(16),
        ),
      );
    }
    // initPayPal();
    _flutterPaypalNativePlugin.makeOrder(
      //action: FPayPalUserAction.payNow,
    );
  }*/

  // _makePaypalPayment({required amount}) async {
  //   PayPalClientTokenGen.paypalClientToken(
  //           paypalSettingData: paypalSettingData!)
  //       .then((value) async {
  //     final String tokenizationKey =
  //         paypalSettingData!.braintree_tokenizationKey;
  //
  //     var request = BraintreePayPalRequest(
  //         amount: amount,
  //         currencyCode: currencyData!.code,
  //         billingAgreementDescription: "djsghxghf",
  //         displayName: PAYID);
  //
  //     BraintreePaymentMethodNonce? resultData;
  //     try {
  //       resultData =
  //           await Braintree.requestPaypalNonce(tokenizationKey, request);
  //     } on Exception {
  //       print("Stripe error");
  //       showAlert(_globalKey.currentContext!,
  //           response: "contact-admin".tr(), colors: Colors.red);
  //     }
  //     print(resultData?.nonce);
  //     print(resultData?.paypalPayerId);
  //     if (resultData?.nonce != null) {
  //       PayPalClientTokenGen.paypalSettleAmount(
  //         paypalSettingData: paypalSettingData!,
  //         nonceFromTheClient: resultData?.nonce,
  //         amount: amount,
  //         deviceDataFromTheClient: resultData?.typeLabel,
  //       ).then((value) {
  //         print('payment done!!');
  //         if (value['success'] == "true" || value['success'] == true) {
  //           if (value['data']['success'] == "true" ||
  //               value['data']['success'] == true) {
  //             payPalSettel.PayPalClientSettleModel settleResult =
  //                 payPalSettel.PayPalClientSettleModel.fromJson(value);
  //             placeParcelOrder();
  //             ScaffoldMessenger.of(_globalKey.currentContext!)
  //                 .showSnackBar(SnackBar(
  //               content: Text(
  //                 "Status".tr() +
  //                     " : ${settleResult.data.transaction.status}\n"
  //                         "Transaction id : ${settleResult.data.transaction.id}\n"
  //                         "Amount : ${settleResult.data.transaction.amount}",
  //               ),
  //               duration: const Duration(seconds: 8),
  //               backgroundColor: Colors.green,
  //             ));
  //           } else {
  //             print(value);
  //             payPalCurrModel.PayPalCurrencyCodeErrorModel settleResult =
  //                 payPalCurrModel.PayPalCurrencyCodeErrorModel.fromJson(value);
  //             Navigator.pop(_globalKey.currentContext!);
  //             ScaffoldMessenger.of(_globalKey.currentContext!)
  //                 .showSnackBar(SnackBar(
  //               content:
  //                   Text("Status".tr() + " : ${settleResult.data.message}"),
  //               duration: const Duration(seconds: 8),
  //               backgroundColor: Colors.red,
  //             ));
  //           }
  //         } else {
  //           PayPalErrorSettleModel settleResult =
  //               PayPalErrorSettleModel.fromJson(value);
  //           Navigator.pop(_globalKey.currentContext!);
  //           ScaffoldMessenger.of(_globalKey.currentContext!)
  //               .showSnackBar(SnackBar(
  //             content: Text("Status".tr() + " : ${settleResult.data.message}"),
  //             duration: const Duration(seconds: 8),
  //             backgroundColor: Colors.red,
  //           ));
  //         }
  //       });
  //     } else {
  //       Navigator.pop(_globalKey.currentContext!);
  //       ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
  //         content: Text("Status : Payment Incomplete!!".tr()),
  //         duration: const Duration(seconds: 8),
  //         backgroundColor: Colors.red,
  //       ));
  //     }
  //   });
  // }

  ///Paytm payment function
  getPaytmCheckSum(
    context, {
    required double amount,
  }) async {
    final String orderId = await UserPreference.getPaymentId();
    print(orderId);
    print('here order ID');
    String getChecksum = "${GlobalURL}payments/getpaytmchecksum";
    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmSettingData?.PaytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY,
        });

    final data = jsonDecode(response.body);
    print(data);
    await verifyCheckSum(
            checkSum: data["code"], amount: amount, orderId: orderId)
        .then((value) {
      initiatePayment(amount: amount, orderId: orderId).then((value) {
        if (value != null) {
          print(value);
          GetPaymentTxtTokenModel result = value;
          String callback = "";
          if (paytmSettingData!.isSandboxEnabled) {
            callback = callback +
                "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
          } else {
            callback = callback +
                "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
          }

          _startTransaction(context,
              txnTokenBy: result.body.txnToken,
              orderId: orderId,
              amount: amount,
              callBackURL: callback);
        }
      });
    });
  }

  Future<void> _startTransaction(
    context, {
    required String txnTokenBy,
    required orderId,
    required double amount,
    required callBackURL,
  }) async {
    try {
      var response = AllInOneSdk.startTransaction(
        paytmSettingData!.PaytmMID,
        orderId,
        amount.toString(),
        txnTokenBy,
        callBackURL,
        isStaging,
        true,
        enableAssist,
      );

      response.then((value) {
        if (value!["RESPMSG"] == "Txn Success") {
          print("txt done!!");
          print(amount);
          placeParcelOrder();
          showAlert(context,
              response: "Payment Successful!!\n".tr() + "${value['RESPMSG']}",
              colors: Colors.green);
        }
      }).catchError((onError) {
        if (onError is PlatformException) {
          print("======>>1");
          Navigator.pop(_globalKey.currentContext!);

          print("Error124 : $onError");
          result =
              onError.message.toString() + " \n  " + onError.code.toString();
          showAlert(_globalKey.currentContext!,
              response: onError.message.toString(), colors: Colors.red);
        } else {
          print("======>>2");

          result = onError.toString();
          Navigator.pop(_globalKey.currentContext!);
          showAlert(_globalKey.currentContext!,
              response: result, colors: Colors.red);
        }
      });
    } catch (err) {
      print("======>>3");
      result = err.toString();
      Navigator.pop(_globalKey.currentContext!);
      showAlert(_globalKey.currentContext!,
          response: result, colors: Colors.red);
    }
  }

  Future<GetPaymentTxtTokenModel> initiatePayment(
      {required double amount, required orderId}) async {
    String initiateURL = "${GlobalURL}payments/initiatepaytmpayment";

    String callback = "";
    if (paytmSettingData!.isSandboxEnabled) {
      callback = callback +
          "https://securegw-stage.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    } else {
      callback = callback +
          "https://securegw.paytm.in/theia/paytmCallback?ORDER_ID=$orderId";
    }
    final response =
        await http.post(Uri.parse(initiateURL), headers: {}, body: {
      "mid": paytmSettingData?.PaytmMID,
      "order_id": orderId,
      "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY.toString(),
      "amount": amount.toString(),
      "currency": currencyData!.code,
      "callback_url": callback,
      "custId": MyAppState.currentUser!.userID,
      "issandbox": paytmSettingData!.isSandboxEnabled ? "1" : "2",
    });
    // print(response.body);
    final data = jsonDecode(response.body);
    if (data["body"]["txnToken"] == null ||
        data["body"]["txnToken"].toString().isEmpty) {
      Navigator.pop(_globalKey.currentContext!);
      showAlert(_globalKey.currentContext!,
          response: "contact-admin", colors: Colors.red);
    }
    return GetPaymentTxtTokenModel.fromJson(data);
  }

  Future verifyCheckSum(
      {required String checkSum,
      required double amount,
      required orderId}) async {
    String getChecksum = "${GlobalURL}payments/validatechecksum";
    final response = await http.post(
        Uri.parse(
          getChecksum,
        ),
        headers: {},
        body: {
          "mid": paytmSettingData?.PaytmMID,
          "order_id": orderId,
          "key_secret": paytmSettingData?.PAYTM_MERCHANT_KEY,
          "checksum_value": checkSum,
        });
    final data = jsonDecode(response.body);
    return data['status'];
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    print(response.orderId);
    print(response.paymentId);

    placeParcelOrder();
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Successful!!\n".tr() + response.orderId!,
      ),
      backgroundColor: Colors.green.shade400,
      duration: const Duration(seconds: 6),
    ));
  }

  void _handleExternalWaller(ExternalWalletResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Proccessing Via\n".tr() + response.walletName!,
      ),
      backgroundColor: Colors.blue.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Navigator.pop(_globalKey.currentContext!);
    print(response.code);
    RazorPayFailedModel lom =
        RazorPayFailedModel.fromJson(jsonDecode(response.message!.toString()));
    ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
      content: Text(
        "Payment Failed!!\n".tr() + lom.error.description,
      ),
      backgroundColor: Colors.red.shade400,
      duration: const Duration(seconds: 8),
    ));
  }

  ///FlutterWave Payment Method
  String? _ref;

  setRef() {
    Random numRef = Random();
    int year = DateTime.now().year;
    int refNumber = numRef.nextInt(20000);
    if (Platform.isAndroid) {
      setState(() {
        _ref = "AndroidRef$year$refNumber";
      });
    } else if (Platform.isIOS) {
      setState(() {
        _ref = "IOSRef$year$refNumber";
      });
    }
  }

  _flutterWaveInitiatePayment(
    BuildContext context,
  ) async {
    final style = FlutterwaveStyle(
      appBarText: PAYID,
      buttonColor: Color(COLOR_PRIMARY),
      buttonTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
      ),
      appBarColor: Color(COLOR_PRIMARY),
      dialogCancelTextStyle: const TextStyle(
        color: Colors.black,
        fontSize: 18,
      ),
      dialogContinueTextStyle: TextStyle(
        color: Color(COLOR_PRIMARY),
        fontSize: 18,
      ),
      mainTextStyle:
          const TextStyle(color: Colors.black, fontSize: 19, letterSpacing: 2),
      dialogBackgroundColor: Colors.white,
      appBarTitleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 18,
      ),
    );
    final flutterwave = Flutterwave(
      amount: getTotalAmount().toString().trim(),
      currency: currencyData!.code,
      style: style,
      customer: Customer(
          name: MyAppState.currentUser!.firstName,
          phoneNumber: MyAppState.currentUser!.phoneNumber.trim(),
          email: MyAppState.currentUser!.email.trim()),
      context: context,
      publicKey: flutterWaveSettingData!.publicKey.trim(),
      paymentOptions: "card, payattitude",
      customization: Customization(title: PAYID),
      txRef: _ref!,
      isTestMode: flutterWaveSettingData!.isSandbox,
      redirectUrl: '${GlobalURL}success',
    );
    final ChargeResponse response = await flutterwave.charge();
    if (response.success!) {
      placeParcelOrder();
      ScaffoldMessenger.of(_globalKey.currentContext!).showSnackBar(SnackBar(
        content: Text("Payment Successful!!\n".tr()),
        backgroundColor: Colors.green,
      ));
    } else {
      showLoading(message: response.status!);
    }
    print("${response.toJson()}");
  }

  Future<void> showLoading(
      {required String message, Color txtColor = Colors.black}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Container(
            margin: const EdgeInsets.fromLTRB(30, 20, 30, 20),
            width: double.infinity,
            height: 30,
            child: Text(
              message,
              style: TextStyle(color: txtColor),
            ),
          ),
        );
      },
    );
  }

  ///PayStack Payment Method
  payStackPayment(BuildContext context) async {
    await PayStackURLGen.payStackURLGen(
      amount: (getTotalAmount() * 100).toString(),
      currency: currencyData!.code,
      secretKey: payStackSettingData!.secretKey,
    ).then((value) async {
      if (value != null) {
        PayStackUrlModel _payStackModel = value;
        bool isDone = await Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => PayStackScreen(
                  secretKey: payStackSettingData!.secretKey,
                  callBackUrl: payStackSettingData!.callbackURL,
                  initialURl: _payStackModel.data.authorizationUrl,
                  amount: getTotalAmount().toString(),
                  reference: _payStackModel.data.reference,
                )));
        //Navigator.pop(_globalKey.currentContext!);

        if (isDone) {
          placeParcelOrder();
          ScaffoldMessenger.of(_globalKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment Successful!!\n".tr()),
            backgroundColor: Colors.green,
          ));
        } else {
          Navigator.pop(_globalKey.currentContext!);
          ScaffoldMessenger.of(_globalKey.currentContext!)
              .showSnackBar(SnackBar(
            content: Text("Payment UnSuccessful!!\n".tr()),
            backgroundColor: Colors.red,
          ));
        }
      } else {
        Navigator.pop(_globalKey.currentContext!);
        showAlert(_globalKey.currentContext!,
            response: "Something went wrong, please contact admin.".tr(),
            colors: Colors.red);
      }
    });
  }

  final GlobalKey<ScaffoldState> _globalKey = GlobalKey<ScaffoldState>();

  showLoadingAlert() {
    return showDialog<void>(
      context: _globalKey.currentContext!,
      useRootNavigator: true,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const CircularProgressIndicator(),
              const Text('Please wait!!').tr(),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                const SizedBox(
                  height: 15,
                ),
                Text(
                  'Please wait!! while completing Transaction'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(
                  height: 15,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
