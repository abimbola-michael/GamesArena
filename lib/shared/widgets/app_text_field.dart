import 'package:country_code_picker_plus/country_code_picker_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:gamesarena/shared/extensions/extensions.dart';
import 'package:gamesarena/shared/utils/utils.dart';

import '../../theme/colors.dart';
import '../utils/country_code_utils.dart';
import 'svg_button.dart';

class AppTextField extends StatefulWidget {
  final String hintText;
  final String titleText;
  final Widget? prefix;
  final Widget? suffix;
  final EdgeInsets? margin;
  final EdgeInsets? padding;
  final TextStyle? style;
  final String? Function(String?)? validator;
  final double? height;
  final double? width;
  final TextEditingController? controller;
  final void Function(String code)? onChangedCountryCode;
  final void Function(String dialCode)? onChangedDialCode;

  final String? initialCountryCode;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmit;
  final int? maxLines;
  final TextInputType? inputType;
  final bool hideErrorText;
  final bool capitalize;
  final bool centered;
  final bool? obscureText;
  final bool? focused;
  final bool? hasError;
  final bool dontShowKeyboard;
  final bool autoFocus;
  final FocusNode? focusNode;
  final BorderRadius? borderRadius;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final bool isCard;
  final Color? color;
  final TextInputAction? inputAction;
  final bool isSearch;
  final bool removeBottomSpacing;

  const AppTextField(
      {super.key,
      this.color,
      this.hintText = "",
      this.titleText = "",
      this.validator,
      this.height,
      this.width,
      this.controller,
      this.onChangedCountryCode,
      this.onChangedDialCode,
      this.onChanged,
      this.onSubmit,
      this.maxLines,
      this.prefix,
      this.suffix,
      this.margin,
      this.padding,
      this.inputType,
      this.style,
      this.inputAction,
      this.hideErrorText = false,
      this.removeBottomSpacing = false,
      this.capitalize = false,
      this.centered = false,
      this.obscureText,
      this.dontShowKeyboard = false,
      this.autoFocus = false,
      this.isSearch = false,
      this.focusNode,
      this.borderRadius,
      this.alignment,
      this.onTap,
      this.hasError,
      this.focused,
      this.isCard = false,
      this.initialCountryCode});

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool obscureText = true;
  bool _isFieldValid = true;
  bool _isFocused = false;
  FocusNode _focusNode = FocusNode();
  String hintText = "";
  String? errorText = "";
  String text = "";
  String countryDialCode = "";
  String countryCode = "US";

