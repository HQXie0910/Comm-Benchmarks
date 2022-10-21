## Huffman Coding

+ Huffman encoder

 ```shell
python huffman_coding.py --encoding \
--data-dir=PATH_TO_LOAD_SOURCE_DATA
 ```

+ Huffman decoder

```shell
python huffman_coding.py --decoding \
--decoded-text=PATH_TO_LOAD_RECEIVED_BITS \
--output-dir=PATH_TO_STORE_RECOVERED_SOURCE
```

## UTF-8 Coding

+ UTF-8 encoder

```shell
python utf_coding.py --encoding \
--data-dir=PATH_TO_LOAD_SOURCE_DATA
```

+ UTF-8 decoder

```shell
python utf_coding.py --decoding \
--decoded-text=PATH_TO_LOAD_RECEIVED_BITS \
--output-dir=PATH_TO_STORE_RECOVERED_SOURCE
```

## JPEG Coding

+ JPEG encoder

```shell
matlab jpeg_coding.m
```

+ JPEG decoder

You can employ any read image function to decode JPEG images.

## WEBP Coding

+ WEBP encoder

```shell
python webp_coding.py --input-path=PATH_TO_LOAD_IMAGE\
--output-path=PATH_TO_STORE_IMAGE
```

+ WEBP decoder

You can employ any read image function to decode JPEG images.
