import 'package:easy_localization/easy_localization.dart';
import 'package:emartconsumer/cab_service/dashboard_cab_service.dart';
import 'package:emartconsumer/ecommarce_service/ecommarce_dashboard.dart';
import 'package:emartconsumer/model/SectionModel.dart';
import 'package:emartconsumer/rental_service/rental_service_dash_board.dart';
import 'package:emartconsumer/ui/QrCodeScanner/QrCodeScanner.dart';
import 'package:emartconsumer/ui/container/ContainerScreen.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../model/User.dart';
import '../../services/FirebaseHelper.dart';
import '../../services/helper.dart';
import '../../services/localDatabase.dart';
import '../auth/AuthScreen.dart';

class StoreSelection extends StatefulWidget {
  const StoreSelection({Key? key}) : super(key: key);

  @override
  StoreSelectionState createState() => StoreSelectionState();
}

class StoreSelectionState extends State<StoreSelection> {
  late CartDatabase cartDatabase;
  int cartCount = 0;
  final fireStoreUtils = FireStoreUtils();
  late Future<List<SectionModel>> categoriesSection;
  List<SectionModel> preSectionList = [];

  @override
  void initState() {
    super.initState();
    fireStoreUtils.getplaceholderimage().then((value) {
      if (value != null && value.isNotEmpty) {
        placeholderImage = value;
      }
    });

    getLanguages();
    setCurrency();
  }

  setCurrency() async {
    await FireStoreUtils().getCurrency().then((value) {
      print("---->" + value.toString());
      for (var element in value) {
        if (element.isactive = true) {
          symbol = element.symbol;
          isRight = element.symbolatright;
          currName = element.code;
          currencyData = element;
        }
      }
    });
    await FireStoreUtils().getRazorPayDemo();
    await FireStoreUtils.getPaypalSettingData();
    await FireStoreUtils.getStripeSettingData();
    await FireStoreUtils.getPayStackSettingData();
    await FireStoreUtils.getFlutterWaveSettingData();
    await FireStoreUtils.getPaytmSettingData();
    await FireStoreUtils.getPayFastSettingData();
    await FireStoreUtils.getWalletSettingData();
    await FireStoreUtils.getMercadoPagoSettingData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    cartDatabase = Provider.of<CartDatabase>(context);
    categoriesSection = fireStoreUtils.getSections();
    if (mounted) {
      fireStoreUtils.getBannerUrl().whenComplete(() => setState(() {}));
    }
  }

