# !usr/bin/env python
# -*- coding:utf-8 _*-

import json
import collections
import argparse
import numpy as np
import pickle
from huffman import codebook as hcode
from tqdm import tqdm

parser = argparse.ArgumentParser()
parser.add_argument('--encoding', action='store_true', help='enable the encoding')
parser.add_argument('--decoding', action='store_true', help='enable the decoding')
parser.add_argument('--data-dir', default='...', type=str, help='The PATH to LOAD sentences')
parser.add_argument('--decoded-text', default='....', type=str, help='The PATH to LOAD the received bits')
parser.add_argument('--output-dir', default='....', type=str, help='The PATH to store the recovered sentences')


class Huffman():
    def __init__(self, data, num_lines_read=50000):
        char_count = collections.Counter()
        print('initializing huffman codebook')
        for line in tqdm(data):
            for char in line:
                char_count.update(char)
        self.huffman_code = hcode(char_count.items())
        self.huffman_decode = dict(zip(self.huffman_code.values(), self.huffman_code.keys()))

    def encode(self, word):
        """ Returns binary string sequence"""
        encoding = ''.join(self.huffman_code.get(x) for x in word)
        return encoding

    def decode(self, binary):
        """ Decode the binary to string """
        decoding = ""
        while binary:
            for k in self.huffman_decode:
                if binary.startswith(k):
                    decoding += self.huffman_decode[k]
                    binary = binary[len(k):]
        return decoding

def source_encoding(sentences):
    # Encoding
    h_encoding = []
    for line in tqdm(sentences):
        for word in line.split():
            h_encoding.append(huffman.encode(word))

    # record the length bits
    h_bit_length = [len(bits) for bits in h_encoding]
    h_bit_length = np.array(h_bit_length)

    return h_bit_length, h_encoding

def source_decoding(args, snr, sentences,
                    huffman_bit_length, huffman_encoding):
    huffman_decoded = []
    print('huffman decoding')
    path = args.data_dir + args.decoded_text + '/' + str(snr).zfill(2) + '-test.txt'
    # received bits
    with open(path) as file:
        bit_string = file.readlines()[0]  # 读取每一行
    print('data loaded')

    huffman_received = []
    a = 0
    for length in huffman_bit_length:
        b = a + length
        huffman_received.append(bit_string[a:b])
        a = b
    #
    logic_huffman = [huffman_received[x] == huffman_encoding[x] for x in range(len(huffman_received))]
    # word_error_rate_huffman = 1 - np.array(logic_huffman).astype(np.int32).sum()/len(huffman_received)
    #
    predicted_words = []
    for x, line in enumerate(huffman_received):
        if not logic_huffman[x]:
            predicted_words.append('<UNK>')
        #  estimated_sentence_huffman.append(line)
        else:
            word = huffman.decode(line)
            predicted_words.append(word)

    j = 0
    predicted_sentences = []
    for line in sentences:
        # combine as a sentence
        a = ' '.join(predicted_words[j: j + len(line.split())])
        predicted_sentences.append(a)
        j += len(line.split())

    print('Writing Data')
    output_pickle_file = args.data_dir + args.output_dir + '/' + 'val_' + str(snr).zfill(2) + '.pkl'
    with open(output_pickle_file, 'wb') as f:
        pickle.dump(predicted_sentences, f)


if __name__ == '__main__':
    args = parser.parse_args()
    with open(args.data_dir, 'r') as f:
        seqs = json.load(f)   # Load your data, in which the data is list consisting of sentences
    huffman = Huffman(data=seqs)  # Initialize the huffman dictionary
    if args.encoding:
        huffman_bit_length, huffman_encoding = source_encoding(seqs)
        with open('./huffman_bit_length.pkl', 'wb') as f:
            pickle.dump(huffman_bit_length, f)
        with open('./huffman_encoding.pkl', 'wb') as f:
            pickle.dump(huffman_encoding, f)
        # bits convert to array
        huffman_bits = [x for bit_string in huffman_encoding for x in bit_string]
        word_per_bit = len(huffman_bits)/len(huffman_bit_length)
        print(word_per_bit)
        file = open('./huffman_encoded_bits.txt', 'w')
        for bit_string in huffman_encoding:
            for x in bit_string:
                file.write(str(x))
                file.write('\n')
        file.close()

    if args.decoding:
        with open('./huffman_bit_length.pkl', 'rb') as f:
            huffman_bit_length = pickle.load(f)
        with open('./huffman_encoding.pkl', 'rb') as f:
            huffman_encoding = pickle.load(f)
        SNR = [18]
        for snr in tqdm(SNR):
            source_decoding(args, snr, seqs, huffman_bit_length, huffman_encoding)
