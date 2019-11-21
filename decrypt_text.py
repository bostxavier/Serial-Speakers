#!/usr/bin/env python3

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


def _srt2json(input_file, input_encoding):
    # expand paths
    input_file = os.path.expanduser(input_file)

    # regular expressions
    timestamp_regexp = r'^(\d{2}):(\d{2}):(\d{2})[,.](\d{3}) --> (\d{2}):(\d{2}):(\d{2})[,.](\d{3})$'

    # open input file
    fh = codecs.open(input_file, 'r', encoding=input_encoding)

    # read input file
    subtitles = []
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
                              'text': _pre_processing(text)})

        # augment text
        else:
            if len(text) > 0:
                text += ' '
            text += line
        
    fh.close()
        
    return subtitles


def _remove_spaces(text):
    text = re.sub(r'^ ', '', text)
    text = re.sub(r" '", "'", text)
    text = re.sub(r" n't", "n't", text)
    text = re.sub(r'` ', '`', text)
    text = re.sub(r' (\.|\?|,|:|;|!)', r'\1', text)
    text = re.sub(r'([gG]on|[wW]an) na', r'\1na', text)
    text = re.sub(r'([gG]ot) ta', r'\1ta', text)
    
    return text


def _pre_processing(text):
    text = re.sub(r'</?i>', '', text)
    
    return text
    
def _post_processing(speech_segments):
    for i in range(len(speech_segments)):
        speech_segments[i] = _remove_spaces(speech_segments[i])
        
    return speech_segments


def _retrieve_content(encrypted_tokens, subtitle_tokens):

    # dictionary of hashes
    hash_dict = {}

    # initialize number of deletions / substitutions
    n_del = n_sub = 0
    
    speech_segments = ['' for i in range(len(encrypted_tokens))]
    
    # squeeze first dimension of reference encrypted tokens
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
            h = hashlib.md5()

            # encrypt word type
            h.update(token.lower().encode('utf-8'))
            hash_dict[token] = h.hexdigest()

        # append encryted token
        sub_encrypted_tokens.append(hash_dict[token])

    # match both sequences
    matcher = difflib.SequenceMatcher(None, ref_encrypted_tokens, sub_encrypted_tokens)

    # loop over matching
    for tag, i1, i2, j1, j2 in matcher.get_opcodes():

        if tag == 'equal' or tag == 'replace':
            for i, j in enumerate(range(j1, j2)):
                segment_idx = mapping[i + i1]
                decrypted = subtitle_tokens[j]
                if tag == 'replace':
                    decrypted = '<{}>'.format(decrypted)
                    n_sub += 1
                speech_segments[segment_idx] += ' {}'.format(decrypted)

        elif tag == 'delete':
            for i in range(i1, i2):
                segment_idx = mapping[i]
                speech_segments[segment_idx] += ' <>'
                n_del += 1
                
    # post-process recovered speech segments
    speech_segments = _post_processing(speech_segments)
    
    return speech_segments, n_del, n_sub

    
def decrypt_text(annot_file, subtitles_dir, subtitles_encoding, output_annot_file):
    # starting time
    start_time = time.time()
    
    # expand paths
    annot_file = os.path.expanduser(annot_file)
    subtitles_dir = os.path.expanduser(subtitles_dir)
    output_annot_file = os.path.expanduser(output_annot_file)

    # load annotation file
    annotations = json.load(open(annot_file))

    # loop over seasons
    seasons = annotations['seasons']
    for i, season in enumerate(seasons):

        n_deletions = []
        n_substitutions = []
        
        # loop over episodes
        episodes = season['episodes']
        for j, episode in enumerate(episodes):

            encrypted_tokens = []
            
            # loop over annotated speech segments
            speech_segments = episode['data']['speech_segments']
            for speech_segment in speech_segments:
                encrypted_tokens.append(speech_segment['encrypted_text'])
                
            # retrieve subtitles
            sub_fname_pattern = '*[sS]{}[eE]{}*.srt'.format(str(season['id']).zfill(2),
                                                            str(episode['id']).zfill(2))
            sub_fnames = glob.glob(os.path.join(subtitles_dir, sub_fname_pattern))

            if len(sub_fnames) == 0:
                print('S{}E{}: no subtitle file found in input directory...'.format(str(season['id']).zfill(2), str(episode['id']).zfill(2)))
            else:
                sub_fname = sub_fnames[0]
                subtitles = _srt2json(sub_fname, subtitles_encoding)

                # subtitles tokens lengths
                subtitle_tokens = []

                for subtitle in subtitles:
                    subtitle_tokens += word_tokenize(subtitle['text'])
                
                # retrieve speech segments content
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
