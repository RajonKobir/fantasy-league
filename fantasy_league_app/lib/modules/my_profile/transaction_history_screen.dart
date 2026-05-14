// import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:fantasyleague/api/api_provider.dart';
import 'package:fantasyleague/constance/constance.dart';
import 'package:fantasyleague/constance/themes.dart';
import 'package:fantasyleague/models/transaction_response.dart';
// import 'package:fantasyleague/validator/validator.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:url_launcher/url_launcher.dart';

class TransectionHistoryScreen extends StatefulWidget {
  const TransectionHistoryScreen({super.key});

  @override
  _TransectionHistoryScreenState createState() =>
      _TransectionHistoryScreenState();
}

class _TransectionHistoryScreenState extends State<TransectionHistoryScreen> {
  var transactionList = <Transaction>[];
  bool isProsses = false;
  var transactionModiFiedDataList = <TransactionModiFiedDataList>[];
  bool isPopupOpen = false;
  var toDate = DateFormat('dd/MM/yyyy')
      .parse(DateFormat('dd/MM/yyyy').format(DateTime.now()));
  var fromDate = DateFormat('dd/MM/yyyy').parse(DateFormat('dd/MM/yyyy')
      .format(DateTime.now().subtract(const Duration(days: 30))));
  var nowDate = DateFormat('dd/MM/yyyy')
      .parse(DateFormat('dd/MM/yyyy').format(DateTime.now()));
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    getData();
    super.initState();
  }

  void getData() async {
    setState(() {
      isProsses = true;
    });

    var responseData = await ApiProvider().getTransaction();

    setState(() {
      transactionList = responseData.transaction!;
    });

    for (var data in transactionList) {
      if (isMach(DateFormat('dd/MM/yyyy')
          .parse(data.time!.split(',')[0])
          .millisecondsSinceEpoch
          .toString())) {
        for (var tdate in transactionModiFiedDataList) {
          if (tdate.date ==
              DateFormat('dd/MM/yyyy')
                  .parse(data.time!.split(',')[0])
                  .millisecondsSinceEpoch
                  .toString()) {
            tdate.transaction!.add(data);
          }
        }
      } else {
        var newList = TransactionModiFiedDataList();
        newList.date = DateFormat('dd/MM/yyyy')
            .parse(data.time!.split(',')[0])
            .millisecondsSinceEpoch
            .toString();
        newList.transaction = [data];
        transactionModiFiedDataList.add(newList);
      }
    }

    transactionModiFiedDataList.sort(
        (a, b) => int.tryParse(b.date!)!.compareTo(int.tryParse(a.date!)!));

    setState(() {
      isProsses = false;
    });
  }

  bool isMach(String time) {
    bool isMach = false;
    for (var tData in transactionModiFiedDataList) {
      if (tData.date == time) {
        isMach = true;
        continue;
      }
    }
    return isMach;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isPopupOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        if (isPopupOpen) {
          setState(() {
            isPopupOpen = false;
          });
        }
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AllCoustomTheme.getThemeData().primaryColor,
              AllCoustomTheme.getThemeData().primaryColor,
              Colors.white,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: <Widget>[
            SafeArea(
              child: Scaffold(
                key: _scaffoldKey,
                backgroundColor:
                    AllCoustomTheme.getThemeData().colorScheme.surface,
                body: Stack(
                  alignment: AlignmentDirectional.bottomCenter,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Container(
                          color: AllCoustomTheme.getThemeData().primaryColor,
                          height: AppBar().preferredSize.height,
                          child: Row(
                            children: <Widget>[
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    Navigator.pop(context);
                                  },
                                  child: SizedBox(
                                    width: AppBar().preferredSize.height,
                                    height: AppBar().preferredSize.height,
                                    child: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    'History',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: ConstanceData.SIZE_TITLE20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      isPopupOpen = true;
                                    });
                                  },
                                  child: SizedBox(
                                    width: AppBar().preferredSize.height,
                                    height: AppBar().preferredSize.height,
                                    child: const Icon(
                                      Icons.receipt,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ModalProgressHUD(
                            inAsyncCall: isProsses,
                            color: Colors.transparent,
                            progressIndicator: const CircularProgressIndicator(
                              strokeWidth: 2.0,
                            ),
                            child: listData(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// Popup overlay
            if (isPopupOpen)
              Scaffold(
                backgroundColor: Colors.black.withValues(alpha: 128),
                body: SingleChildScrollView(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AllCoustomTheme.getThemeData()
                                .colorScheme
                                .surface,
                            borderRadius: BorderRadius.circular(4.0),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 128),
                                offset: const Offset(0, 1),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // ? Your existing popup content stays unchanged
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void getBanckStatementPDF() async {
    setState(() {
      isProsses = true;
    });
    final Uri url = Uri.parse(
      'https://starsportsfantasy.com/Fantasy/statement/bankstatement937205614.pdf',
    );

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $url';
    }

    setState(() {
      isProsses = false;
    });
  }

  void showInSnackBar(String value, {bool isGreen = false}) {
    var snackBar = SnackBar(
      backgroundColor: isGreen ? Colors.green : Colors.red,
      content: Text(
        value,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: ConstanceData.SIZE_TITLE14,
          color: AllCoustomTheme.getReBlackAndWhiteThemeColors(),
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Widget _buildBottomPicker(Widget picker) {
  //   return Container(
  //     height: 216.0,
  //     padding: const EdgeInsets.only(top: 6.0),
  //     color: CupertinoColors.white,
  //     child: DefaultTextStyle(
  //       style: const TextStyle(
  //         fontFamily: 'Poppins',
  //         color: CupertinoColors.black,
  //         fontSize: 22.0,
  //       ),
  //       child: GestureDetector(
  //         onTap: () {},
  //         child: SafeArea(
  //           top: false,
  //           child: picker,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget listData() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: transactionModiFiedDataList.length,
      itemBuilder: (context, index) {
        return StickyHeaderBuilder(
          builder: (BuildContext context, double stuckAmount) {
            return Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 26),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: Text(
                        DateFormat('dd MMM, yyyy').format(DateTime.fromMillisecondsSinceEpoch(int.tryParse(transactionModiFiedDataList[index].date!)!)),
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: ConstanceData.SIZE_TITLE16,
                            fontWeight: FontWeight.bold,
                            color:
                                AllCoustomTheme.getBlackAndWhiteThemeColors()),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          content: Column(
            children: <Widget>[
              const Divider(
                height: 1,
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: getSubList(
                  transactionModiFiedDataList[index],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget getSubList(TransactionModiFiedDataList data) {
    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        setState(() {
          data.transaction![index].isExpanded = !isExpanded;
        });
      },
      children: data.transaction!.map<ExpansionPanel>((Transaction listData) {
        return ExpansionPanel(
          canTapOnHeader: true,
          isExpanded: listData.isExpanded!,
          headerBuilder: (BuildContext context, bool isExpanded) {
            return SizedBox(
              height: 44,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        listData.type == 'RECEIVE'
                            ? '+ ? ${listData.amount}'
                            : '- ? ${listData.amount}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: ConstanceData.SIZE_TITLE14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    child: Text(
                      '${listData.remark}',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: ConstanceData.SIZE_TITLE14,
                        color: Colors.black.withValues(alpha: 128),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          body: Container(
            child: Column(
              children: <Widget>[
                const Divider(
                  height: 1,
                ),
                Container(
                  padding:
                      const EdgeInsets.only(right: 16, left: 16, bottom: 16, top: 16),
                  child: Column(
                    children: <Widget>[
                      listData.statusRequest != ''
                          ? Container(
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: listData.statusRequest == '1'
                                                ? Colors.green
                                                : Colors.grey
                                                    .withValues(alpha: 128),
                                            border: Border.all(
                                              color:
                                                  AllCoustomTheme.getThemeData()
                                                      .colorScheme
                                                      .surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.done,
                                            color:
                                                AllCoustomTheme.getThemeData()
                                                    .colorScheme
                                                    .surface,
                                            size: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 2,
                                            color: listData.statusProcess == '1'
                                                ? Colors.green
                                                : Colors.grey
                                                    .withValues(alpha: 128),
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: listData.statusProcess == '1'
                                                ? Colors.green
                                                : Colors.grey
                                                    .withValues(alpha: 128),
                                            border: Border.all(
                                              color:
                                                  AllCoustomTheme.getThemeData()
                                                      .colorScheme
                                                      .surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.done,
                                            color:
                                                AllCoustomTheme.getThemeData()
                                                    .colorScheme
                                                    .surface,
                                            size: 12,
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            height: 2,
                                            color: listData.statusCredit == '1'
                                                ? Colors.green
                                                : Colors.grey
                                                    .withValues(alpha: 128),
                                          ),
                                        ),
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: listData.statusCredit == '1'
                                                ? Colors.green
                                                : Colors.grey
                                                    .withValues(alpha: 128),
                                            border: Border.all(
                                              color:
                                                  AllCoustomTheme.getThemeData()
                                                      .colorScheme
                                                      .surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.done,
                                            color:
                                                AllCoustomTheme.getThemeData()
                                                    .colorScheme
                                                    .surface,
                                            size: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Expanded(
                                          child: Container(
                                            width: 120,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              'Withdrawal\nRequested',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize:
                                                    ConstanceData.SIZE_TITLE14,
                                                color: AllCoustomTheme
                                                    .getBlackAndWhiteThemeColors(),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Container(
                                          child: Text(
                                            'Withdrawal\nProcessed',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize:
                                                  ConstanceData.SIZE_TITLE14,
                                              color: AllCoustomTheme
                                                  .getBlackAndWhiteThemeColors(),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            width: 120,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Amount\nCredited',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize:
                                                    ConstanceData.SIZE_TITLE14,
                                                color: AllCoustomTheme
                                                    .getBlackAndWhiteThemeColors(),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          : const SizedBox(),
                      listData.statusRequest != ''
                          ? const Divider(
                              height: 1,
                            )
                          : const SizedBox(),
                      Container(
                        padding: EdgeInsets.only(
                            right: 16,
                            left: 16,
                            top: listData.statusRequest != '' ? 16 : 8,
                            bottom: 8),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Transaction Id',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: ConstanceData.SIZE_TITLE14,
                                  color: AllCoustomTheme.getTextThemeColors(),
                                ),
                              ),
                            ),
                            Container(
                              child: Text(
                                listData.transactionId!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: ConstanceData.SIZE_TITLE14,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            right: 16, left: 16, top: 8, bottom: 8),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 120,
                              child: Text(
                                'Transaction Date',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: ConstanceData.SIZE_TITLE14,
                                  color: AllCoustomTheme.getTextThemeColors(),
                                ),
                              ),
                            ),
                            Container(
                              child: Text(
                                DateFormat('dd MMM, HH:mm:ss a').format(
                                    DateFormat('dd/MM/yyyy,HH:mm:ss a')
                                        .parse(listData.time!)),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: ConstanceData.SIZE_TITLE14,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(
                            right: 16, left: 16, top: 8, bottom: 8),
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 120,
                              child: Text(
                                'TeamName',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: ConstanceData.SIZE_TITLE14,
                                  color: AllCoustomTheme.getTextThemeColors(),
                                ),
                              ),
                            ),
                            Container(
                              child: Text(
                                listData.teamName!,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: ConstanceData.SIZE_TITLE14,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}




