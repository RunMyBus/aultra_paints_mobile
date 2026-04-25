import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../services/config.dart';
import '../../../services/error_handling.dart';
import '../../../utility/Utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../widgets/primitives/app_app_bar.dart';
import '../../../widgets/primitives/app_button.dart';
import '../../../widgets/primitives/app_card.dart';
import '../../../widgets/primitives/app_text_field.dart';

class CreateOrders extends StatefulWidget {
  const CreateOrders({Key? key}) : super(key: key);

  @override
  State<CreateOrders> createState() => _CreateOrdersState();
}

class _CreateOrdersState extends State<CreateOrders> {
  int? selected;

  var accesstoken;
  var USER_ID;
  var Company_ID;

  Map mapResponse = {};

  var ewbNumber = '';
  var lrNumber = '';
  var invoiceNumber = '';
  var invoiceValue = '';

  var argumentData;

  DateTime? invoiceDate = DateTime.now();

  Map fetchedDetails = {};

  late TextEditingController _brandNameController;
  late TextEditingController _productNameController;
  late TextEditingController _volumeController;
  late TextEditingController _quantityController;

  DateTime _selectedDate = DateTime.now();
  DateTime _selectedValidUptoDate = DateTime.now();

  var tripNumber;

  @override
  void initState() {
    fetchLocalStorageDate();
    super.initState();
    _brandNameController = TextEditingController();
    _productNameController = TextEditingController();
    _volumeController = TextEditingController();
    _quantityController = TextEditingController();
  }

  @override
  void dispose() {
    _brandNameController.dispose();
    _productNameController.dispose();
    _volumeController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  fetchLocalStorageDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    accesstoken = prefs.getString('accessToken');
  }

  void _showSnackBar(String message, BuildContext context, ColorCheck) {
    final snackBar = SnackBar(
        content: Text(message),
        backgroundColor: ColorCheck ? Colors.green : Colors.red,
        duration: Utils.returnStatusToastDuration(ColorCheck));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void validateCreateOrderDetails() {
    if (_brandNameController.text.isEmpty) {
      _showSnackBar("Please enter Brand Name", context, false);
    } else if (_productNameController.text.isEmpty) {
      _showSnackBar("Please enter Product Name", context, false);
    } else if (_volumeController.text.isEmpty) {
      _showSnackBar("Please enter Volume", context, false);
    } else if (_quantityController.text.isEmpty) {
      _showSnackBar("Please enter Quantity", context, false);
    } else {
      createOrder();
    }
  }

  Future createOrder() async {
    Utils.returnScreenLoader(context);
    http.Response response;
    Map map = {
      "brand": _brandNameController.text,
      "productName": _productNameController.text,
      "volume": _volumeController.text,
      "quantity": _quantityController.text,
    };
    var body = json.encode(map);

    response = await http.post(Uri.parse(BASE_URL + CREATE_ORDER),
        headers: {
          "Content-Type": "application/json",
          "Authorization": accesstoken
        },
        body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      var apiResp = json.decode(response.body);
      Navigator.pop(context);
      _showSnackBar(apiResp['message'], context, true);
      Navigator.pop(context, true);
    } else {
      Navigator.pop(context);
      error_handling.errorValidation(
          context, response.statusCode, response.body, false);
    }
  }

  onBackPressed() {
    Utils.clearToasts(context);
    Navigator.pop(context, true);
  }

  Future<bool> _onWillPop() async {
    onBackPressed();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppAppBar(
          title: 'New Order',
          leading: AppAppBarAction(
            icon: Icons.arrow_back,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: AppCard(
            emphasis: AppCardEmphasis.form,
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Brand
                AppTextField(
                  label: 'Brand',
                  hint: 'Enter Brand',
                  controller: _brandNameController,
                  keyboardType:
                      defaultTargetPlatform == TargetPlatform.iOS
                          ? TextInputType.numberWithOptions(
                              decimal: true, signed: true)
                          : TextInputType.text,
                  onChanged: (value) {
                    setState(() {
                      if (_brandNameController.text != value) {
                        final cursorPosition =
                            _brandNameController.selection;
                        _brandNameController.text = value;
                        _brandNameController.selection = cursorPosition;
                      }
                    });
                  },
                ),
                SizedBox(height: AppSpacing.md),
                // Product Name
                AppTextField(
                  label: 'Product Name',
                  hint: 'Enter Product Name',
                  controller: _productNameController,
                  keyboardType:
                      defaultTargetPlatform == TargetPlatform.iOS
                          ? TextInputType.numberWithOptions(
                              decimal: true, signed: true)
                          : TextInputType.text,
                  onChanged: (value) {
                    setState(() {
                      if (_productNameController.text != value) {
                        final cursorPosition =
                            _productNameController.selection;
                        _productNameController.text = value;
                        _productNameController.selection = cursorPosition;
                      }
                    });
                  },
                ),
                SizedBox(height: AppSpacing.sm),
                // Add Product link preserved
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      Navigator.pushNamed(context, '/createProduct');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add,
                            color: AppColors.primary, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Add Product',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall!
                              .copyWith(
                                color: AppColors.primary,
                                decoration: TextDecoration.underline,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
                // Volume
                AppTextField(
                  label: 'Volume',
                  hint: 'Enter Volume',
                  controller: _volumeController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      if (_volumeController.text != value) {
                        final cursorPosition = _volumeController.selection;
                        _volumeController.text = value;
                        _volumeController.selection = cursorPosition;
                      }
                    });
                  },
                ),
                SizedBox(height: AppSpacing.md),
                // Quantity
                AppTextField(
                  label: 'Quantity',
                  hint: 'Enter Quantity',
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      if (_quantityController.text != value) {
                        final cursorPosition =
                            _quantityController.selection;
                        _quantityController.text = value;
                        _quantityController.selection = cursorPosition;
                      }
                    });
                  },
                ),
                SizedBox(height: AppSpacing.lg),
                AppButton.filled(
                  label: 'Create',
                  onPressed: () {
                    Utils.clearToasts(context);
                    validateCreateOrderDetails();
                  },
                  fullWidth: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
