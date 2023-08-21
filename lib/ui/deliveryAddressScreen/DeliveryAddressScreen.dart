import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/main.dart';
import 'package:emartconsumer/model/AddressModel.dart';
import 'package:emartconsumer/model/DeliveryChargeModel.dart';
import 'package:emartconsumer/model/TaxModel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/model/VendorModel.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:emartconsumer/services/localDatabase.dart';
import 'package:emartconsumer/ui/payment/PaymentScreen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:place_picker/place_picker.dart';

class DeliveryAddressScreen extends StatefulWidget {
  static const kInitialPosition = LatLng(-33.8567844, 151.213108);

  final double total;
  final double? discount;
  final String? couponCode;
  final String? couponId;
  final String? notes;
  final List<CartProduct> products;
  final List<String>? extra_addons;
  final String? extra_size;
  final String? tipValue;

  // final String? orderNotes;
  final String? deliveryCharge;
  final bool? take_away;
  final TaxModel? taxModel;
  final Map<String, dynamic>? specialDiscountMap;

  const DeliveryAddressScreen(
      {Key? key,
      required this.total,
      this.discount,
      this.couponCode,
      this.couponId,
      this.specialDiscountMap,
      required this.products,
      this.extra_addons,
      this.extra_size,
      this.tipValue,
      this.take_away,
      this.deliveryCharge,
      this.taxModel,
      this.notes})
      : super(key: key);

  @override
  _DeliveryAddressScreenState createState() => _DeliveryAddressScreenState();
}

