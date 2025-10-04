class ProfileModel {
  final int? profileId;
  final String? profileName;
  final String? profileLastname;
  final String? profilePhone;
  final String? profileNumberDocument;
  final int? userFk;
  final int? imageFk;
  final int? typeDocumentFk;
  final int? addressFk;
  final String? userMail;
  final String? typeDocumentName;
  final String? imageUrl;
  final String? imageName;

  ProfileModel({
    this.profileId,
    this.profileName,
    this.profileLastname,
    this.profilePhone,
    this.profileNumberDocument,
    this.userFk,
    this.imageFk,
    this.typeDocumentFk,
    this.addressFk,
    this.userMail,
    this.typeDocumentName,
    this.imageUrl,
    this.imageName,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      profileId: json['Profile_id'],
      profileName: json['Profile_name'],
      profileLastname: json['Profile_lastname'],
      profilePhone: json['Profile_phone'],
      profileNumberDocument: json['Profile_number_document'],
      userFk: json['User_fk'],
      imageFk: json['image_fk'],
      typeDocumentFk: json['Type_document_fk'],
      addressFk: json['Address_fk'],
      userMail: json['User_mail'],
      typeDocumentName: json['Type_document_name'],
      imageUrl: json['Image_url'],
      imageName: json['Image_name'],
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'Profile_name': profileName?.trim(),
      'Profile_lastname': profileLastname?.trim(),
    };
    
    // Solo incluir campos si no son null o vacíos
    if (profilePhone != null && profilePhone!.isNotEmpty) {
      map['Profile_phone'] = profilePhone!.trim();
    }
    
    if (profileNumberDocument != null && profileNumberDocument!.isNotEmpty) {
      map['Profile_number_document'] = profileNumberDocument!.trim();
    }
    
    if (userFk != null) {
      map['User_fk'] = userFk;
    }
    
    if (typeDocumentFk != null) {
      map['Type_document_fk'] = typeDocumentFk;
    }
    
    // Solo incluir si tienen valores válidos
    if (imageFk != null && imageFk! > 0) {
      map['image_fk'] = imageFk;
    }
    
    if (addressFk != null && addressFk! > 0) {
      map['Address_fk'] = addressFk;
    }
    
    return map;
  }
}

class DocumentTypeModel {
  final int typeDocumentId;
  final String typeDocumentName;

  DocumentTypeModel({
    required this.typeDocumentId,
    required this.typeDocumentName,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) {
    return DocumentTypeModel(
      typeDocumentId: json['Type_document_id'],
      typeDocumentName: json['Type_document_name'],
    );
  }
}

class UserCodeModel {
  final String codigeNumber;
  final String productName;
  final String? userMail;
  final int? userId;

  UserCodeModel({
    required this.codigeNumber,
    required this.productName,
    this.userMail,
    this.userId,
  });

  factory UserCodeModel.fromJson(Map<String, dynamic> json) {
    return UserCodeModel(
      codigeNumber: json['codige_number'],
      productName: json['product_name'],
      userMail: json['user_mail'],
      userId: json['user_id'],
    );
  }
}

class ImageUploadModel {
  final int id;
  final String name;
  final String url;

  ImageUploadModel({
    required this.id,
    required this.name,
    required this.url,
  });

  factory ImageUploadModel.fromJson(Map<String, dynamic> json) {
    return ImageUploadModel(
      id: json['id'],
      name: json['name'],
      url: json['url'],
    );
  }
}