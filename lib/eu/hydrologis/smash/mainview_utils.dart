/*
 * Copyright (c) 2019-2020. Antonello Andrea (www.hydrologis.com). All rights reserved.
 * Use of this source code is governed by a GPL3 license that can be
 * found in the LICENSE file.
 */

import 'dart:async';
import 'dart:io';

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:smash/eu/hydrologis/dartlibs/dartlibs.dart';
import 'package:smash/eu/hydrologis/flutterlibs/filesystem/filemanagement.dart';
import 'package:smash/eu/hydrologis/flutterlibs/filesystem/workspace.dart';
import 'package:smash/eu/hydrologis/flutterlibs/theme/colors.dart';
import 'package:smash/eu/hydrologis/flutterlibs/theme/icons.dart';
import 'package:smash/eu/hydrologis/flutterlibs/ui/dialogs.dart';
import 'package:smash/eu/hydrologis/flutterlibs/ui/ui.dart';
import 'package:smash/eu/hydrologis/flutterlibs/utils/preferences.dart';
import 'package:smash/eu/hydrologis/flutterlibs/utils/screen.dart';
import 'package:smash/eu/hydrologis/flutterlibs/utils/share.dart';
import 'package:smash/eu/hydrologis/flutterlibs/utils/validators.dart';
import 'package:smash/eu/hydrologis/smash/export/export_widget.dart';
import 'package:smash/eu/hydrologis/smash/gps/geocoding.dart';
import 'package:smash/eu/hydrologis/smash/gps/gps.dart';
import 'package:smash/eu/hydrologis/smash/import/import_widget.dart';
import 'package:smash/eu/hydrologis/smash/maps/plugins/pluginshandler.dart';
import 'package:smash/eu/hydrologis/smash/models/gps_state.dart';
import 'package:smash/eu/hydrologis/smash/models/map_state.dart';
import 'package:smash/eu/hydrologis/smash/models/info_tool_state.dart';
import 'package:smash/eu/hydrologis/smash/models/project_state.dart';
import 'package:smash/eu/hydrologis/smash/project/projects_view.dart';
import 'package:smash/eu/hydrologis/smash/util/diagnostic.dart';
import 'package:smash/eu/hydrologis/smash/util/network.dart';
import 'package:smash/eu/hydrologis/smash/widgets/about.dart';
import 'package:smash/eu/hydrologis/smash/widgets/settings.dart';

const String KEY_DO_NOTE_IN_GPS = "KEY_DO_NOTE_IN_GPS";

class DashboardUtils {
  static Widget makeToolbarBadge(Widget widget, int badgeValue) {
    if (badgeValue > 0) {
      return Badge(
        badgeColor: SmashColors.mainSelection,
        shape: BadgeShape.circle,
        toAnimate: false,
        badgeContent: Text(
          '$badgeValue',
          style: TextStyle(color: Colors.white),
        ),
        child: widget,
      );
    } else {
      return widget;
    }
  }

  static Widget makeToolbarZoomBadge(Widget widget, int badgeValue) {
    if (badgeValue > 0) {
      return Badge(
        badgeColor: SmashColors.mainDecorations,
        shape: BadgeShape.circle,
        toAnimate: false,
        badgeContent: Text(
          '$badgeValue',
          style: TextStyle(color: Colors.white),
        ),
        child: widget,
      );
    } else {
      return widget;
    }
  }

