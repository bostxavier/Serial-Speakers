# Serial-Speakers
Companion toolkit of the *Serial Speakers* dataset, available at https://figshare.com/articles/TV_Series_Corpus/3471839

This repository contains a Python script to recover from subtitle files the copyrighted contents of the *Serial Speakers* dataset.

Users are expected to gather, for each of the three annotated TV series, the subtitle files in a single repository.

Each episode must have its own subtitle file in the *.srt* format, and be named so as to mention both the corresponding season and episode. For instance, the subitle file of the 13th episode of the second season is expected to contain the *S02E13* (or alternatively *s02e03*) substring.

Usage:

```
python3 decrypt_text.py --annot_file (path of one of the three following files: "bb.json", "got.json", "hoc.json") \
                        --subtitles_dir (directory containing the subtitle .srt files) \
                        --output_annot_file (path of the annotation file with text recovered)
 ```


For information purpose, the repository also contains the script (*encrypt_text.py*) that we used to encrypt the copyrighted content of the *Serial Speakers* dataset.
