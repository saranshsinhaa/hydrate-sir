/// Fixed screen copy in Hargreaves' voice. Lines that depend on circumstance
/// live in `hargreaves.dart`.
library;

abstract final class WelcomeText {
  static const since = 'In service since MMXXVI';
  static const brandTop = 'HYDRATE,';
  static const brandSir = 'Sir';
  static const role = 'Hargreaves · Butler';
  static const greeting = 'Good day.\nHargreaves, at your service.';
  static const intro =
      'I shall see to it that you never go thirsty. First, if I may, a few '
      'discreet questions.';
  static const proceed = 'Very well, proceed';
  static const privacy = 'Your particulars never leave this house.';
}

abstract final class ParticularsText {
  static const step = 'I of III';
  static const title = 'A Few Particulars';
  static const address = 'How shall I address you?';
  static const sir = 'Sir';
  static const madam = 'Madam';
  static const byName = 'By name';
  static const nameHint = 'Your name, if you please';
  static const weight = 'Your weight';
  static const age = 'Your age';
  static const exertion = 'Your daily exertion';
  static const leisurely = 'Leisurely';
  static const moderate = 'Moderate';
  static const vigorous = 'Vigorous';
  static const climate = 'The climate hereabouts';
  static const temperate = 'Temperate';
  static const warm = 'Rather warm';
  static const estimate = 'I should think, daily';
}

abstract final class HoursText {
  static const step = 'II of III';
  static const title = 'Your Hours';
  static const rise = 'You rise at';
  static const retire = 'You retire at';
  static const glance = 'The day at a glance';
  static const quiet = 'The hour before bed, I keep quiet';
  static const sleep = 'You sleep; I do not disturb';
  static const silence =
      'I shall fall silent an hour before you retire. I should never dream of '
      'disturbing your rest.';
}

abstract final class ArrangementsText {
  static const step = 'III of III';
  static const title = 'The Arrangements';
  static const propose = 'I should propose, daily:';
  static const asYouWish = 'As you wish';
  static const glassSize = 'The size of each glass, in ml';
  static const accept = 'That will do nicely';
  static const disclaimer =
      'A sensible estimate for healthy adults; not medical advice. Your '
      'physician, naturally, outranks me.';
}

abstract final class CommonText {
  static const back = '‹ Back';
  static const continueOn = 'Continue';
  static const today = 'Today';
  static const cellarBook = 'Cellar Book';
  static const instructions = 'Instructions';
  static const millilitres = 'millilitres';
}

abstract final class TodayText {
  static const atService = 'At your service';
  static const hargreaves = 'Hargreaves';
  static const takenToday = 'Taken today';
  static const signature = '— Hargreaves';
  static const differentAmount = 'I had a different amount';
  static const undo = 'Undo the last glass';
  static const undone = 'Very good. I have struck it from the book.';
  static const nothingToUndo = 'There is nothing to strike out today.';
  static const sheetTitle = 'How much did you take?';
  static const custom = 'Another amount, in ml';
  static const record = 'Record it';
  static const allServed = 'All\nserved';
}

abstract final class BatteryText {
  static const title = 'The battery warden';
  static const exempt = 'Leaves me be';
  static const restricts = 'May delay me';
  static const showMe = 'Show me how';
  static const neverMind = 'Never mind';
  static const openSettings = 'Open the settings';
  static const steps =
      'In the page I shall open, choose Battery (on some phones, App '
      'battery usage) and set it to Unrestricted. Then press back, and I '
      'shall be at your service on the minute.';
}
