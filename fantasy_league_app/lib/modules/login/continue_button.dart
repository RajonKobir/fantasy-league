import 'package:flutter/material.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';

class ContinueButton extends StatelessWidget {
  final void Function()? callBack;
  final String? name;

  const ContinueButton({super.key, this.callBack, this.name});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Container(
        decoration: BoxDecoration(
          color: AllCoustomTheme.getThemeData().primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              callBack!();
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 12),
              child: Center(
                child: Text(
                  (name! != '') ? name! : 'Continue',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: ConstanceData.SIZE_TITLE18,
                    fontWeight: FontWeight.bold,
                    color: AllCoustomTheme.getThemeData().colorScheme.surface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}




