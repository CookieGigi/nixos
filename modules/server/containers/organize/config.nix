_: {
  environment.etc = {
    "organize/config.yml".text = ''
      rules:
        - name: Pictures
          locations: /downloads
          filters:
            - extension: [jpg, jpeg, png, gif, webp, heic, raw, cr2, nef]
          actions:
            - move: /media/pictures/

        - name: Videos
          locations: /downloads
          filters:
            - extension: [mp4, mkv, avi, mov, webm, m4v, ts, flv]
          actions:
            - move: /media/videos/

        - name: Music
          locations: /downloads
          filters:
            - extension: [mp3, flac, ogg, wav, aac, m4a, opus]
          actions:
            - move: /media/music/

        - name: Documents
          locations: /downloads
          filters:
            - extension: [pdf, docx, doc, epub, txt, odt, csv, xlsx]
          actions:
            - move: /media/documents/
    '';
  };
}