  static List<Widget> getDrawerTilesList(
      BuildContext context, MapController mapController) {
    double iconSize = SmashUI.MEDIUM_ICON_SIZE;
    Color c = SmashColors.mainDecorations;
    return [
      ListTile(
        leading: new Icon(
          Icons.folder_open,
          color: c,
          size: iconSize,
        ),
        title: SmashUI.normalText(
          "Projects",
          bold: true,
          color: c,
        ),
        onTap: () async {
          Navigator.of(context).pop();
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ProjectView()));
        },
      ),
      ListTile(
        leading: new Icon(
          SmashIcons.importIcon,
          color: c,
          size: iconSize,
        ),
        title: SmashUI.normalText(
          "Import",
          bold: true,
          color: c,
        ),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ImportWidget()));
        },
      ),
      ListTile(
        leading: new Icon(
          SmashIcons.exportIcon,
          color: c,
          size: iconSize,
        ),
        title: SmashUI.normalText(
          "Export",
          bold: true,
          color: c,
        ),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => ExportWidget()));
        },
      ),
      ListTile(
        leading: new Icon(
          Icons.settings,
          color: c,
          size: iconSize,
        ),
        title: SmashUI.normalText(
          "Settings",
          bold: true,
          color: c,
        ),
        onTap: () {
          Navigator.of(context).pop();
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => SettingsWidget()));
        },
      ),
      ListTile(
        leading: new Icon(
          MdiIcons.informationOutline,
          color: c,
          size: iconSize,
        ),
        title: SmashUI.normalText(
          "About",
          bold: true,
          color: c,
        ),
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => AboutPage())),
      ),
    ];
  }

  static List<Widget> getEndDrawerListTiles(
      BuildContext context, MapController mapController) {
    Color c = SmashColors.mainDecorations;
    var iconSize = SmashUI.MEDIUM_ICON_SIZE;
    var doDiagnostics =
        GpPreferences().getBooleanSync(KEY_ENABLE_DIAGNOSTICS, false);

    Color backColor = SmashColors.mainBackground;
    List<Widget> list = []
      ..add(Container(
        color: backColor,
        child: ListTile(
          title: SmashUI.normalText(
            "Project Info",
            bold: true,
            color: c,
          ),
          leading: new Icon(
            MdiIcons.informationOutline,
            color: c,
            size: iconSize,
          ),
          onTap: () {
            var projectState =
                Provider.of<ProjectState>(context, listen: false);
            String projectPath = projectState.projectPath;
            if (Platform.isIOS) {
              projectPath =
                  IOS_DOCUMENTSFOLDER + Workspace.makeRelative(projectPath);
            }
            var isLandscape = ScreenUtilities.isLandscape(context);
            showInfoDialog(
                projectState.context,
                "Project: ${projectState.projectName}\nDatabase: $projectPath"
                    .trim(),
                doLandscape: isLandscape,
                widgets: [
                  IconButton(
                    icon: Icon(
                      Icons.share,
                      color: SmashColors.mainDecorations,
                    ),
                    onPressed: () async {
                      ShareHandler.shareProject(projectState.context);
                    },
                  )
                ]);
          },
        ),
      ))
      ..add(getPositionTools(c, backColor, iconSize, context))
      ..add(getPluginsVisibility(c, backColor, iconSize, context))
      ..add(getVectorTools(c, backColor, iconSize, doDiagnostics, context))
      ..add(getExtras(c, backColor, iconSize, doDiagnostics, context));

    return list;
  }

  static Container getVectorTools(Color c, Color backColor, double iconSize,
      bool doDiagnostics, BuildContext context) {
    return Container(
      color: backColor,
      child: ExpansionTile(
          title: SmashUI.normalText(
            "Feature tools",
            bold: true,
            color: c,
          ),
          children: [
            ListTile(
              title: SmashUI.normalText(
                "Query layers",
                bold: true,
                color: c,
              ),
              leading:
                  Consumer<InfoToolState>(builder: (context, infoState, child) {
                return Checkbox(
                    value: infoState.isEnabled,
                    onChanged: (value) {
                      infoState.setEnabled(value);
                    });
              }),
            ),
          ]),
    );
  }

  static Container getExtras(Color c, Color backColor, double iconSize,
      bool doDiagnostics, BuildContext context) {
    return Container(
      color: backColor,
      child: ExpansionTile(
          title: SmashUI.normalText(
            "Extras",
            bold: true,
            color: c,
          ),
          children: [
            ListTile(
              leading: new Icon(
                Icons.insert_emoticon,
                color: c,
                size: iconSize,
              ),
              title: SmashUI.normalText(
                "Available icons",
                bold: true,
                color: c,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => IconsWidget()));
              },
            ),
            ListTile(
              leading: new Icon(
                Icons.map,
                color: c,
                size: iconSize,
              ),
              title: SmashUI.normalText(
                "Offline maps",
                bold: true,
                color: c,
              ),
              onTap: () async {
                var mapsFolder = await Workspace.getMapsFolder();
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MapsDownloadWidget(mapsFolder)));
              },
            ),
            doDiagnostics
                ? ListTile(
                    leading: new Icon(
                      MdiIcons.bugOutline,
                      color: c,
                      size: iconSize,
                    ),
                    title: SmashUI.normalText(
                      "Run diagnostics",
                      bold: true,
                      color: c,
                    ),
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => DiagnosticWidget())),
                  )
                : Container(),
          ]),
    );
  }

  static Container getPluginsVisibility(
      Color c, Color backColor, double iconSize, BuildContext context) {
    return Container(
      color: backColor,
      child: ExpansionTile(
        title: SmashUI.normalText(
          "Map Plugins",
          bold: true,
          color: c,
        ),
        children: [
          PluginCheckboxWidget(PluginsHandler.SCALE.key),
          PluginCheckboxWidget(PluginsHandler.GRID.key),
          PluginCheckboxWidget(PluginsHandler.CROSS.key),
          PluginCheckboxWidget(PluginsHandler.GPS.key),
        ],
      ),
    );
  }

  static Container getPositionTools(
      Color c, Color backColor, double iconSize, BuildContext context) {
    return Container(
      color: backColor,
      child: ExpansionTile(
        title: SmashUI.normalText(
          "Position Tools",
          bold: true,
          color: c,
        ),
        children: [
          ListTile(
            leading: new Icon(
              MdiIcons.navigation,
              color: c,
              size: iconSize,
            ),
            title: SmashUI.normalText(
              "Go to",
              bold: true,
              color: c,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => GeocodingPage()));
            },
          ),
          ListTile(
            leading: new Icon(
              MdiIcons.shareVariant,
              color: c,
              size: iconSize,
            ),
            title: SmashUI.normalText(
              "Share position",
              bold: true,
              color: c,
            ),
            onTap: () {
              var gpsState = Provider.of<GpsState>(context, listen: false);
              var pos = gpsState.lastGpsPosition;
              StringBuffer sb = StringBuffer();
              sb.write("Latitude: ");
              sb.write(pos.latitude.toStringAsFixed(KEY_LATLONG_DECIMALS));
              sb.write("\nLongitude: ");
              sb.write(pos.longitude.toStringAsFixed(KEY_LATLONG_DECIMALS));
              sb.write("\nAltitude: ");
              sb.write(pos.altitude.toStringAsFixed(KEY_ELEV_DECIMALS));
              sb.write("\nAccuracy: ");
              sb.write(pos.accuracy.toStringAsFixed(KEY_ELEV_DECIMALS));
              sb.write("\nTimestamp: ");
              sb.write(TimeUtilities.ISO8601_TS_FORMATTER.format(
                  DateTime.fromMillisecondsSinceEpoch(pos.time.round())));
              ShareHandler.shareText(sb.toString());
            },
          ),
          Consumer<SmashMapState>(builder: (context, mapState, child) {
            return ListTile(
              title: SmashUI.normalText("Center on GPS", bold: true, color: c),
              leading: Checkbox(
                  value: mapState.centerOnGps,
                  onChanged: (value) {
                    mapState.centerOnGps = value;
                  }),
            );
          }),
          Platform.isAndroid && EXPERIMENTAL_ROTATION_ENABLED
              ? Consumer<SmashMapState>(builder: (context, mapState, child) {
                  return ListTile(
                    title: SmashUI.normalText("Rotate map with GPS",
                        bold: true, color: c),
                    leading: Checkbox(
                        value: mapState.rotateOnHeading,
                        onChanged: (value) {
                          if (!value) {
                            mapState.heading = 0;
                          }
                          mapState.rotateOnHeading = value;
                        }),
                  );
                })
              : Container(),
        ],
      ),
    );
  }

  static Future _createNewProject(BuildContext context) async {
    String projectName =
        "smash_${TimeUtilities.DATE_TS_FORMATTER.format(DateTime.now())}";

    var userString = await showInputDialog(
      context,
      "New Project",
      "Enter a name for the new project or accept the proposed.",
      hintText: '',
      defaultText: projectName,
      validationFunction: fileNameValidator,
    );
    if (userString != null) {
      if (userString.trim().length == 0) userString = projectName;
      var file = await Workspace.getProjectsFolder();
      var newPath = join(file.path, userString);
      if (!newPath.endsWith(".gpap")) {
        newPath = "$newPath.gpap";
      }
      var gpFile = new File(newPath);
      var projectState = Provider.of<ProjectState>(context, listen: false);
      await projectState.setNewProject(gpFile.path);
      await projectState.reloadProject();
    }

    Navigator.of(context).pop();
  }

  static Icon getGpsStatusIcon(GpsStatus status, [double iconSize]) {
    Color color;
    IconData iconData;
    switch (status) {
      case GpsStatus.OFF:
        {
          color = SmashColors.gpsOff;
          iconData = Icons.gps_off;
          break;
        }
      case GpsStatus.ON_WITH_FIX:
        {
          color = SmashColors.gpsOnWithFix;
          iconData = Icons.gps_fixed;
          break;
        }
      case GpsStatus.ON_NO_FIX:
        {
          iconData = Icons.gps_not_fixed;
          color = SmashColors.gpsOnNoFix;
          break;
        }
      case GpsStatus.LOGGING:
        {
          iconData = Icons.gps_fixed;
          color = SmashColors.gpsLogging;
          break;
        }
      case GpsStatus.NOPERMISSION:
        {
          iconData = Icons.gps_off;
          color = SmashColors.gpsNoPermission;
          break;
        }
    }
    return iconSize != null
        ? Icon(
            iconData,
            color: color,
            size: iconSize,
          )
        : Icon(
            iconData,
            color: color,
          );
  }

  static Icon getLoggingIcon(GpsStatus status) {
    Color color;
    IconData iconData;
    switch (status) {
      case GpsStatus.LOGGING:
        {
          iconData = SmashIcons.logIcon;
          color = SmashColors.gpsLogging;
          break;
        }
      case GpsStatus.OFF:
      case GpsStatus.ON_WITH_FIX:
      case GpsStatus.ON_NO_FIX:
      case GpsStatus.NOPERMISSION:
        {
          iconData = SmashIcons.logIcon;
          color = SmashColors.mainBackground;
          break;
        }
      default:
        {
          iconData = SmashIcons.logIcon;
          color = SmashColors.mainBackground;
        }
    }
    return Icon(
      iconData,
      color: color,
    );
  }
}