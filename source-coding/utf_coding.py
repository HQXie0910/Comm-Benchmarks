# !usr/bin/env python
# -*- coding:utf-8 _*-

import json
import argparse
import pickle
from tqdm import tqdm


parser = argparse.ArgumentParser()
parser.add_argument('--encoding', action='store_true', help='enable the encoding')
parser.add_argument('--decoding', action='store_true', help='enable the decoding')
parser.add_argument('--data_dir', default='...', type=str, help='The PATH to LOAD sentences')
parser.add_argument('--decoded_text', default='....', type=str, help='The PATH to LOAD the received bits')
parser.add_argument('--output_dir', default='....', type=str, help='The PATH to store the recovered sentences')


def source_encoding(sentences):
    text_bytes = []
    h_encoding = []
    for line in tqdm(sentences):
        sentence = []
        line1 = line.encode('utf-8')
        for byte in line1:
            sentence.append(byte)
            h_encoding.append(byte)  # one byte equals to eight bits
        text_bytes.append(sentence)

    # record the length bits
    h_bit_length = [len(sentence) for sentence in text_bytes]

    return h_bit_length, h_encoding


def source_decoding(bytes_string, utf_byte_length):
    utf_received = []
    a = 0
    for length in utf_byte_length:
        b = a + length
        utf_received.append(bytes(bytes_string[a:b]))
        a = b

    predicted_sents = []
    for line in tqdm(utf_received):
        try:
            sent = line.decode('utf-8')
            predicted_sents.append(sent)
        except:
            sent = 'Unable to decode'
            predicted_sents.append(sent)

    return predicted_sents

if __name__ == '__main__':
    args = parser.parse_args()
    with open(args.data_dir, 'r') as f:
        seqs = json.load(f)
    words = [word for line in seqs for word in line.split()]
    if args.encoding:
        utf_bit_length, utf_encoding = source_encoding(seqs)
        bit_per_word = len(utf_encoding)*8/len(words)
        print('Bits Per Word: {}'.format(bit_per_word))
        with open('./utf-8/utf_bit_length.pkl', 'wb') as f:
            pickle.dump(utf_bit_length, f)
        with open('./utf-8/utf_encoding.pkl', 'wb') as f:
            pickle.dump(utf_encoding, f)
        # bits convert to array
        file = open('./utf-8/utf_encoded_bytes.txt', 'w')
        for byte in utf_encoding:
            file.write(str(byte))
            file.write('\n')
        file.close()

    if args.decoding:
        with open('./utf-8/utf_bit_length.pkl', 'rb') as f:
            utf_bytes_length = pickle.load(f)
        with open('./utf-8/utf_encoding.pkl', 'rb') as f:
            utf_encoding = pickle.load(f)
        SNR = [-6, -3, 0, 3, 6, 9, 12, 15, 18]
        for snr in tqdm(SNR):
            path = args.decoded_text + '/' + str(snr).zfill(2) + '.txt'  # Load the received bytes
            # received bits
            with open(path) as file:
                byte_string = file.readlines()
            byte_string = [int(bit.strip('\n')) for bit in byte_string]
            predicted_sents = source_decoding(byte_string, utf_bytes_length)
            print('Writing Data')
            output_pickle_file = args.output_dir + '/' + str(snr).zfill(2) + '.pkl'
            with open(output_pickle_file, 'wb') as f:
                pickle.dump(predicted_sents, f)    # Store the recovered sentences