  DateTime pre_backpress = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final timegap = DateTime.now().difference(pre_backpress);
        final cantExit = timegap >= const Duration(seconds: 2);
        pre_backpress = DateTime.now();
        if (cantExit) {
          //show snackbar
          SnackBar snack = SnackBar(
            content: Text(
              "back-button".tr(),
              style: const TextStyle(color: Colors.white),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.black,
          );
          ScaffoldMessenger.of(context).showSnackBar(snack);
          return false; // false will do nothing when back press
        } else {
          return true; // true will exit the app
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            "eMart".tr(),
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
          ),
          actions: [
            // if (!(_currentWidget is CartScreen) ||
            //     !(_currentWidget is ProfileScreen))
            IconButton(
                padding: const EdgeInsets.only(right: 20),
                visualDensity: const VisualDensity(horizontal: -4),
                tooltip: 'QrCode'.tr(),
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: const [
                    Image(
                      image: AssetImage("assets/images/qrscan.png"),
                      width: 20,
                      color: Colors.black,
                    ),
                  ],
                ),
                onPressed: () {
                  push(
                    context,
                    QrCodeScanner(
                      presectionList: preSectionList,
                    ),
                  );
                }),
            // IconButton(
            //     padding: const EdgeInsets.only(right: 20),
            //     visualDensity: const VisualDensity(horizontal: -4),
            //     tooltip: 'Cart'.tr(),
            //     icon: Stack(
            //       clipBehavior: Clip.none,
            //       children: [
            //         const Image(
            //           image: AssetImage("assets/images/cart.png"),
            //           width: 20,
            //           color: Colors.black,
            //         ),
            //         StreamBuilder<List<CartProduct>>(
            //           stream: cartDatabase.watchProducts,
            //           builder: (context, snapshot) {
            //             cartCount = 0;
            //             if (snapshot.hasData) {
            //               for (var element in snapshot.data!) {
            //                 cartCount += element.quantity;
            //               }
            //             }
            //             return Visibility(
            //               visible: cartCount >= 1,
            //               child: Positioned(
            //                 right: -6,
            //                 top: -8,
            //                 child: Container(
            //                   padding: const EdgeInsets.all(4),
            //                   decoration: BoxDecoration(
            //                     shape: BoxShape.circle,
            //                     color: Color(COLOR_PRIMARY),
            //                   ),
            //                   constraints: const BoxConstraints(
            //                     minWidth: 12,
            //                     minHeight: 12,
            //                   ),
            //                   child: Center(
            //                     child: Text(
            //                       cartCount <= 99 ? '$cartCount' : '+99',
            //                       style: const TextStyle(
            //                         color: Colors.white,
            //                         // fontSize: 10,
            //                       ),
            //                       textAlign: TextAlign.center,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //             );
            //           },
            //         )
            //       ],
            //     ),
            //     onPressed: () {
            //       push(
            //         context,
            //         const CartScreen(
            //           fromContainer: false,
            //           fromStoreSelection: true,
            //         ),
            //       );
            //     }),
          ],
        ),
        body: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {},
              child: Banner_Url.isEmpty
                  ? Container()
                  : Container(
                      margin: const EdgeInsets.all(10),
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width / 2.5,
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
                          image: DecorationImage(
                              image: NetworkImage(Banner_Url),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.5),
                                  BlendMode.darken))),
                    ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 10, right: 10, top: 15),
              child: FutureBuilder<List<SectionModel>>(
                  future: categoriesSection,
                  initialData: const [],
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator.adaptive(
                          valueColor:
                              AlwaysStoppedAnimation(Color(COLOR_PRIMARY)),
                        ),
                      );
                    }

                    if (snapshot.hasData ||
                        (snapshot.data?.isNotEmpty ?? false)) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          if (snapshot.data != null) {
                            preSectionList.clear();
                            preSectionList.addAll(snapshot.data!);
                          }
                          return snapshot.data != null
                              ? buildCuisineCell(snapshot.data![index])
                              : showEmptyState('No Categories'.tr(), context);
                        },
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 0,
                                crossAxisSpacing: 8,
                                mainAxisExtent: 200),
                      );
                    }
                    return const CircularProgressIndicator();
                  }),
            )
          ],
        )),
      ),
    );
  }

  Widget buildCuisineCell(SectionModel sectionModel) {
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GestureDetector(
          onTap: () async {
            // if (sectionModel.serviceTypeFlag == "cab-service") {
            //   auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
            //   if (firebaseUser != null) {
            //     User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
            //
            //     if (user!.role == USER_ROLE_CUSTOMER) {
            //       user.active = true;
            //       user.role = USER_ROLE_CUSTOMER;
            //       SELECTED_CATEGORY = sectionModel.id.toString();
            //       SELECTED_SECTION_NAME = sectionModel.name.toString();
            //       serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
            //       isDineEnable = sectionModel.dineInActive!;
            //       COLOR_PRIMARY = int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
            //       user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken() ?? '';
            //       await FireStoreUtils.updateCurrentUser(user);
            //       push(context, DashBoardCabService(user: user));
            //     } else {
            //       pushReplacement(context, const AuthScreen());
            //     }
            //   } else {
            //     if (isSkipLogin) {
            //       SELECTED_CATEGORY = sectionModel.id.toString();
            //       SELECTED_SECTION_NAME = sectionModel.name.toString();
            //       isDineEnable = sectionModel.dineInActive!;
            //       serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
            //       COLOR_PRIMARY = int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
            //       push(context, DashBoardCabService(user: null));
            //     } else {
            //       pushReplacement(context, const AuthScreen());
            //     }
            //   }
            // }
            // else if (sectionModel.serviceTypeFlag == "parcel_delivery") {
            //   auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
            //   if (firebaseUser != null) {
            //     User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
            //
            //     if (user != null && user.role == USER_ROLE_CUSTOMER) {
            //       user.active = true;
            //       user.role = USER_ROLE_CUSTOMER;
            //       SELECTED_CATEGORY = sectionModel.id.toString();
            //       SELECTED_SECTION_NAME = sectionModel.name.toString();
            //       isDineEnable = sectionModel.dineInActive!;
            //       serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
            //       COLOR_PRIMARY = int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
            //       user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken() ?? '';
            //       await FireStoreUtils.updateCurrentUser(user);
            //       push(context, ParcelDahBoard(user: user));
            //     } else {
            //       pushReplacement(context, const AuthScreen());
            //     }
            //   } else {
            //     if (isSkipLogin) {
            //       SELECTED_CATEGORY = sectionModel.id.toString();
            //       SELECTED_SECTION_NAME = sectionModel.name.toString();
            //       serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
            //       isDineEnable = sectionModel.dineInActive!;
            //       COLOR_PRIMARY = int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
            //       push(context, ParcelDahBoard(user: null));
            //     } else {
            //       pushReplacement(context, const AuthScreen());
            //     }
            //   }
            // }
            // else if (sectionModel.serviceTypeFlag == "rental-service") {
            //   auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
            //   if (firebaseUser != null) {
            //     User? user = await FireStoreUtils.getCurrentUser(firebaseUser.uid);
            //
            //     if (user!.role == USER_ROLE_CUSTOMER) {
            //       user.active = true;
            //       user.role = USER_ROLE_CUSTOMER;
            //       SELECTED_CATEGORY = sectionModel.id.toString();
            //       SELECTED_SECTION_NAME = sectionModel.name.toString();
            //       serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
            //       isDineEnable = sectionModel.dineInActive!;
            //       COLOR_PRIMARY = int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
            //       user.fcmToken = await FireStoreUtils.firebaseMessaging.getToken() ?? '';
            //       await FireStoreUtils.updateCurrentUser(user);
            //       push(context, RentalServiceDashBoard(user: user));
            //     } else {
            //       pushReplacement(context, const AuthScreen());
            //     }
            //   } else {
            //     if (isSkipLogin) {
            //       SELECTED_CATEGORY = sectionModel.id.toString();
            //       SELECTED_SECTION_NAME = sectionModel.name.toString();
            //       serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
            //       isDineEnable = sectionModel.dineInActive!;
            //       COLOR_PRIMARY = int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
            //       push(context, RentalServiceDashBoard(user: null));
            //     } else {
            //       pushReplacement(context, const AuthScreen());
            //     }
            //   }
            // } else {
            //
            // }

            auth.User? firebaseUser = auth.FirebaseAuth.instance.currentUser;
            if (firebaseUser != null) {
              User? user =
                  await FireStoreUtils.getCurrentUser(firebaseUser.uid);

              if (user!.role == USER_ROLE_CUSTOMER) {
                user.active = true;
                user.role = USER_ROLE_CUSTOMER;
                referralAmount = sectionModel.referralAmount.toString();
                SELECTED_CATEGORY = sectionModel.id.toString();
                SELECTED_SECTION_NAME = sectionModel.name.toString();
                serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
                isDineEnable = sectionModel.dineInActive!;
                ecommarceDileveryCharges = sectionModel.delivery_charge!;
                COLOR_PRIMARY =
                    int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
                user.fcmToken =
                    await FireStoreUtils.firebaseMessaging.getToken() ?? '';
                await FireStoreUtils.updateCurrentUser(user);
                if (sectionModel.serviceTypeFlag == "ecommerce-service") {
                  await Provider.of<CartDatabase>(context, listen: false)
                      .allCartProducts
                      .then((value) {
                    if (value.isNotEmpty) {
                      showAlertDialog(context, user, sectionModel);
                    } else {
                      push(context, EcommeceDashBoardScreen(user: user));
                    }
                  });
                } else if (sectionModel.serviceTypeFlag == "cab-service") {
                  push(context, DashBoardCabService(user: user));
                } else if (sectionModel.serviceTypeFlag == "rental-service") {
                  push(context, RentalServiceDashBoard(user: user));
                } /* else if (sectionModel.serviceTypeFlag == "parcel_delivery") {
                  push(context, ParcelDahBoard(user: user));
                } */
                else {
                  await Provider.of<CartDatabase>(context, listen: false)
                      .allCartProducts
                      .then((value) {
                    if (value.isNotEmpty) {
                      showAlertDialog(context, user, sectionModel);
                    } else {
                      push(context, ContainerScreen(user: user));
                    }
                  });
                  // showAlertDialog(context,user,sectionModel);
                }
              } else {
                pushReplacement(context, const AuthScreen());
              }
            } else {
              if (isSkipLogin) {
                referralAmount = sectionModel.referralAmount.toString();
                SELECTED_CATEGORY = sectionModel.id.toString();
                SELECTED_SECTION_NAME = sectionModel.name.toString();
                serviceTypeFlag = sectionModel.serviceTypeFlag.toString();
                isDineEnable = sectionModel.dineInActive!;
                ecommarceDileveryCharges = sectionModel.delivery_charge!;
                COLOR_PRIMARY =
                    int.parse(sectionModel.color!.replaceFirst("#", "0xff"));
                if (sectionModel.serviceTypeFlag == "ecommerce-service") {
                  push(context, EcommeceDashBoardScreen(user: null));
                } else if (sectionModel.serviceTypeFlag == "cab-service") {
                  push(context, DashBoardCabService(user: null));
                } else if (sectionModel.serviceTypeFlag == "rental-service") {
                  push(context, RentalServiceDashBoard(user: null));
                } /* else if (sectionModel.serviceTypeFlag == "parcel_delivery") {
                  push(context, ParcelDahBoard(user: null));
                }*/
                else {
                  push(context, ContainerScreen(user: null));
                }
              } else {
                pushReplacement(context, const AuthScreen());
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.all(5),
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
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.network(
                    (sectionModel.sectionImage == null ||
                            sectionModel.sectionImage!.isEmpty)
                        ? placeholderImage
                        : sectionModel.sectionImage.toString(),
                    height: 75,
                    width: 75,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Text(
                    sectionModel.name.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18),
                  ).tr(),
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> getLanguages() async {
    await FireStoreUtils.firestore
        .collection(Setting)
        .doc("languages")
        .get()
        .then((value) {
      List list = value.data()!["list"];
      isLanguageShown = (list.isNotEmpty);
    });
  }

  showAlertDialog(BuildContext context, User? user, SectionModel sectionModel) {
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () async {
        if (sectionModel.serviceTypeFlag == "ecommerce-service") {
          Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
          push(context, EcommeceDashBoardScreen(user: user));
        } else {
          Provider.of<CartDatabase>(context, listen: false).deleteAllProducts();
          push(context, ContainerScreen(user: user));
        }
      },
    );

    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.pop(context);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Alert!"),
      content: const Text(
          "If you select this Section/Service, your previously added items will be removed from the cart."),
      actions: [
        cancelButton,
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
