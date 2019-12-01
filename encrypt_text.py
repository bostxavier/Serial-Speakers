#!/usr/bin/python3
# -*- coding: utf-8 -*-

import sys
import argparse
import os
import json
import hashlib

from nltk.tokenize import word_tokenize


def encrypt_text(annot_file, output_file):
    """Encrypts the textual content of the ``Serial Speakers'' dataset
    Args:
    annot_file  (str): input annotation file with plain text
    output_file (str): output annotation file with encrypted text

    Returns:
    None
    """
    # expand input paths
    annot_file = os.path.expanduser(annot_file)
    output_file = os.path.expanduser(output_file)

    # load annotation file
    annotations = json.load(open(annot_file))

    # dictionary of hashes
    hash_dict = {}
    
    # loop over seasons
    seasons = annotations['seasons']
    for i, season in enumerate(seasons):

        # loop over episodes
        episodes = season['episodes']
        for j, episode in enumerate(episodes):

            annotations['seasons'][i]['episodes'][j].pop('path')
            annotations['seasons'][i]['episodes'][j].pop('width')
            annotations['seasons'][i]['episodes'][j].pop('height')
            
            # loop over speech segments
            speech_segments = episode['data']['speech_segments']

            # new list of encrypted speech segments
            new_speech_segments = []
            
            for speech_segment in speech_segments:
                text = speech_segment['text'].lower()
                
                # encrypt words
                encrypted_tokens = []
                words = word_tokenize(text)
                for word in words:

                    # new word type: compute hash
                    if not word in hash_dict:
                        
                        # initialize hash object
                        h = hashlib.sha256()

                        # encrypt word type
                        h.update(word.encode('utf-8'))
                        hash_dict[word] = h.hexdigest()[:3]

                    # append encryted word
                    encrypted_tokens.append(hash_dict[word])
                    
                speech_segment['encrypted_text'] = encrypted_tokens
                speech_segment.pop('text', None)
                new_speech_segments.append(speech_segment)

            # update annotation file
            annotations['seasons'][i]['episodes'][j]['data']['speech_segments'] = new_speech_segments

    # write out annotation file with encrypted text
    with open(output_file, 'w') as outfile:
        json.dump(annotations, outfile, indent=2)

    print('# word types: {}'.format(len(hash_dict)))
    print('# hash types: {}'.format(len(set(hash_dict.values()))))
        
def parse_arguments(argv):
    parser = argparse.ArgumentParser()
    parser.add_argument('--annot_file',
                        type=str,
                        help='Annotation file.',
                        required=True)

    parser.add_argument('--output_file',
                        type=str,
                        help='Output file.',
                        required=True)

    return parser.parse_args(argv)

if __name__ == '__main__':
    args = parse_arguments(sys.argv[1:])
    encrypt_text(args.annot_file, args.output_file)
