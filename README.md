# Serial-Speakers
Companion toolkit of the *Serial Speakers* dataset, available at https://figshare.com/articles/TV_Series_Corpus/3471839

This repository contains a Python script to recover from subtitle files the copyrighted contents of the *Serial Speakers* dataset.

Users are expected to gather, for each of the three annotated TV series, the subtitle files in a single repository.

Each episode must have its own subtitle file in the *.srt* format, and be named so as to mention both the corresponding season and episode. For instance, the subtitle file of the 13th episode of the 2nd season is expected to contain the *S02E13* (or alternatively *s02e03*) substring.

## Usage

```
python3 decrypt_text.py --annot_file (path of one of the three following files: "bb.json", "got.json", "hoc.json") \
                        --subtitles_dir (directory containing the subtitle .srt files) \
                        --output_annot_file (path of the output annotation file with the text as recovered)
 ```
Should you experience codec issues with your subtitles, you would set the following additional parameter to another value than the default "utf-8" value:

```
                        --subtitles_encoding (encoding, for instance "iso-8859-1"...)
```

## Output

The execution of the script displays on the standard output, as the text is being recovered, the average number of deletions/substitutions by episode your particular set of subtitles is causing in the annotated dataset. Deletions are signaled in the output file by an empty "<>" tag, and substitutions by an enclosing tag, for instance "\<Why\>". You should expect a rather low number of deletions/substitutions. For information, with my own set of subtitles, I obtain the following average number of deletions/substitutions by episode (included punctuation issues, responsible for most of the differences):

  *Breaking Bad*
  ```
  Season 1: 30.00 del (avg.); 24.57 sub (avg.)
  Season 2: 39.69 del (avg.); 37.77 sub (avg.)
  Season 3: 52.23 del (avg.); 15.31 sub (avg.)
  Season 4: 72.38 del (avg.); 54.15 sub (avg.)
  Season 5: 60.75 del (avg.); 39.44 sub (avg.)
  ```
  *Game of Thrones*
  ```
  Season 1: 03.20 del (avg.); 16.90 sub (avg.)
  Season 2: 03.70 del (avg.); 01.10 sub (avg.)
  Season 3: 26.00 del (avg.); 04.80 sub (avg.)
  Season 4: 44.20 del (avg.); 04.30 sub (avg.)
  Season 5: 24.30 del (avg.); 11.40 sub (avg.)
  Season 6: 17.30 del (avg.); 03.70 sub (avg.)
  Season 7: 02.57 del (avg.); 00.71 sub (avg.)
  ```
  *House of Cards*
  ```
  Season 1: 08.23 del (avg.); 04.23 sub (avg.)
  Season 2: 10.54 del (avg.); 03.69 sub (avg.)
  ```
## Other files

In addition, and for information purpose, the repository also contains the script (*encrypt_text.py*) that we used to encrypt the copyrighted content of the *Serial Speakers* dataset.
