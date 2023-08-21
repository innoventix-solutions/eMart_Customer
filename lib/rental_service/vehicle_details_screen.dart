import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/constants.dart';
import 'package:emartconsumer/model/Ratingmodel.dart';
import 'package:emartconsumer/model/User.dart';
import 'package:emartconsumer/rental_service/model/rental_order_model.dart';
import 'package:emartconsumer/services/FirebaseHelper.dart';
import 'package:emartconsumer/services/helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'rental_payment_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  User? driverDetails;
  RentalOrderModel? rentalOrderModel;

  VehicleDetailsScreen({Key? key, required this.driverDetails, this.rentalOrderModel}) : super(key: key);

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  User? driverDetails;

  late List<RatingModel> ratingproduct = [];

  @override
  void initState() {
    // TODO: implement initState
    setState(() {
      driverDetails = widget.driverDetails;
    });
    getReviewList();
    super.initState();
  }

  getReviewList() async {
    await FireStoreUtils().getReviewByDriverId(widget.driverDetails!.userID).then((value) {
      setState(() {
        ratingproduct = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          color: isDarkMode(context) ? Colors.black : const Color(0xffFFFFFF),
          child: Stack(children: [
            SizedBox(
                height: MediaQuery.of(context).size.height * 0.27,
                child: CachedNetworkImage(
                  imageUrl: driverDetails!.carInfo!.carImage!.isEmpty ? "" : driverDetails!.carInfo!.carImage!.first,
                  errorWidget: (context, url, error) => Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), image: DecorationImage(image: NetworkImage(placeholderImage), fit: BoxFit.cover)),
                  ),
                  placeholder: (context, url) => Center(
                      child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                  )),
                  fit: BoxFit.fitWidth,
                )),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: CircleAvatar(
                  backgroundColor: Colors.black54,
                  radius: 18,
                  child: Center(
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  )),
            ),
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.24),
              child: Container(
                height: MediaQuery.of(context).size.height,
                decoration: BoxDecoration(
                  color: isDarkMode(context) ? Colors.black : Colors.white,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                                child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("${driverDetails!.carName} ${driverDetails!.carMakes}", style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.orange.withOpacity(0.80), size: 16),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      driverDetails!.reviewsCount != 0 ? (driverDetails!.reviewsSum / driverDetails!.reviewsCount).toStringAsFixed(1) : 0.toString(),
                                      style: const TextStyle(letterSpacing: 2, fontWeight: FontWeight.w600),
                                    ),
                                    Text('(${driverDetails!.reviewsCount.toStringAsFixed(0)})',
                                        style: TextStyle(
                                          letterSpacing: 0.5,
                                          color: isDarkMode(context) ? Colors.white60 : const Color(0xff666666),
                                        )),
                                  ],
                                ),
                              ],
                            )),
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Car Rate ".tr(),
                                      style: const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      symbol + driverDetails!.carRate,
                                      style: TextStyle(color: Color(COLOR_PRIMARY), letterSpacing: 0.5, fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      "/" + "day".tr(),
                                      style: const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "Driver Rate ".tr(),
                                      style: const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      symbol + driverDetails!.driverRate,
                                      style: TextStyle(color: Color(COLOR_PRIMARY), letterSpacing: 0.5, fontWeight: FontWeight.w900),
                                    ),
                                    Text(
                                      "/" + "day".tr(),
                                      style: const TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 8,
                        ),
                        tabViewWidget(),
                        const SizedBox(
                          height: 8,
                        ),
                        tabString == "About"
                            ? aboutTabViewWidget()
                            : tabString == "Gallery"
                                ? gallaryTabViewWidget()
                                : reviewTabViewWidget(),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height * 0.06,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white, backgroundColor: Color(COLOR_PRIMARY), // foreground
                            ),
                            onPressed: () {
                              print(widget.rentalOrderModel!.pickupLatLong!.toJson());
                              push(
                                  context,
                                  RentalPaymentScreen(
                                    driverDetails: widget.driverDetails,
                                    rentalOrderModel: widget.rentalOrderModel,
                                  ));
                            },
                            child: Text(
                              'Continue'.tr().toUpperCase(),
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          ]),
        ),
      ),
    );
  }

  String tabString = "About";

  tabViewWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  tabString = "About";
                });
              },
              child: const Text('About').tr(),
              style: ElevatedButton.styleFrom(
                foregroundColor: tabString == "About" ? Colors.white : Colors.black,
                shape: const StadiumBorder(),
                elevation: 0,
                backgroundColor: tabString == "About" ? Color(COLOR_PRIMARY) : Colors.grey.withOpacity(0.30),
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  tabString = "Gallery";
                });
              },
              child: const Text('Gallery').tr(),
              style: ElevatedButton.styleFrom(
                foregroundColor: tabString == "Gallery" ? Colors.white : Colors.black,
                shape: const StadiumBorder(),
                elevation: 0,
                backgroundColor: tabString == "Gallery" ? Color(COLOR_PRIMARY) : Colors.grey.withOpacity(0.30),
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  tabString = "Review";
                });
              },
              child: const Text('Review').tr(),
              style: ElevatedButton.styleFrom(
                foregroundColor: tabString == "Review" ? Colors.white : Colors.black,
                shape: const StadiumBorder(),
                elevation: 0,
                backgroundColor: tabString == "Review" ? Color(COLOR_PRIMARY) : Colors.grey.withOpacity(0.30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  aboutTabViewWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Car Specs".tr(), style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
          const SizedBox(
            height: 15,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), border: Border.all(color: Colors.grey.withOpacity(0.30), width: 2.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Max Power".tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${driverDetails!.carInfo!.maxPower}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                          Text(
                            "hp".tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), border: Border.all(color: Colors.grey.withOpacity(0.30), width: 2.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "0-60 mph".tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${driverDetails!.carInfo!.mph}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                          Text(
                            "sec.".tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15.0), border: Border.all(color: Colors.grey.withOpacity(0.30), width: 2.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Top speed".tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                            "${driverDetails!.carInfo!.topSpeed}",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1),
                          ),
                          Text(
                            "mph".tr(),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 15,
          ),
          Text("Car Info".tr(), style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
          const SizedBox(
            height: 15,
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text("${driverDetails!.carInfo!.passenger} " + "Passenger".tr(), style: const TextStyle(letterSpacing: 1))
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.ac_unit,
                          size: 20,
                          color: driverDetails!.carInfo!.airConditioning == "No" ? Colors.red : Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text("Air Conditioner".tr(), style: TextStyle(letterSpacing: 1, color: driverDetails!.carInfo!.airConditioning == "No" ? Colors.red : Color(COLOR_PRIMARY)))
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.speed_rounded,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text("${driverDetails!.carInfo!.mileage}", style: const TextStyle(letterSpacing: 1))
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.local_gas_station_rounded,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          "${driverDetails!.carInfo!.fuelType}",
                          style: const TextStyle(letterSpacing: 1),
                        )
                      ],
                    )
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.door_back_door,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text("${driverDetails!.carInfo!.doors} " + "Door".tr(), style: const TextStyle(letterSpacing: 1))
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.account_tree_rounded,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text("${driverDetails!.carInfo!.gear}", style: const TextStyle(letterSpacing: 1))
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.local_gas_station_rounded,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text("${driverDetails!.carInfo!.fuelFilling}", style: const TextStyle(letterSpacing: 1))
                      ],
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 20,
                          color: Color(COLOR_PRIMARY),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          driverDetails!.carNumber,
                          style: const TextStyle(letterSpacing: 1),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 15,
          ),
          Visibility(
            visible: driverDetails!.companyId.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Renter Information".tr(), style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
                const SizedBox(
                  height: 15,
                ),
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0), border: Border.all(color: Colors.grey.withOpacity(0.30), width: 2.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        driverDetails!.profilePictureURL.isEmpty
                            ? const CircleAvatar(
                                radius: 22.0,
                                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor: Colors.transparent,
                              )
                            : CircleAvatar(
                                radius: 22.0,
                                backgroundImage: NetworkImage(driverDetails!.profilePictureURL.toString()),
                                backgroundColor: Colors.transparent,
                              ),
                        const SizedBox(
                          width: 5,
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverDetails!.companyName, style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(driverDetails!.companyAddress, style: const TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Visibility(
            visible: !driverDetails!.companyId.isNotEmpty,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Driver Information".tr(), style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
                const SizedBox(
                  height: 15,
                ),
                Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0), border: Border.all(color: Colors.grey.withOpacity(0.30), width: 2.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Row(
                      children: [
                        driverDetails!.profilePictureURL.isEmpty
                            ? const CircleAvatar(
                                radius: 22.0,
                                backgroundImage: AssetImage('assets/images/placeholder.jpg'),
                                backgroundColor: Colors.transparent,
                              )
                            : CircleAvatar(
                                radius: 22.0,
                                backgroundImage: NetworkImage(driverDetails!.profilePictureURL.toString()),
                                backgroundColor: Colors.transparent,
                              ),
                        const SizedBox(
                          width: 5,
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(driverDetails!.firstName + " " + driverDetails!.lastName, style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                const SizedBox(
                                  height: 4,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.call,
                                      color: Colors.grey,
                                      size: 18,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(driverDetails!.phoneNumber, style: const TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                  ],
                                )
                              ],
                            )
                          ],
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  gallaryTabViewWidget() {
    return driverDetails!.carInfo!.carImage!.isEmpty
        ? Center(
            child: const Text("No Image Found").tr(),
          )
        : GridView.builder(
            itemCount: driverDetails!.carInfo!.carImage!.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 0, crossAxisSpacing: 8, mainAxisExtent: 180),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: driverDetails!.carInfo!.carImage![index],
                    height: 60,
                    width: 60,
                    imageBuilder: (context, imageProvider) => Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    placeholder: (context, url) => Center(
                        child: CircularProgressIndicator.adaptive(
                      valueColor: AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                    )),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          );
  }

  reviewTabViewWidget() {
    return ratingproduct.isEmpty
        ? Center(
            child: const Text("No review Found").tr(),
          )
        : ListView.builder(
            itemCount: ratingproduct.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14.0), border: Border.all(color: Colors.grey.withOpacity(0.30), width: 2.0)),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ratingproduct[index].uname.toString(), style: const TextStyle(fontSize: 16, letterSpacing: 1, fontWeight: FontWeight.w600)),
                                const SizedBox(
                                  height: 4,
                                ),
                                RatingBar.builder(
                                  initialRating: double.parse(ratingproduct[index].rating.toString()),
                                  direction: Axis.horizontal,
                                  itemSize: 20,
                                  itemPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                                  itemBuilder: (context, _) => Icon(
                                    Icons.star,
                                    color: Color(COLOR_PRIMARY),
                                  ),
                                  onRatingUpdate: (double rate) {},
                                ),
                              ],
                            )
                          ],
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(ratingproduct[index].comment.toString()),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
  }
}
