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

        # Security
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
        "privacy.donottrackheader.enabled" = true;
        "privacy.globalprivacycontrol.enabled" = true;

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
        vimium
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
