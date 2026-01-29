/// App-wide icon definitions using HugeIcons
/// This file centralizes all icon usage for easy theming and replacement
library;

import 'package:hugeicons/hugeicons.dart';
import 'package:flutter/material.dart';

/// App icons using HugeIcons package
/// Reference: https://pub.dev/packages/hugeicons
class AppIcons {
  AppIcons._();

  // Navigation
  static const dashboard = HugeIcons.strokeRoundedHome01;
  static const properties = HugeIcons.strokeRoundedBuilding06;
  static const tenants = HugeIcons.strokeRoundedUserGroup;
  static const payments = HugeIcons.strokeRoundedMoneyReceiveSquare;
  static const more = HugeIcons.strokeRoundedMenu01;
  static const invoices = HugeIcons.strokeRoundedInvoice01;
  static const maintenance = HugeIcons.strokeRoundedWrench01;
  static const settings = HugeIcons.strokeRoundedSettings01;
  
  // Actions
  static const add = HugeIcons.strokeRoundedAdd01;
  static const edit = HugeIcons.strokeRoundedEdit01;
  static const delete = HugeIcons.strokeRoundedDelete01;
  static const close = HugeIcons.strokeRoundedCancel01;
  static const search = HugeIcons.strokeRoundedSearch01;
  static const filter = HugeIcons.strokeRoundedFilter;
  static const sort = HugeIcons.strokeRoundedSortByUp01;
  static const refresh = HugeIcons.strokeRoundedRefresh;
  static const share = HugeIcons.strokeRoundedShare01;
  static const copy = HugeIcons.strokeRoundedCopy01;
  static const download = HugeIcons.strokeRoundedDownload01;
  static const upload = HugeIcons.strokeRoundedUpload01;
  static const send = HugeIcons.strokeRoundedSent;
  static const save = HugeIcons.strokeRoundedTick01;
  
  // Navigation arrows
  static const back = HugeIcons.strokeRoundedArrowLeft01;
  static const forward = HugeIcons.strokeRoundedArrowRight01;
  static const up = HugeIcons.strokeRoundedArrowUp01;
  static const down = HugeIcons.strokeRoundedArrowDown01;
  static const chevronRight = HugeIcons.strokeRoundedArrowRight01;
  static const chevronDown = HugeIcons.strokeRoundedArrowDown01;
  static const expand = HugeIcons.strokeRoundedArrowExpand01;
  
  // Property related
  static const property = HugeIcons.strokeRoundedBuilding06;
  static const unit = HugeIcons.strokeRoundedHome12;
  static const location = HugeIcons.strokeRoundedLocation01;
  static const calendar = HugeIcons.strokeRoundedCalendar01;
  static const key = HugeIcons.strokeRoundedKey02;
  static const door = HugeIcons.strokeRoundedDoor;
  
  // Tenant related
  static const person = HugeIcons.strokeRoundedUser;
  static const people = HugeIcons.strokeRoundedUserGroup;
  static const phone = HugeIcons.strokeRoundedSmartPhone01;
  static const email = HugeIcons.strokeRoundedMail01;
  static const call = HugeIcons.strokeRoundedCall;
  static const message = HugeIcons.strokeRoundedMessage01;
  static const chat = HugeIcons.strokeRoundedBubbleChat;
  
  // Finance related
  static const money = HugeIcons.strokeRoundedMoney02;
  static const payment = HugeIcons.strokeRoundedMoneyReceiveSquare;
  static const invoice = HugeIcons.strokeRoundedInvoice01;
  static const receipt = HugeIcons.strokeRoundedInvoice02;
  static const wallet = HugeIcons.strokeRoundedWallet01;
  static const bank = HugeIcons.strokeRoundedBank;
  static const trending = HugeIcons.strokeRoundedChartLineData01;
  static const chart = HugeIcons.strokeRoundedChartRose;
  