class _DeliveryAddressScreenState extends State<DeliveryAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  // String? line1, line2, zipCode, city;
  String? country;
  var street = TextEditingController();
  var street1 = TextEditingController();
  var landmark = TextEditingController();
  var landmark1 = TextEditingController();
  var zipcode = TextEditingController();
  var zipcode1 = TextEditingController();
  var city = TextEditingController();
  var city1 = TextEditingController();
  var cutries = TextEditingController();
  var cutries1 = TextEditingController();
  var lat;
  var long;

  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
    street.dispose();
    landmark.dispose();
    city.dispose();
    // cutries.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MyAppState.currentUser!.shippingAddress.country != '' ? country = MyAppState.currentUser!.shippingAddress.country : null;
    street.text = MyAppState.currentUser!.shippingAddress.line1;
    landmark.text = MyAppState.currentUser!.shippingAddress.line2;
    city.text = MyAppState.currentUser!.shippingAddress.city;
    zipcode.text = MyAppState.currentUser!.shippingAddress.postalCode;
    cutries.text = MyAppState.currentUser!.shippingAddress.country;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Delivery Address'.tr(),
          style: TextStyle(color: isDarkMode(context) ? Colors.white : Colors.black),
        ).tr(),
      ),
      body: Container(
          color: isDarkMode(context) ? null : const Color(0XFFF1F4F7),
          child: Form(
              key: _formKey,
              autovalidateMode: _autoValidateMode,
              child: SingleChildScrollView(
                  child: Column(children: [
                const SizedBox(
                  height: 40,
                ),
                Card(
                  elevation: 0.5,
                  color: isDarkMode(context) ? const Color(DARK_BG_COLOR) : const Color(0XFFFFFFFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.only(left: 20, right: 20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 10),
                        child: TextFormField(
                            // controller: street,
                            controller: street1.text.isEmpty ? street : street1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            // onSaved: (text) => line1 = text,
                            onSaved: (text) => street.text = text!,
                            style: const TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue:
                            //     MyAppState.currentUser!.shippingAddress.line1,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              labelText: 'Street 1'.tr(),
                              labelStyle: const TextStyle(color: Color(0Xff696A75), fontSize: 17),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            )),
                      ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 10),
                        child: TextFormField(
                          // controller: _controller,
                          controller: landmark1.text.isEmpty ? landmark : landmark1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => landmark.text = text!,
                          style: const TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.streetAddress,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue:
                          //     MyAppState.currentUser!.shippingAddress.line2,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Landmark'.tr(),
                            labelStyle: const TextStyle(color: Color(0Xff696A75), fontSize: 17),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Zip Code'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                        padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 10),
                        child: TextFormField(
                          controller: zipcode1.text.isEmpty ? zipcode : zipcode1,
                          textAlignVertical: TextAlignVertical.center,
                          textInputAction: TextInputAction.next,
                          validator: validateEmptyField,
                          onSaved: (text) => zipcode.text = text!,
                          style: const TextStyle(fontSize: 18.0),
                          keyboardType: TextInputType.phone,
                          cursorColor: Color(COLOR_PRIMARY),
                          // initialValue: MyAppState
                          //     .currentUser!.shippingAddress.postalCode,
                          decoration: InputDecoration(
                            // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                            labelText: 'Zip Code'.tr(),
                            labelStyle: const TextStyle(color: Color(0Xff696A75), fontSize: 17),
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                            ),
                            errorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            focusedErrorBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Theme.of(context).errorColor),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                              // borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                        ),
                      ),
                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'City'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),
                      Container(
                          padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 10),
                          child: TextFormField(
                            controller: city1.text.isEmpty ? city : city1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            onSaved: (text) => city.text = text!,
                            style: const TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue:
                            //     MyAppState.currentUser!.shippingAddress.city,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              labelText: 'City'.tr(),
                              labelStyle: const TextStyle(color: Color(0Xff696A75), fontSize: 17),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          )),

                      Container(
                          padding: const EdgeInsetsDirectional.only(start: 20, end: 20, bottom: 10),
                          child: TextFormField(
                            controller: cutries1.text.isEmpty ? cutries : cutries1,
                            textAlignVertical: TextAlignVertical.center,
                            textInputAction: TextInputAction.next,
                            validator: validateEmptyField,
                            onSaved: (text) => cutries.text = text!,
                            style: const TextStyle(fontSize: 18.0),
                            keyboardType: TextInputType.streetAddress,
                            cursorColor: Color(COLOR_PRIMARY),
                            // initialValue:
                            //     MyAppState.currentUser!.shippingAddress.city,
                            decoration: InputDecoration(
                              // contentPadding: EdgeInsets.symmetric(horizontal: 24),
                              labelText: 'Country'.tr(),
                              labelStyle: const TextStyle(color: Color(0Xff696A75), fontSize: 17),
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(COLOR_PRIMARY)),
                              ),
                              errorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              focusedErrorBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Theme.of(context).errorColor),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0XFFB1BCCA)),
                                // borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                          )),

                      // ListTile(
                      //   contentPadding:
                      //       const EdgeInsetsDirectional.only(start: 40, end: 30, top: 24),
                      //   leading: Container(
                      //     // width: 0,
                      //     child: Text(
                      //       'Country'.tr(),
                      //       style: TextStyle(fontSize: 16),
                      //     ),
                      //   ),
                      // ),

                      // ListTile(
                      //     contentPadding: const EdgeInsetsDirectional.only(
                      //         start: 5, end: 10),
                      //     subtitle: Padding(
                      //         padding: EdgeInsets.only(left: 16, right: 10),
                      //         child: Divider(
                      //           color: Color(0XFFB1BCCA),
                      //           thickness: 1.5,
                      //         )),
                      //     title: ButtonTheme(
                      //         alignedDropdown: true,
                      //         child: DropdownButtonHideUnderline(
                      //             child: DropdownButton<String>(
                      //           icon: Icon(Icons.keyboard_arrow_down_outlined),
                      //           hint: country == null
                      //               ? Text('Country'.tr())
                      //               : Text(
                      //                   country!,
                      //                   style: TextStyle(
                      //                       color: Color(COLOR_PRIMARY)),
                      //                 ),
                      //           items: <String>[
                      //             'USA',
                      //             'UK',
                      //             'India',
                      //             'France',
                      //             'Russia',
                      //             'Japan',
                      //             'UAE',
                      //             'Qatar',
                      //             'Netherland',
                      //             'Canada'
                      //           ].map((String value) {
                      //             return DropdownMenuItem<String>(
                      //               value: value,
                      //               child: Text(value),
                      //             );
                      //           }).toList(),
                      //           isExpanded: true,
                      //           iconSize: 30.0,
                      //           onChanged: (value) {
                      //             setState(() {
                      //               country = value;
                      //             });
                      //           },
                      //         )))
                      // ),
                      // leading: Container(
                      //   width: 60,
                      //   child: Text(
                      //     'Country'.tr(),
                      //     style: TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      // ),
                      // title: TextFormField(
                      //   textAlignVertical: TextAlignVertical.center,
                      //   textInputAction: TextInputAction.done,
                      //   validator: validateEmptyField,
                      //   onFieldSubmitted: (_) => validateForm(),
                      //   maxLength: 2,
                      //   onSaved: (text) => country = text,
                      //   style: TextStyle(fontSize: 18.0),
                      //   keyboardType: TextInputType.streetAddress,
                      //   cursorColor: Color(COLOR_PRIMARY),
                      //   initialValue: MyAppState.currentUser!.shippingAddress.country,
                      //   decoration: InputDecoration(
                      //     contentPadding: EdgeInsets.symmetric(horizontal: 24),
                      //     hintText: 'UK'.tr(),
                      //     hintStyle: TextStyle(color: Colors.grey.shade400),
                      //     focusedBorder: OutlineInputBorder(
                      //       borderRadius: BorderRadius.circular(8.0),
                      //       borderSide:
                      //           BorderSide(color: Color(COLOR_PRIMARY), width: 2.0),
                      //     ),
                      //     errorBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Theme.of(context).errorColor),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     focusedErrorBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Theme.of(context).errorColor),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //     enabledBorder: OutlineInputBorder(
                      //       borderSide: BorderSide(color: Colors.grey.shade300),
                      //       borderRadius: BorderRadius.circular(8.0),
                      //     ),
                      //   ),
                      // ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Card(
                            child: ListTile(
                                leading: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // ImageIcon(
                                    //   AssetImage('assets/images/current_location1.png'),
                                    //   size: 23,
                                    //   color: Color(COLOR_PRIMARY),
                                    // ),
                                    Icon(
                                      Icons.location_searching_rounded,
                                      color: Color(COLOR_PRIMARY),
                                    ),
                                  ],
                                ),
                                title: Text(
                                  "Current Location".tr(),
                                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                                ),
                                subtitle: Text(
                                  "Using GPS".tr(),
                                  style: TextStyle(color: Color(COLOR_PRIMARY)),
                                ),
                                onTap: () async {
                                  LocationResult result = await Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlacePicker(GOOGLE_API_KEY)));

                                  street1.text = result.name.toString();
                                  landmark1.text = result.subLocalityLevel1!.name == null ? result.subLocalityLevel2!.name.toString() : result.subLocalityLevel1!.name.toString();
                                  city1.text = result.city!.name.toString();
                                  cutries1.text = result.country!.name.toString();
                                  zipcode1.text = result.postalCode.toString();
                                  lat = result.latLng!.latitude;
                                  long = result.latLng!.longitude;

                                  MyAppState.currentUser!.shippingAddress.location.latitude = result.latLng!.latitude;
                                  MyAppState.currentUser!.shippingAddress.location.longitude = result.latLng!.longitude;
                                  getDeliveyData();
                                  setState(() {});
                                })),
                      ),

                      const SizedBox(
                        height: 40,
                      ),

                      Visibility(
                        child: Text("new-delivery-charge".tr() + symbol + deliveryCharges,
                            style: const TextStyle()),
                        visible: isLocationChange,
                      ),
                    ],
                  ),
                ),
                const SizedBox()
              ])))),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 25),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(15),
            backgroundColor: Color(COLOR_PRIMARY),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: () => validateForm(),
          child: Text(
            'Continue'.tr(),
            style: TextStyle(color: isDarkMode(context) ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }

  VendorModel? vendorModel;
  var deliveryCharges = "0.0";
  bool isLocationChange = false;

  getDeliveyData() async {
    if (serviceTypeFlag == "ecommerce-service") {
      deliveryCharges = "50";
    } else {
      if (!widget.take_away!) {
        await FireStoreUtils().getVendorByVendorID(widget.products.first.vendorID).then((value) {
          vendorModel = value;
        });
        num km = num.parse(getKm(Position.fromMap({'latitude': lat, 'longitude': long}), Position.fromMap({'latitude': vendorModel!.latitude, 'longitude': vendorModel!.longitude})));
        await FireStoreUtils().getDeliveryCharges().then((value) {
          if (value != null) {
            DeliveryChargeModel deliveryChargeModel = value;

            if (!deliveryChargeModel.vendor_can_modify) {
              if (km > deliveryChargeModel.minimum_delivery_charges_within_km) {
                deliveryCharges = (km * deliveryChargeModel.delivery_charges_per_km).toDouble().toStringAsFixed(decimal);
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                  widget.deliveryCharge != deliveryCharges.toString();
                }
                setState(() {});
              } else {
                deliveryCharges = deliveryChargeModel.minimum_delivery_charges.toDouble().toStringAsFixed(decimal);
                if (widget.deliveryCharge != deliveryCharges) {
                  isLocationChange = true;
                  widget.deliveryCharge != deliveryCharges.toString();
                }
                setState(() {});
              }
            } else {
              if (vendorModel != null && vendorModel!.DeliveryCharge != null) {
                if (km > vendorModel!.DeliveryCharge!.minimum_delivery_charges_within_km) {
                  deliveryCharges = (km * vendorModel!.DeliveryCharge!.delivery_charges_per_km).toDouble().toStringAsFixed(decimal);
                  if (widget.deliveryCharge != deliveryCharges) {
                    isLocationChange = true;
                    widget.deliveryCharge != deliveryCharges.toString();
                  }
                  setState(() {});
                } else {
                  deliveryCharges = vendorModel!.DeliveryCharge!.minimum_delivery_charges.toDouble().toStringAsFixed(decimal);
                  if (widget.deliveryCharge != deliveryCharges) {
                    isLocationChange = true;
                    widget.deliveryCharge != deliveryCharges.toString();
                  }
                  setState(() {});
                }
              } else {
                if (km > deliveryChargeModel.minimum_delivery_charges_within_km) {
                  deliveryCharges = (km * deliveryChargeModel.delivery_charges_per_km).toDouble().toStringAsFixed(decimal);
                  if (widget.deliveryCharge != deliveryCharges) {
                    isLocationChange = true;
                    widget.deliveryCharge != deliveryCharges.toString();
                  }
                  setState(() {});
                } else {
                  deliveryCharges = deliveryChargeModel.minimum_delivery_charges.toDouble().toStringAsFixed(decimal);
                  if (widget.deliveryCharge != deliveryCharges) {
                    isLocationChange = true;
                    widget.deliveryCharge != deliveryCharges.toString();
                  }
                  setState(() {});
                }
              }
            }
          }
        });
      }
    }
  }

  validateForm() async {
    Position? locationData;
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState!.save();
      // if (country == null) {
      //   showDialog(
      //     context: context,
      //     builder: (BuildContext context) => ShowDialogToDismiss(
      //       title: 'Error'.tr(),
      //       content: 'Please Select Country'.tr(),
      //       buttonText: 'CLOSE'.tr(),
      //     ),
      //   );
      // } else
      {
        showProgress(context, 'Saving Address...'.tr(), true);

        MyAppState.currentUser!.location = UserLocation(
          latitude: lat ??
              (MyAppState.currentUser!.shippingAddress.location.latitude == 0.01
                  ? showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          content: const Text("select-current-location").tr(),
                          actions: [
                            // FlatButton(
                            //   onPressed: () => Navigator.pop(
                            //       context, false), // passing false
                            //   child: Text('No'),
                            // ),
                            TextButton(
                              onPressed: () {
                                hideProgress();
                                Navigator.pop(context, true);
                              }, // passing true
                              child: const Text('OK').tr(),
                            ),
                          ],
                        );
                      }).then((exit) {
                      if (exit == null) return;

                      if (exit) {
                        // user pressed Yes button
                      } else {
                        // user pressed No button
                      }
                    })
                  : MyAppState.currentUser!.shippingAddress.location.latitude),
          longitude: long ??
              (MyAppState.currentUser!.shippingAddress.location.longitude == 0.01
                  ? showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (_) {
                        return AlertDialog(
                          content: const Text("select-current-location").tr(),
                          actions: [
                            // FlatButton(
                            //   onPressed: () => Navigator.pop(
                            //       context, false), // passing false
                            //   child: Text('No'),
                            // ),
                            TextButton(
                              onPressed: () {
                                hideProgress();
                                Navigator.pop(context, true);
                              }, // passing true
                              child: const Text('OK').tr(),
                            ),
                          ],
                        );
                      }).then((exit) {
                      if (exit == null) return;

                      if (exit) {
                        // user pressed Yes button
                      } else {
                        // user pressed No button
                      }
                    })
                  : MyAppState.currentUser!.shippingAddress.location.longitude),
          // locationData!.longitude,
        );

        AddressModel userAddress = AddressModel(
            name: MyAppState.currentUser!.fullName(),
            postalCode: zipcode.text.toString(),
            line1: street.text.toString(),
            line2: landmark.text.toString(),
            country: cutries.text.toString(),
            city: city.text.toString(),
            location: MyAppState.currentUser!.location,
            email: MyAppState.currentUser!.email.toString());
        MyAppState.currentUser!.shippingAddress = userAddress;
        await FireStoreUtils.updateCurrentUserAddress(userAddress);
        hideProgress();
        print("------->Tax ${widget.taxModel!.toJson()}");
        push(
          context,
          PaymentScreen(
            total: isLocationChange ? ((widget.total - num.parse(widget.deliveryCharge!)) + num.parse(deliveryCharges)) : widget.total,
            discount: widget.discount!,
            couponCode: widget.couponCode!,
            couponId: widget.couponId!,
            products: widget.products,
            extra_addons: widget.extra_addons,
            tipValue: widget.tipValue,
            take_away: widget.take_away,
            deliveryCharge: isLocationChange ? deliveryCharges.toString() : widget.deliveryCharge,
            notes: widget.notes,
            taxModel: widget.taxModel,
            specialDiscountMap: widget.specialDiscountMap,
          ),
        );
      }
    } else {
      setState(() {
        _autoValidateMode = AutovalidateMode.onUserInteraction;
      });
    }
  }
}
