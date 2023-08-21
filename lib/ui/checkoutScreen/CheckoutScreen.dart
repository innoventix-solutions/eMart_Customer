import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/OrderModel.dart';
import 'package:emartconsumer/model/ProductModel.dart';
import 'package:emartconsumer/model/TaxModel.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/ui/placeOrderScreen/PlaceOrderScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckoutScreen extends StatefulWidget {
  final String paymentOption, paymentType;
  final double total;
  final double? discount;
  final String? couponCode;
  final String? couponId, notes;
  final List<CartProduct> products;
  final List<String>? extra_addons;
  final String? extra_size;
  final String? tipValue;
  final bool? take_away;
  final String? deliveryCharge;
  final String? size;
  final bool isPaymentDone;
  final TaxModel? taxModel;
  final Map<String, dynamic>? specialDiscountMap;

  const CheckoutScreen(
      {Key? key,
      required this.isPaymentDone,
      required this.paymentOption,
      required this.paymentType,
      required this.total,
      this.discount,
      this.couponCode,
      this.couponId,
      this.notes,
      required this.products,
      this.extra_addons,
      this.extra_size,
      this.tipValue,
      this.take_away,
      this.deliveryCharge,
      this.taxModel,
      this.specialDiscountMap,
      this.size})
      : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final fireStoreUtils = FireStoreUtils();
  late Map<String, dynamic>? adminCommission;
  String? adminCommissionValue = "", addminCommissionType = "";
  bool? isEnableAdminCommission = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    placeAutoOrder();
  }

  placeAutoOrder() async {
    await fireStoreUtils.getAdminCommission().then((value) {
      if (value != null) {
        setState(() {
          adminCommission = value;
          adminCommissionValue = adminCommission!["adminCommission"].toString();
          addminCommissionType = adminCommission!["adminCommissionType"].toString();
          isEnableAdminCommission = adminCommission!["isAdminCommission"];
          print(adminCommission!["adminCommission"].toString() + "===____");
          print(adminCommission!["isAdminCommission"].toString() + "===____" + isEnableAdminCommission.toString());
        });
      }
    });

    if (widget.isPaymentDone) {
      placeOrder();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode(context) ? Colors.grey.shade900 : Colors.grey.shade50,
      appBar: AppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Checkout'.tr(),
              style: TextStyle(fontSize: 25, color: isDarkMode(context) ? Colors.grey.shade300 : Colors.grey.shade800, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                Container(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  child: ListTile(
                    leading: Text(
                      'Payment'.tr(),
                      style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    trailing: Text(
                      widget.paymentOption,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const Divider(
                  height: 3,
                ),
                Container(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Deliver to'.tr(),
                          style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 2,
                          child: Text(
                            '${MyAppState.currentUser!.shippingAddress.line1} ${MyAppState.currentUser!.shippingAddress.line2}',
                            textAlign: TextAlign.end,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(
                  height: 3,
                ),
                Container(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  child: ListTile(
                    leading: Text(
                      'Total'.tr(),
                      style: TextStyle(color: Color(COLOR_PRIMARY), fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    trailing: Text(
                      symbol + widget.total.toDouble().toStringAsFixed(decimal),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
              ],
              shrinkWrap: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(20),
                backgroundColor: Color(COLOR_PRIMARY),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (!widget.isPaymentDone) {
                  placeOrder();
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Visibility(
                      visible: widget.isPaymentDone,
                      child: const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                          ))),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    'PLACE ORDER'.tr(),
                    style: TextStyle(color: isDarkMode(context) ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> setPrefData() async {
    SharedPreferences sp = await SharedPreferences.getInstance();

    sp.setString("musics_key", "");
    sp.setString("addsize", "");
  }

  placeOrder() async {
    FireStoreUtils fireStoreUtils = FireStoreUtils();
    //place order
    List<CartProduct> tempProduc = [];

    for (CartProduct cartProduct in widget.products) {
      CartProduct tempCart = cartProduct;
      tempProduc.add(tempCart);
    }
    showProgress(context, 'Placing Order...'.tr(), false);
    VendorModel vendorModel = await fireStoreUtils.getVendorByVendorID(widget.products.first.vendorID).whenComplete(() => setPrefData());
    log(vendorModel.fcmToken.toString() + "{}{}{}{======TOKENADD" + vendorModel.toJson().toString());

    OrderModel orderModel = OrderModel(
      address: MyAppState.currentUser!.shippingAddress,
      author: MyAppState.currentUser,
      authorID: MyAppState.currentUser!.userID,
      createdAt: Timestamp.now(),
      products: tempProduc,
      status: ORDER_STATUS_PLACED,
      vendor: vendorModel,
      vendorID: widget.products.first.vendorID,
      discount: widget.discount,
      couponCode: widget.couponCode,
      couponId: widget.couponId,
      notes: widget.notes,
      payment_method: widget.paymentType,
      tipValue: widget.tipValue,
      sectionId: SELECTED_CATEGORY,
      adminCommission: isEnableAdminCommission! ? adminCommissionValue : "0",
      adminCommissionType: isEnableAdminCommission! ? addminCommissionType : "",
      taxModel: widget.taxModel,
      takeAway: widget.take_away,
      deliveryCharge: widget.deliveryCharge,
      specialDiscount: widget.specialDiscountMap,
    );

    OrderModel placedOrder = await fireStoreUtils.placeOrder(orderModel);
    print("||||{}" + orderModel.toJson().toString());

    for (int i = 0; i < tempProduc.length; i++) {
      await FireStoreUtils().getProductByID(tempProduc[i].id.split('~').first).then((value) async {
        ProductModel? productModel = value;
        if (tempProduc[i].variant_info != null) {
          for (int j = 0; j < productModel.itemAttributes!.variants!.length; j++) {
            if (productModel.itemAttributes!.variants![j].variant_id == tempProduc[i].id.split('~').last) {
              if (productModel.itemAttributes!.variants![j].variant_quantity != "-1") {
                productModel.itemAttributes!.variants![j].variant_quantity = (int.parse(productModel.itemAttributes!.variants![j].variant_quantity.toString()) - tempProduc[i].quantity).toString();
              }
            }
          }
        } else {
          if (productModel.quantity != -1) {
            productModel.quantity = productModel.quantity - tempProduc[i].quantity;
          }
        }

        await FireStoreUtils.updateProduct(productModel).then((value) {
          log("-----------2>${value!.toJson()}");
        });
      });
    }
    hideProgress();
    print('_CheckoutScreenState.placeOrder ${placedOrder.id}');
    showModalBottomSheet(
      isScrollControlled: true,
      isDismissible: false,
      context: context,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceOrderScreen(orderModel: placedOrder),
    );
  }
}
