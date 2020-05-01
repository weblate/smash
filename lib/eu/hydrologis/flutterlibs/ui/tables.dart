/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */

import 'package:flutter/material.dart';
import 'package:smash/eu/hydrologis/flutterlibs/ui/ui.dart';

class TableUtilities {
  static TableCell cellForString(String data,
      {color: Colors.black, bool doSmallText = false}) {
    return TableCell(
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: doSmallText
            ? SmashUI.smallText(data, color: color)
            : SmashUI.normalText(data, color: color),
      ),
    );
  }

  static Table fromMap(Map<String, dynamic> map,
      {bool withBorder = false,
      Color borderColor = Colors.blueAccent,
      bool doSmallText = false,
      List<double> colWidthFlex = const [0.4, 0.6]}) {
    List<TableRow> rows = [];

    map.forEach((key, value) {
      var row = TableRow(
        children: [
          cellForString(key, doSmallText: doSmallText),
          cellForString(value.toString(), doSmallText: doSmallText),
        ],
      );
      rows.add(row);
    });

    return Table(
      border: withBorder
          ? TableBorder(
              bottom: BorderSide(color: borderColor, width: 2),
              left: BorderSide(color: borderColor, width: 2),
              right: BorderSide(color: borderColor, width: 2),
              top: BorderSide(color: borderColor, width: 2),
              horizontalInside: BorderSide(color: borderColor, width: 1),
              verticalInside: BorderSide(color: borderColor, width: 1),
            )
          : null,
      columnWidths: {
        0: FlexColumnWidth(colWidthFlex[0]),
        1: FlexColumnWidth(colWidthFlex[1]),
      },
      children: rows,
    );
  }
}