  // Status
  static const success = HugeIcons.strokeRoundedCheckmarkCircle02;
  static const error = HugeIcons.strokeRoundedAlertCircle;
  static const warning = HugeIcons.strokeRoundedAlert02;
  static const info = HugeIcons.strokeRoundedInformationCircle;
  static const pending = HugeIcons.strokeRoundedClock01;
  static const active = HugeIcons.strokeRoundedRadioButton;
  static const inactive = HugeIcons.strokeRoundedCircle;
  
  // Maintenance
  static const tools = HugeIcons.strokeRoundedWrench01;
  static const repair = HugeIcons.strokeRoundedRepair;
  static const ticket = HugeIcons.strokeRoundedTicket01;
  static const priority = HugeIcons.strokeRoundedFlag01;
  static const urgent = HugeIcons.strokeRoundedFire;
  
  // Media
  static const image = HugeIcons.strokeRoundedImage01;
  static const camera = HugeIcons.strokeRoundedCamera01;
  static const gallery = HugeIcons.strokeRoundedImageAdd01;
  static const video = HugeIcons.strokeRoundedVideo01;
  static const attachment = HugeIcons.strokeRoundedAttachment01;
  static const file = HugeIcons.strokeRoundedFile01;
  static const document = HugeIcons.strokeRoundedFile02;
  static const pdf = HugeIcons.strokeRoundedPdf01;
  
  // Auth
  static const login = HugeIcons.strokeRoundedLogin01;
  static const logout = HugeIcons.strokeRoundedLogout01;
  static const lock = HugeIcons.strokeRoundedLockKey;
  static const unlock = HugeIcons.strokeRoundedSquareUnlock01;
  static const visibility = HugeIcons.strokeRoundedView;
  static const visibilityOff = HugeIcons.strokeRoundedViewOff;
  static const fingerprint = HugeIcons.strokeRoundedFingerprintScan;
  
  // Misc
  static const star = HugeIcons.strokeRoundedStar;
  static const favorite = HugeIcons.strokeRoundedFavourite;
  static const notification = HugeIcons.strokeRoundedNotification01;
  static const help = HugeIcons.strokeRoundedHelpCircle;
  static const language = HugeIcons.strokeRoundedGlobe02;
  static const theme = HugeIcons.strokeRoundedSun01;
  static const link = HugeIcons.strokeRoundedLink01;
  static const qr = HugeIcons.strokeRoundedQrCode;
  static const loading = HugeIcons.strokeRoundedLoading01;
  static const empty = HugeIcons.strokeRoundedInbox;
  static const noImage = HugeIcons.strokeRoundedImageNotFound01;
  static const brokenImage = HugeIcons.strokeRoundedImageNotFound01;
  static const house = HugeIcons.strokeRoundedHome01;
  static const apartment = HugeIcons.strokeRoundedBuilding06;
  static const commercial = HugeIcons.strokeRoundedStore01;
  static const land = HugeIcons.strokeRoundedMapsGlobal01;
  static const water = HugeIcons.strokeRoundedDroplet;
  static const power = HugeIcons.strokeRoundedFlash;
  static const meter = HugeIcons.strokeRoundedDashboardSpeed01;
  static const clipboard = HugeIcons.strokeRoundedClipboard;
  static const notes = HugeIcons.strokeRoundedNote;
  static const lease = HugeIcons.strokeRoundedFileAttachment;
  static const contract = HugeIcons.strokeRoundedAgreement01;
  static const moveIn = HugeIcons.strokeRoundedMove01;
  static const moveOut = HugeIcons.strokeRoundedLogout01;
  static const charges = HugeIcons.strokeRoundedCreditCard;
  static const billing = HugeIcons.strokeRoundedInvoice02;
  static const marketing = HugeIcons.strokeRoundedMegaphone01;
  static const explore = HugeIcons.strokeRoundedGlobe02;
  static const enquiry = HugeIcons.strokeRoundedMessageQuestion;
  static const vacant = HugeIcons.strokeRoundedCheckList;
}

/// Helper widget for HugeIcon with common defaults
class AppIcon extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? color;

  const AppIcon(this.icon, {super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: icon,
      size: size ?? 24,
      color: color ?? Theme.of(context).iconTheme.color ?? Colors.black,
    );
  }
}
