#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import argparse
import os
import json
import glob
import codecs
import re
import hashlib
import difflib
import numpy as np
import time

from nltk.tokenize import word_tokenize


def _pre_process_subtitles(text):
    """Removes subtitles metadata
    Args:
    text (str): subtitle text

    Returns:
    text (str): same text, without formatting tags and content in parentheses
    """
    # formatting tags
    text = re.sub(r'</?i>', '', text)

    # speaker mentions
    text = re.sub(r'\(.+?\)', '', text)

    # speaker turns
    text = re.sub(r'^-', '', text)
    
    return text


def _srt2list(input_file, input_encoding):
    """Converts .srt subtitle file to list
    Args:
    input_file     (str):  subtitle file in .srt format
    input_encoding (str):  encoding of the input subtitle file

    Returns:
    subtitles      (list): list of subtitles as dictionaries
    """
    
    # expand paths
    input_file = os.path.expanduser(input_file)

    # regular expression to capture subtitle timecodes
    timestamp_regexp = r'^(\d{2}):(\d{2}):(\d{2})[,.](\d{3}) --> (\d{2}):(\d{2}):(\d{2})[,.](\d{3})$'

    # list of subtitles
    subtitles = []
    
    # open input file
    try:
        fh = codecs.open(input_file, 'r', encoding=input_encoding)

        # read input file
        
        text = ''
        start = end = -1
        while True:
            # read line
            line = fh.readline()

            # exit if empty line
            if not line:
                break

            # remove newline
            line = line.replace('\r', '')
            line = line.replace('\n', '')

            matches = re.findall(timestamp_regexp, line)

            # new subtitle
            if len(matches) > 0:
                start = int(matches[0][0]) * 3600 + int(matches[0][1]) * 60 + int(matches[0][2]) + int(matches[0][3]) / 1000
                end = int(matches[0][4]) * 3600 + int(matches[0][5]) * 60 + int(matches[0][6]) + int(matches[0][7]) / 1000
                text = ''

            # end of subtitle
            elif line == '':
                subtitles.append({'start': start,
                                  'end': end,
                                  'text': _pre_process_subtitles(text)})

            # augment text
            else:
                if len(text) > 0:
                    text += ' '
                text += line
            
        fh.close()

    except UnicodeDecodeError:
        print('\"{}\": subtitle file encoding is not unicode.'.format(os.path.basename(input_file)))
        print('First convert to unicode or use the "--subtitles_encoding" parameter.')
        
    return subtitles


def _remove_spaces(text):
    """Removes extra spaces from input text
    Args:
    text (str): input text

    Returns:
    text (str): text with extra spaces removed
    """
    text = re.sub(r'^ ', '', text)
    text = re.sub(r" '", "'", text)
    text = re.sub(r" n't", "n't", text)
    text = re.sub(r'` ', '`', text)
    text = re.sub(r' (\.|\?|,|:|;|!)', r'\1', text)
    text = re.sub(r'([gG]on|[wW]an) na', r'\1na', text)
    text = re.sub(r'([gG]ot) ta', r'\1ta', text)
    
    return text


def _post_processing(speech_segments):
    """Post-processes speech segments once recovered
    Args:
    speech_segments (list): speech turns

    Returns:
    speech_segments  (list): post-processed speech turns
    """
    for i in range(len(speech_segments)):
        speech_segments[i] = _remove_spaces(speech_segments[i])
        
    return speech_segments


def _retrieve_content(encrypted_tokens, subtitle_tokens):
    """Recovers textual content of speech turns from subtitles
    Args:
    encrypted_tokens (list): sequence of encrypted tokens (speech turns)
    subtitle_tokens  (list): sequence of encrypted tokens with corresponding subitle words

    Returns:
    speech_segments  (list): speech turns with plain text
    n_del            (int) :  # of deletions
    n_sub            (int) :  # of substitutions
    """
    
    # dictionary of hashes
    hash_dict = {}

    # initialize number of deletions / substitutions
    n_del = n_sub = 0
    
    speech_segments = ['' for i in range(len(encrypted_tokens))]
    
    # flatten reference encrypted tokens
    ref_encrypted_tokens = []
    mapping = []
    
    for i, tokens in enumerate(encrypted_tokens):
        ref_encrypted_tokens += tokens
        mapping += [i for j in range(len(tokens))]

    # encrypt subtitle tokens
    sub_encrypted_tokens = []
    for token in subtitle_tokens:

        # new word type: compute hash
        if not token in hash_dict:
            # initialize hash object
            h = hashlib.sha256()

            # encrypt word type
            h.update(token.lower().encode('utf-8'))
            hash_dict[token] = h.hexdigest()[:3]

        # append encryted token
        sub_encrypted_tokens.append(hash_dict[token])

    # match both sequences
    matcher = difflib.SequenceMatcher(None, ref_encrypted_tokens, sub_encrypted_tokens)

    # loop over matching
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():
        len_ref = i2 - i1
        len_sub = j2 - j1

        if tag == 'equal' or tag == 'replace':
            for i in range(len_ref):
                segment_idx = mapping[i1+i]

                # substitution
                if i < len_sub:
                    decrypted = subtitle_tokens[j1+i]
                    speech_segments[segment_idx] += ' {}'.format(decrypted)
                    if tag == 'replace':
                        decrypted = '<{}>'.format(decrypted)
                        n_sub += 1
                # deletion
                else:
                    speech_segments[segment_idx] += ' <>'
                    n_del += 1
                    
        elif tag == 'delete':
            for i in range(len_ref):
                segment_idx = mapping[i1+i]
                speech_segments[segment_idx] += ' <>'
                n_del += 1

    # post-process recovered speech segments
    speech_segments = _post_processing(speech_segments)
    
    return speech_segments, n_del, n_sub

    
