/// What Hargreaves brings on the tray besides the water: a kind word and a
/// curiosity. All bundled with the app; nothing is fetched.
///
/// Contributors: keep facts well established, phrase them as a butler would,
/// and never address the user here (the reminder title already does).
library;

/// Kind words. One accompanies each reminder.
const kindWords = [
  'I took the liberty of chilling it a touch.',
  'I have polished the glass especially.',
  'Do take a moment; the world will keep.',
  'The household runs smoothly, I am pleased to report.',
  'A small glass, a large improvement.',
  'No need to rise; I have brought it to you.',
  'Steady progress, quietly made. Most admirable.',
  'I find a glass of water improves almost any afternoon.',
  'Consider it a brief recess from your labours.',
  'Your future self sends compliments.',
  'Lemon is available on request.',
  'The papers can wait. This cannot, quite.',
  'Hydration and good manners never go out of fashion.',
  'Even the ferns in the conservatory are envious.',
  'Water first; then conquer the day, as is your custom.',
  'A moment of pause becomes you.',
  'You are doing splendidly, if I may be so bold.',
  'I chose the nicest glass in the cabinet.',
  'One glass at a time is how fine days are built.',
  'Your eyes and your temper will both be the brighter for it.',
  'Pray do not let the tea persuade you otherwise.',
  'A fine moment for it, whatever the weather.',
  'The household is quietly proud of you.',
  'Fresh as the morning, or very nearly.',
  'Sip at your leisure; I am in no hurry.',
  'Should you be busy, I shall simply leave it by your elbow.',
  'A sensible choice, as ever.',
  'Your posture, if I may, would also welcome a stretch.',
  'I have drawn it from the coolest jug.',
  'Small kindnesses to oneself are the most dependable kind.',
];

/// Curiosities about water, the body and the Victorian waterworks.
const curiosities = [
  'Ice floats because water expands by about nine per cent as it freezes, '
      'so lakes freeze from the top and shelter the fish beneath.',
  'Water is at its densest at about four degrees Celsius, not at freezing.',
  'Roughly three-quarters of the human brain is water.',
  'An adult body is somewhere between half and three-fifths water.',
  'Blood plasma is around nine parts in ten water.',
  'Saliva is more than ninety-nine per cent water.',
  'Your kidneys filter some 180 litres of blood plasma each day, returning '
      'nearly all of it.',
  'You lose a few hundred millilitres of water a day simply by breathing.',
  'About a fifth of the water one takes in comes from food rather than '
      'drink.',
  'A cucumber is about ninety-six per cent water; a watermelon, about '
      'ninety-two.',
  'Tea is almost entirely water, and a cup counts towards the day quite '
      'respectably.',
  'Even mild dehydration can dull concentration and invite a headache.',
  'The sense of thirst grows fainter with age, so older folk do well to '
      'drink by habit rather than by thirst.',
  'In hot, hard work a person may sweat away more than a litre an hour.',
  'Healthy kidneys can pass only about a litre an hour, which is why '
      'drinking a great deal at once is unwise. Steady glasses are best.',
  'Pale straw is the colour to hope for, should you be inclined to check.',
  'A newborn baby is roughly three-quarters water.',
  'About seventy-one per cent of the Earth is covered by water.',
  'The oceans hold about ninety-seven per cent of all the water on Earth.',
  'Only about three per cent of Earth\'s water is fresh, and most of that '
      'is locked away in ice.',
  'Lake Baikal in Siberia holds roughly a fifth of the world\'s unfrozen '
      'fresh surface water.',
  'The Amazon carries more water to the sea than any other river by a '
      'very wide margin.',
  'A modest cumulus cloud may hold some five hundred tonnes of water.',
  'Raindrops are not tear-shaped: small ones are round, and larger ones '
      'flatten like a bread roll as they fall.',
  'Snowflakes have six sides because water molecules lock together in a '
      'hexagonal pattern when they freeze.',
  'The scent of rain on dry earth has a name, petrichor, coined in 1964.',
  'On the summit of Everest, water boils at only about seventy degrees '
      'Celsius.',
  'Pure water conducts electricity poorly; it is the dissolved minerals '
      'that carry the current.',
  'Water dissolves more substances than almost any other common liquid, '
      'hence its title, the universal solvent.',
  'Surface tension is strong enough to let pond skaters stroll upon water.',
  'A water molecule is bent, its two hydrogen atoms set at about 104.5 '
      'degrees.',
  'Ice made from heavy water sinks in an ordinary glass.',
  'Under certain conditions hot water may freeze faster than cold. It is '
      'called the Mpemba effect, and scientists still debate it.',
  'Water\'s great capacity for heat is why the sea keeps coastal climates '
      'mild.',
  'The tallest redwoods draw water more than a hundred metres up their '
      'trunks without a single pump.',
  'A camel\'s hump stores fat, not water.',
  'The Dead Sea is so salty that one floats in it without the slightest '
      'effort.',
  'Mawsynram in Meghalaya is counted among the wettest places on Earth, '
      'with nearly twelve metres of rain in a typical year.',
  'Cherrapunji, nearby, recorded over twenty-six metres of rain in the '
      'twelve months from August 1860.',
  'In 1854 Dr John Snow traced a cholera outbreak in Soho to a single '
      'pump on Broad Street, and had its handle removed.',
  'The Great Stink of 1858 so offended Parliament that it funded Joseph '
      'Bazalgette\'s great London sewers.',
  'London\'s first free public drinking fountain opened in 1859, at '
      'Holborn. Crowds queued to use it.',
  'The hot springs at Bath fell as rain thousands of years before they '
      'rose again, warm, into the Roman baths.',
  'The last of the Thames frost fairs was held in 1814, when the river '
      'froze hard enough to lead an elephant across.',
  'The water in your glass may well have been ice, cloud and sea many '
      'times over since the Earth was young.',
];

/// Picks the kind word and curiosity for a given glass, cycling through the
/// lists so the same one doesn't come round again for a good while.
abstract final class Garnish {
  /// A running number for each glass of each day.
  static int sequence(DateTime day, int slot, int glassesPerDay) {
    final days = DateTime.utc(
      day.year,
      day.month,
      day.day,
    ).difference(DateTime.utc(2026)).inDays;
    return days * glassesPerDay + slot;
  }

  static String kindWord(int seq) =>
      kindWords[(seq * 7 + 3) % kindWords.length];

  static String curiosity(int seq) => curiosities[seq % curiosities.length];
}
