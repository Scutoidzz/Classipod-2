import 'dart:async';

import 'package:classipod/core/constants/constants.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:classipod/core/navigation/routes.dart';
import 'package:classipod/features/custom_screen_elements/custom_screen.dart';
import 'package:classipod/features/menu/controller/split_screen_controller.dart';
import 'package:classipod/features/menu/models/split_screen_type.dart';
import 'package:classipod/features/settings/controller/settings_preferences_controller.dart';
import 'package:classipod/features/settings/models/settings_preferences_model.dart';
import 'package:classipod/features/settings/widgets/settings_list_tile.dart';
import 'package:classipod/features/status_bar/widgets/status_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

enum _ExtrasDisplayItems {
  appTheme,
  deviceColor,
  clickWheelSize,
  clickWheelSensitivity,
  isTouchScreenEnabled,
  vibrate,
  clickWheelSound,
  splitScreenEnabled,
  immersiveMode,
  showAppTutorial,
  donate;

  String title(BuildContext context) {
    switch (this) {
      case appTheme:
        return context.localization.themeSettingTitle;
      case deviceColor:
        return context.localization.deviceColorSettingTitle;
      case clickWheelSize:
        return context.localization.clickWheelSizeSettingTitle;
      case clickWheelSensitivity:
        return context.localization.clickWheelSensitivitySettingTitle;
      case isTouchScreenEnabled:
        return context.localization.touchScreenSettingTitle;
      case vibrate:
        return context.localization.vibrateSettingTitle;
      case clickWheelSound:
        return context.localization.clickWheelSettingTitle;
      case splitScreenEnabled:
        return context.localization.splitScreenSettingTitle;
      case immersiveMode:
        return context.localization.immersiveModeSettingTitle;
      case showAppTutorial:
        return context.localization.showAppTutorialSettingTitle;
      case donate:
        return context.localization.donateSettingTitle;
    }
  }
}

class ExtrasScreen extends ConsumerStatefulWidget {
  const ExtrasScreen({super.key});

  @override
  ConsumerState createState() => _ExtrasScreenState();
}

class _ExtrasScreenState extends ConsumerState<ExtrasScreen>
    with CustomScreen {
  @override
  String get routeName => Routes.extras.name;

  @override
  List<_ExtrasDisplayItems> get displayItems => _ExtrasDisplayItems.values;

  @override
  Future<void> onSelectPressed() =>
      _extraAction(displayItems[selectedDisplayItem]);

  bool? _isOn(
    SettingsPreferencesModel settingsState,
    _ExtrasDisplayItems extrasItem,
  ) {
    switch (extrasItem) {
      case _ExtrasDisplayItems.isTouchScreenEnabled:
        return settingsState.isTouchScreenEnabled;
      case _ExtrasDisplayItems.vibrate:
        return settingsState.vibrate;
      case _ExtrasDisplayItems.clickWheelSound:
        return settingsState.clickWheelSound;
      case _ExtrasDisplayItems.splitScreenEnabled:
        return settingsState.splitScreenEnabled;
      case _ExtrasDisplayItems.immersiveMode:
        return settingsState.immersiveMode;
      default:
        return null;
    }
  }

  String? _getValue(
    SettingsPreferencesModel settingsState,
    _ExtrasDisplayItems extrasItem,
  ) {
    switch (extrasItem) {
      case _ExtrasDisplayItems.appTheme:
        return settingsState.appTheme.title(context);
      case _ExtrasDisplayItems.deviceColor:
        return settingsState.deviceColor.title(context);
      case _ExtrasDisplayItems.clickWheelSize:
        return settingsState.clickWheelSize.title(context);
      case _ExtrasDisplayItems.clickWheelSensitivity:
        return settingsState.clickWheelSensitivity.title(context);
      default:
        final bool? isOn = _isOn(settingsState, extrasItem);
        if (isOn == null) {
          return null;
        }
        return isOn
            ? context.localization.tileValueOn
            : context.localization.tileValueOff;
    }
  }

  Future<void> _extraAction(_ExtrasDisplayItems extrasItem) async {
    setState(() => selectedDisplayItem = displayItems.indexOf(extrasItem));
    switch (extrasItem) {
      case _ExtrasDisplayItems.appTheme:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleAppTheme();
        break;
      case _ExtrasDisplayItems.deviceColor:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .cycleDeviceColor();
        break;
      case _ExtrasDisplayItems.clickWheelSize:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelSize();
        break;
      case _ExtrasDisplayItems.clickWheelSensitivity:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelSensitivity();
        break;
      case _ExtrasDisplayItems.isTouchScreenEnabled:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleTouchScreen();
        break;
      case _ExtrasDisplayItems.vibrate:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleVibrate();
        break;
      case _ExtrasDisplayItems.clickWheelSound:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleClickWheelSound(context);
        break;
      case _ExtrasDisplayItems.splitScreenEnabled:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleSplitScreen();
        break;
      case _ExtrasDisplayItems.immersiveMode:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .toggleImmersiveMode();
        break;
      case _ExtrasDisplayItems.showAppTutorial:
        await ref
            .read(settingsPreferencesControllerProvider.notifier)
            .showAppTutorial();
        break;
      case _ExtrasDisplayItems.donate:
        await launchUrl(
          Uri.parse(Constants.donationLinkUrl),
          mode: LaunchMode.externalApplication,
        );
        break;
    }
  }

  Future<void> _changeSplitScreenType() async {
    await Future.delayed(const Duration(milliseconds: 150));
    switch (displayItems[selectedDisplayItem]) {
      case _ExtrasDisplayItems.appTheme:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.appTheme;
        break;
      case _ExtrasDisplayItems.deviceColor:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.deviceColor;
        break;
      case _ExtrasDisplayItems.clickWheelSize:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSize;
        break;
      case _ExtrasDisplayItems.clickWheelSensitivity:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSensitivity;
        break;
      case _ExtrasDisplayItems.isTouchScreenEnabled:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.touchScreen;
        break;
      case _ExtrasDisplayItems.vibrate:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.vibrate;
        break;
      case _ExtrasDisplayItems.clickWheelSound:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.clickWheelSound;
        break;
      case _ExtrasDisplayItems.splitScreenEnabled:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.splitScreenMode;
        break;
      case _ExtrasDisplayItems.immersiveMode:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.immersiveMode;
        break;
      case _ExtrasDisplayItems.showAppTutorial:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.showTutorialScreen;
        break;
      case _ExtrasDisplayItems.donate:
        ref.read(splitScreenControllerProvider.notifier).changeSplitScreenType =
            SplitScreenType.donate;
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = ref.watch(settingsPreferencesControllerProvider);

    unawaited(_changeSplitScreenType());

    return CupertinoPageScaffold(
      child: Column(
        children: [
          StatusBar(title: Routes.extras.title(context)),
          Flexible(
            child: CupertinoScrollbar(
              controller: scrollController,
              child: ListView.builder(
                controller: scrollController,
                itemCount: displayItems.length,
                prototypeItem: SettingsListTile(
                  text: '',
                  isSelected: false,
                  onTap: () {},
                ),
                itemBuilder: (context, index) => SettingsListTile(
                  text: displayItems[index].title(context),
                  value: _getValue(settingsState, displayItems[index]),
                  isSelected: selectedDisplayItem == index,
                  onTap: () async => _extraAction(displayItems[index]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