def decrypt_text(annot_file, subtitles_dir, subtitles_encoding, output_annot_file):
    """Decrypts the textual content of the ``Serial Speakers'' dataset
    Args:
    annot_file         (str): input annotation file with encrypted text
    subtitles_dir      (str): path of the subtitle files
    subtitles_encoding (str): encoding of the subtitle files
    output_annot_file  (str): annotation file with plain text recovered

    Returns:
    None
    """
    # starting time
    start_time = time.time()
    
    # expand input paths
    annot_file = os.path.expanduser(annot_file)
    subtitles_dir = os.path.expanduser(subtitles_dir)
    output_annot_file = os.path.expanduser(output_annot_file)

    # load annotation file
    annotations = json.load(open(annot_file))

    # loop over seasons
    seasons = annotations['seasons']
    for i, season in enumerate(seasons):

        # maintain number of deletions/substitutions for every episode
        n_deletions = []
        n_substitutions = []
        
        # loop over episodes
        episodes = season['episodes']
        for j, episode in enumerate(episodes):

            encrypted_tokens = []
            
            # loop over encrypted speech segments
            speech_segments = episode['data']['speech_segments']
            for speech_segment in speech_segments:
                encrypted_tokens.append(speech_segment['encrypted_text'])
                
            # retrieve subtitles
            seas_id = str(season['id']).zfill(2)
            ep_id = str(episode['id']).zfill(2)
            sub_fname_pattern = '*[sS]{}[eE]{}*.srt'.format(seas_id, ep_id)
            sub_fnames = glob.glob(os.path.join(subtitles_dir, sub_fname_pattern))

            if len(sub_fnames) == 0:
                print('S{}E{}: no subtitle file found in input directory...'.format(seas_id, ep_id))
                print('Subtitle file name in expected to contain the "S{}E{}" (or "s{}E{}") substring.'.format(seas_id, ep_id))
            else:
                sub_fname = sub_fnames[0]
                subtitles = _srt2list(sub_fname, subtitles_encoding)

                # subtitle sequence of tokens
                subtitle_tokens = []

                for subtitle in subtitles:
                    subtitle_tokens += word_tokenize(subtitle['text'])
                
                # recover speech turn text from subtitle tokens
                speech_segments_contents, n_del, n_sub = _retrieve_content(encrypted_tokens, subtitle_tokens)
                n_deletions.append(n_del)
                n_substitutions.append(n_sub)
                
                new_speech_segments = []
                for k, speech_segment in enumerate(speech_segments):
                    speech_segment['text'] = speech_segments_contents[k]
                    speech_segment.pop('encrypted_text', None)
                    new_speech_segments.append(speech_segment)
                
                # update annotation file
                annotations['seasons'][i]['episodes'][j]['data']['speech_segments'] = new_speech_segments

        print('Season {}: {:4.2f} del (avg.); {:4.2f} sub (avg.)'.format(i+1,
                                                                         np.mean(n_deletions),
                                                                         np.mean(n_substitutions)))
        
    print('Text recovered in {:.2f} seconds'.format(time.time() - start_time))
        
    # write out annotation file with encrypted text
    with open(output_annot_file, 'w') as outfile:
        json.dump(annotations, outfile, indent=2)
        
                
def parse_arguments(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--annot_file',
                        type=str,
                        help='Annotation file.',
                        required=True)

    parser.add_argument('--subtitles_dir',
                        type=str,
                        help='Directory containing subtitles.',
                        required=True)

    parser.add_argument('--subtitles_encoding',
                        type=str,
                        help='Subtitles encoding.',
                        default='utf-8')
                                     
    parser.add_argument('--output_annot_file',
                        type=str,
                        help='Output annotation file.',
                        required=True)

    return parser.parse_args(argv)


if __name__ == '__main__':
    args = parse_arguments(sys.argv[1:])
    decrypt_text(args.annot_file, args.subtitles_dir, args.subtitles_encoding, args.output_annot_file)
