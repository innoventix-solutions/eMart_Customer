class SectionModel {
  String? referralAmount;
  String? serviceType;
  String? taxAmount;
  String? color;
  String? taxType;
  String? name;
  String? taxLable;
  String? sectionImage;
  String? id;
  bool? taxActive;
  bool? isActive;
  bool? dineInActive;
  String? serviceTypeFlag;
  String? commissionAmount;
  String? commissionType;
  String? delivery_charge;
  bool? isEnableCommission;

  SectionModel(
      {
        this.referralAmount,
        this.serviceType,
      this.taxAmount,
      this.color,
      this.taxType,
      this.name,
      this.taxLable,
      this.sectionImage,
      this.id,
      this.taxActive,
      this.isActive,
      this.commissionAmount,
      this.commissionType,
      this.isEnableCommission,
      this.dineInActive,
      this.delivery_charge,
      this.serviceTypeFlag});

  SectionModel.fromJson(Map<String, dynamic> json) {
    referralAmount = json['referralAmount'] ?? '';
    serviceType = json['serviceType'] ?? '';
    taxAmount = json['tax_amount'];
    color = json['color'];
    taxType = json['tax_type'];
    name = json['name'];
    taxLable = json['tax_lable'];
    sectionImage = json['sectionImage'];
    id = json['id'];
    taxActive = json['tax_active'];
    commissionAmount = json['commissionAmount'].toString();
    commissionType = json['commissionType'] ?? '';
    isEnableCommission = json['isEnableCommission'] ?? false;
    isActive = json['isActive'];
    dineInActive = json['dine_in_active'] ?? false;
    serviceTypeFlag = json['serviceTypeFlag'] ?? '';
    delivery_charge = json['delivery_charge'] ?? '';
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['referralAmount'] = referralAmount;
    data['serviceType'] = serviceType;
    data['tax_amount'] = taxAmount;
    data['color'] = color;
    data['tax_type'] = taxType;
    data['name'] = name;
    data['tax_lable'] = taxLable;
    data['sectionImage'] = sectionImage;
    data['commissionAmount'] = commissionAmount;
    data['commissionType'] = commissionType;
    data['isEnableCommission'] = isEnableCommission;
    data['id'] = id;
    data['tax_active'] = taxActive;
    data['isActive'] = isActive;
    data['dine_in_active'] = dineInActive;
    data['serviceTypeFlag'] = serviceTypeFlag;
    data['delivery_charge'] = delivery_charge;
    return data;
  }
}