  @override
  void initState() {
    super.initState();
    // hintText = widget.titleText.isNotEmpty ? widget.titleText : widget.hintText;
    // obscureText = hintText.contains("Password");
    // if (widget.focusNode != null) {
    //   _focusNode = widget.focusNode!;
    // }
    //_focusNode.addListener(_onFocusChange);

    // print("isPhoneNumber");
    // getDialCode().then((value) {
    //   countryDialCode = dialCode;
    //   print("countryCode = $countryCode, dialCode = $dialCode");
    //   setState(() {});
    // });
    if (widget.onChangedCountryCode != null) {
      widget.onChangedCountryCode!(widget.initialCountryCode ?? countryCode);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void tooglePasswordVisibility() {
    setState(() {
      obscureText = !obscureText;
    });
  }

  TextInputType getTextInputType() {
    if (hintText.contains("mail")) {
      return TextInputType.emailAddress;
    } else if (hintText.contains("Phone")) {
      return TextInputType.phone;
    } else if (hintText.contains("Number") || hintText.contains("Phone")) {
      return TextInputType.number;
    } else {
      return TextInputType.text;
    }
  }

  String? validate(String? value) {
    if (widget.validator != null) {
      final validatorValue = widget.validator!(value);
      if (validatorValue != null) {
        return validatorValue;
      }
    }
    if (value == null || value.isEmpty) {
      return "$hintText is required";
    }
    if (hintText.toLowerCase().contains("email")) {
      if (!isValidEmail(value)) {
        return "Invalid Email";
      }
    } else if (hintText.toLowerCase().contains("phone") ||
        hintText.toLowerCase().contains("Mobile") ||
        hintText.toLowerCase().contains("Number")) {
      if (!isValidPhoneNumber(value)) {
        return "Invalid Phone Number";
      }
      if (value.startsWith("+")) {
        return "Select Country dial code and just input the rest of your number";
      }
    } else if (hintText.toLowerCase().contains("password")) {
      if (value.length < 6 || value.length > 30) {
        return "Password must be between 6 and 30 characters";
      }
      // else if (!isValidPassword(value)) {
      //   return "Invalid Password, Password must contain at least one uppercase, lowercase, number and special character";
      // }
    } else if (hintText.toLowerCase().contains("username")) {
      if (value.length < 3 || value.length > 20) {
        return "Username must be between 3 and 20 characters";
      }
      if (!isValidUserName(value)) {
        return "Username can only contain letters, numbers and underscores";
      }
    } else if (hintText.toLowerCase().contains("name")) {
      if (value.length < 3) {
        return "Name must be at least 3 characters";
      }
      if (!isValidName(value)) {
        return "Invalid Name";
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hintText.toLowerCase().contains("phone") &&
        countryDialCode.isEmpty) {
      countryDialCode = "+1";
    }
    hintText = widget.titleText.isNotEmpty ? widget.titleText : widget.hintText;
    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.titleText.trim().isNotEmpty)
          Text(widget.titleText,
              style: context.bodyLarge?.copyWith(color: tint)),
        Container(
          width: widget.width,
          height: widget.height,
          margin: widget.margin ?? const EdgeInsets.symmetric(vertical: 4.0),
          //decoration: BoxDecoration(
          //color: widget.color ?? lightestTint,
          // (_isFocused || !_isFieldValid
          //     ? Colors.transparent
          //     : widget.isCard
          //         ? white
          //         : textFieldUnfocusColor),
          //  borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          // border: widget.dontShowKeyboard
          //     ? Border.all(
          //         color: widget.focused == true
          //             ? primaryColor
          //             : widget.hasError == true
          //                 ? red
          //                 : transparent)
          //     : null,
          // boxShadow: widget.isCard
          //     ? [
          //         BoxShadow(
          //           color: faintBlack,
          //           offset: const Offset(15, 15),
          //           blurRadius: 30,
          //           spreadRadius: 0,
          //         )
          //       ]
          //     : null,
          //   ),
          alignment:
              widget.alignment ?? (widget.centered ? Alignment.center : null),
          child: GestureDetector(
            onTap: () {
              // if (widget.dontShowKeyboard) {
              //   _focusNode.requestFocus();
              // }
              widget.onTap?.call();
            },
            //?? _focusNode
            child: TextFormField(
              autofocus: widget.autoFocus,
              readOnly: widget.dontShowKeyboard,
              focusNode: widget.focusNode,
              onFieldSubmitted: widget.onSubmit,
              textInputAction: widget.inputAction,
              inputFormatters: hintText.contains("Username")
                  ? [
                      LowercaseFormatter(),
                    ]
                  : [],
              textCapitalization: hintText.contains("Name") || widget.capitalize
                  ? TextCapitalization.words
                  : TextCapitalization.none,
              validator: (value) {
                final result = validate(value);
                errorText = result;

                if (result != null) {
                  setState(() {
                    _isFieldValid = false;
                  });
                  return result;
                }
                return result;
              },
              controller: widget.controller,
              onChanged: (value) {
                // if (!_isFieldValid) {
                //   setState(() {
                //     _isFieldValid = true;
                //   });
                // }
                text = value;
                if (widget.onChanged != null) {
                  widget.onChanged!("$countryDialCode$text");
                }
              },
              maxLines: widget.maxLines ?? 1,
              keyboardType: widget.inputType ?? getTextInputType(),
              // inputFormatters: (widget.inputType ?? getTextInputType()) ==
              //         TextInputType.number
              //     ? <TextInputFormatter>[
              //         FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
              //       ]
              //     : null,
              obscureText: widget.obscureText ??
                  (hintText.contains("Password") && obscureText),
              style: widget.style ?? context.bodyMedium?.copyWith(),
              cursorColor: primaryColor,

              //cursorHeight: 20,
              textAlign: widget.centered ? TextAlign.center : TextAlign.left,
              textAlignVertical:
                  widget.centered ? TextAlignVertical.center : null,
              decoration: InputDecoration(
                  fillColor: widget.color ?? lightestTint,
                  filled: true,
                  // prefixIconConstraints: const BoxConstraints(
                  //   minWidth: 60, // Adjust width
                  //   minHeight: 30, // Adjust height
                  // ),
                  prefixIcon: hintText.toLowerCase().contains("phone")
                      ? SizedBox(
                          width: 60,
                          height: 20,
                          child: CountryCodePicker(
                            textStyle:
                                widget.style ?? context.bodyMedium?.copyWith(),
                            padding:
                                const EdgeInsets.only(left: 20, bottom: 1.5),
                            mode: CountryCodePickerMode.bottomSheet,
                            initialSelection:
                                widget.initialCountryCode ?? countryCode,
                            showFlag: false,
                            showDropDownButton: false,
                            dialogBackgroundColor: offtint,
                            onChanged: (country) {
                              countryDialCode = country.dialCode;
                              if (widget.onChangedCountryCode != null) {
                                widget.onChangedCountryCode!(country.code);
                              }
                              if (widget.onChangedDialCode != null) {
                                widget.onChangedDialCode!(country.dialCode);
                              }
                              if (widget.onChanged != null) {
                                widget.onChanged!("$countryDialCode$text");
                              }
                            },
                          ),
                        )
                      : widget.prefix,
                  suffixIcon: hintText.toLowerCase().contains("password")
                      ? SizedBox(
                          width: 17,
                          height: 17,
                          child: IconButton(
                            icon: Icon(
                                obscureText ? IonIcons.eye : IonIcons.eye_off),
                            onPressed: tooglePasswordVisibility,
                            iconSize: 17,
                          ),
                        )
                      : widget.suffix,
                  contentPadding: widget.padding ??
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  hintText: widget.hintText,
                  hintStyle: widget.style != null
                      ? widget.style?.copyWith(color: lighterTint)
                      : context.bodyMedium?.copyWith(color: lighterTint),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(8),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red,
                    ),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: primaryColor,
                    ),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(8),
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: widget.isSearch ? lightestBlack : transparent,
                    ),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: widget.isSearch ? lightestBlack : transparent,
                    ),
                    borderRadius:
                        widget.borderRadius ?? BorderRadius.circular(8),
                  )
                  // border: widget.isSearch
                  //     ?
                  //     : InputBorder.none,
                  ),
            ),
          ),
        ),
        // if (!widget.removeBottomSpacing)
        //   Container(
        //       height: 15,
        //       width: double.infinity,
        //       decoration: BoxDecoration(
        //           boxShadow: !_isFocused
        //               ? null
        //               : [
        //                   BoxShadow(
        //                     color: faintTint,
        //                     blurRadius: 30,
        //                     spreadRadius: 0,
        //                     offset: const Offset(15, 15),
        //                   )
        //                 ]))
      ],
    );
  }
}

class LowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
        text: newValue.text.toLowerCase(), selection: newValue.selection);
  }
}
