# Serial-Speakers
Companion toolkit of the *Serial Speakers* dataset, available at https://figshare.com/articles/TV_Series_Corpus/3471839

This repository mainly contains a *Python* script to recover from subtitle files the copyrighted contents of the *Serial Speakers* dataset.

Users are expected to gather, for each of the three annotated TV series, the subtitle files in a single repository.

Each episode must have its own subtitle file in the *.srt* format, and be named so as to mention both the corresponding season and episode. For instance, the subtitle file of the 13th episode of the 2nd season is expected to contain the *S02E13* (or alternatively *s02e03*) substring.

## Usage

```
python3 decrypt_text.py --annot_file (path of one of the three following files: "bb.json", "got.json", "hoc.json") \
                        --subtitles_dir (directory containing the subtitle .srt files) \
                        --output_annot_file (path of the output annotation file with the text as recovered)
 ```
In case you experience codec issues with your subtitles, try to set the following additional parameter to another value than the default "utf-8":

```
                        --subtitles_encoding (encoding, for instance "iso-8859-1"...)
```

## Output

The execution of the script displays on the standard output, as the text is being recovered, the average number of deletions/substitutions by episode your particular set of subtitles is causing in the annotated dataset. Deletions are signaled in the output file by an empty *"<>"* tag, and substitutions by an enclosing tag, for instance *"\<Why\>"*. You should expect a rather low number of deletions/substitutions. For information, with my own set of subtitles, I obtain the following average number of deletions/substitutions by episode (included punctuation issues, responsible for most of the differences):

  *Breaking Bad*
  ```
  Season 1: 41.29 del (avg.); 16.71 sub (avg.)
  Season 2: 50.92 del (avg.); 27.00 sub (avg.)                                                             
  Season 3: 68.69 del (avg.); 11.08 sub (avg.)                                                                                                                                                       
  Season 4: 105.46 del (avg.); 40.08 sub (avg.)
  Season 5: 73.94 del (avg.); 32.00 sub (avg.)
  ```
  *Game of Thrones*
  ```
  Season 1: 2.60 del (avg.); 13.90 sub (avg.)
  Season 2: 5.10 del (avg.); 1.00 sub (avg.)
  Season 3: 27.10 del (avg.); 4.00 sub (avg.)
  Season 4: 49.70 del (avg.); 2.50 sub (avg.)
  Season 5: 28.80 del (avg.); 6.00 sub (avg.)
  Season 6: 17.80 del (avg.); 2.10 sub (avg.)
  Season 7: 2.57 del (avg.); 0.57 sub (avg.)
  ```
  *House of Cards*
  ```
  Season 1: 11.00 del (avg.); 1.62 sub (avg.)
  Season 2: 13.00 del (avg.); 2.08 sub (avg.)
  ```
## Additional files

In addition, the repository also contains :

- The script (*"encrypt_text.py"*) that we used to encrypt the copyrighted content of the *Serial Speakers* dataset.

- Various *R* scripts (*"sna"* directory), that we used to perform statistical testing of some of the dataset distributions and to compute topological properties of the social networks of interacting speakers.
