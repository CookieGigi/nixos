{pkgs, ...}: {
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";

    # ------------------------------------------------------------------
    # Enterprise policies
    # ------------------------------------------------------------------
    policies = {
      DisablePocket = true;
      DisableFirefoxStudies = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      DisableFormHistory = true;
      SearchSuggestEnabled = false;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
    };

    # ------------------------------------------------------------------
    # Profile
    # ------------------------------------------------------------------
    profiles."cookiegigi" = {
      isDefault = true;
      name = "cookiegigi";

      # -- about:config preferences ------------------------------------
      settings = {
        # Privacy & telemetry
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "toolkit.telemetry.reportingpolicy.firstRun" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;

        # Sponsored content
        "browser.newtabpage.activity-stream.feeds.snippets" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.topsites.contile.enabled" = false;

        # Cookies & tracking protection
        "network.cookie.cookieBehavior" = 1;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.trackingprotection.cryptomining.enabled" = true;
        "privacy.trackingprotection.fingerprinting.enabled" = true;

        # Network hardening
        "dom.security.https_only_mode" = true;
        "security.tls.version.min" = 3;
        "security.ssl.require_safe_negotiation" = true;
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;

        # Referer headers
        "network.http.referer.XOriginTrimmingPolicy" = 2;

        # WebRTC (disable — use dedicated apps for calls)
        "media.peerconnection.enabled" = false;

        # Geolocation & sensors
        "geo.enabled" = false;
        "device.sensors.enabled" = false;
        "dom.battery.enabled" = false;
        "media.navigator.enabled" = false;

        # Fingerprinting resistance
        "privacy.resistFingerprinting" = true;

        # Password manager (disabled — using Proton Pass)
        "signon.rememberSignons" = false;
        "signon.autofillForms" = false;

        # Misc
        "beacon.enabled" = false;
        "dom.event.clipboardevents.enabled" = false;
        "network.IDN_show_punycode" = true;

        # UI
        "browser.tabs.tabmanager.enabled" = false;
        "browser.uidensity" = 1;
      };

      # -- Search engine defaults --------------------------------------
      search = {
        default = "ddg";
        privateDefault = "ddg";
        order = ["ddg" "google"];
      };

      # -- userChrome CSS ----------------------------------------------
      userChrome = ''
        /* Compact title bar */
        #titlebar { max-height: 32px; }
        .titlebar-buttonbox { height: 32px; }
      '';

      # -- Extensions ---------------------------------------------------
      extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
        ublock-origin
        sponsorblock
        darkreader
        privacy-badger
        clearurls
        proton-pass
        multi-account-containers
        consent-o-matic
        port-authority
      ];
    };
  };

  home.persistence."/persist" = {
    directories = [
      ".mozilla"
      ".config/mozilla"
    ];
  };
}
