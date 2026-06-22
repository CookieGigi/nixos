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

  prayerTimesJson = pkgs.writeShellScriptBin "prayer-times-json" ''
    ${pkgs.python3.withPackages (ps: [ps.prayer-times-calculator-offline])}/bin/python3 -c "
    from prayer_times_calculator_offline import PrayerTimesCalculator
    import json
    from datetime import datetime
    now = datetime.now()
    date_str = now.strftime('%Y-%m-%d')
    pt = PrayerTimesCalculator(
        latitude=${lib.strings.floatToString latitude},
        longitude=${lib.strings.floatToString longitude},
        calculation_method='${method}',
        date=date_str
    )
    times = pt.fetch_prayer_times()
    print(json.dumps(times))
    "
  '';
in {
  home.packages = with pkgs; [
    quickshell
    prayerTimesJson
  ];

  # Symlink quickshell QML config into ~/.config/quickshell/bar/
  # so it can be launched with `qs -c bar`.
  xdg.configFile."quickshell/bar" = {
    source = pkgs.lib.cleanSourceWith {
      src = ./.;
      filter = path: type:
        pkgs.lib.hasSuffix ".qml" path
        || type == "directory";
    };
    recursive = true;
  };
}
