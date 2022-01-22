"""
This script merges all *.scr files into one composite binary

Copyright (c) 2021 Dmitry Pakhomenko.
dmitryp@magictale.com
http://magictale.com
 
This code is in the public domain.

Example usage:

.. code-block:: python

    merge_scr_files.py
"""
import argparse
import glob
import shutil

def main(options):
    """
    Main function
    """
    with open(options.destination, 'wb') as outfile:
        for filename in glob.glob(options.source + '/*.scr'):
            print("Merging %s" % filename)
            with open(filename, 'rb') as readfile:
                shutil.copyfileobj(readfile, outfile)

if __name__ == '__main__':
    # pylint: disable=invalid-name
    parser = argparse.ArgumentParser(description='Merges all *.scr files into one composite binary')
    parser.add_argument('--source', default='../Screenshots', help='Folder with *.scr files')
    parser.add_argument('--destination', default='../SDK/hdmi_out_demo/bootimage/screenshots.bin', help='Destination folder')
    
    main(parser.parse_args())
