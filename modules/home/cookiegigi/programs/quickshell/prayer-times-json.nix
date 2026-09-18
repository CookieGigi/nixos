{
  pkgs,
  lib,
  ...
}: let
  # ── Prayer times configuration ──────────────────────────
  # Adjust these to your location and preferred method.
  # Methods: mwl, isna, egypt, makkah, karachi, france,
  #          turkey, singapore, dubai, etc.
  latitude = 48.8566;
  longitude = 2.3522;
  method = "france";
in
  pkgs.writeShellScriptBin "prayer-times-json" ''
    ${pkgs.python3.withPackages (ps: [ps.prayer-times-calculator-offline])}/bin/python3 -c "
    from prayer_times_calculator_offline import PrayerTimesCalculator
    import json
    from datetime import datetime, timedelta
    now = datetime.now()
    date_str = now.strftime('%Y-%m-%d')
    pt = PrayerTimesCalculator(
        latitude=${lib.strings.floatToString latitude},
        longitude=${lib.strings.floatToString longitude},
        calculation_method='${method}',
        date=date_str
    )
    times = pt.fetch_prayer_times()
    tomorrow = PrayerTimesCalculator(
        latitude=${lib.strings.floatToString latitude},
        longitude=${lib.strings.floatToString longitude},
        calculation_method='${method}',
        date=(now + timedelta(days=1)).strftime('%Y-%m-%d')
    )
    times['calculationDate'] = date_str
    times['tomorrowFajr'] = tomorrow.fetch_prayer_times()['Fajr']
    print(json.dumps(times))
    "
  ''
