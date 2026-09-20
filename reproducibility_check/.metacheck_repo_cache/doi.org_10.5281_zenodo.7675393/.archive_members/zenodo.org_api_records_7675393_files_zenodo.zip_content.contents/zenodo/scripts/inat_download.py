"""
Script to download iNaturalist images.
Author: Ilan Havinga.
Date: Febraury 2023.
"""

# Load libraries

import sys
import os
import glob
import natsort
import time
import numpy as np
import pandas as pd
import re
import urllib.request
import urllib.error
import http
from io import BytesIO

from PIL import Image, ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True

# Register sys args for command line execution

s = sys.argv[1] # flickr url file number to process

# Set directory

proj_dir = "[insert project directory here]"

# General functions

def open_image(entry):
    """function to open image"""
    
    img = [] # empty img list object as default
    
    image_url = entry.iloc[1]  # start with lowest resolution image

    if image_url != image_url:
                
        print("...none available")
        
        image_url = []

    print(f"image found at {image_url}")
    
    if len(image_url) != 0:

        e = None # empty error object
        n = 0  # create request error counter

        while True:

            try:

                response = urllib.request.urlopen(image_url)
                img = Image.open(BytesIO(response.read()))
                img = img.convert('RGB')
                img = [img.resize((400,400))]
                break

            except (urllib.error.ContentTooShortError, ConnectionResetError) as ex:

                print(ex)
                print('error...retrying...')

                n += 1
                if n > 10:  # after ten error messages, move on
                    break

                time.sleep(1)
                continue

            except (urllib.error.HTTPError, http.client.IncompleteRead,
                    urllib.error.URLError) as ex:

                print(ex)
                if str(ex) in ("HTTP Error 403: Forbidden", "HTTP Error 404: Not Found", "HTTP Error 410: Gone"):
                    
                    print('...does not exist...moving on...')
                    e = ex
                    break
                
                else:
                    print('...retrying...')
                    time.sleep(2)
                    continue

    return(img)
        
def next_id(df):
    """function to load index of last downloaded image"""
    
    if 'dl' in df:
        
        df = df.iloc[:,2]
        i = pd.Series.last_valid_index(df) + 1

    else:
        i = 0
    
    return(i)

def main():
    
    image_urls = pd.read_csv(f"{proj_dir}/data/inat/urls/inat_urls_{s}.csv")
    
    image_dir = f"{proj_dir}/data/inat/imgs" # results file id (later split between atts and scenes)
    
    start_i = next_id(image_urls)
    
    for i in range(start_i, len(image_urls)):
        
        print(f"Analysing image {i+1} out of {len(image_urls)}")
       
        image = open_image(image_urls.iloc[i])
        
        if image: # if list is not empty
            print(f"...image exists, downloading...")
            
            image[0].save(f"{image_dir}/{image_urls.iloc[i,0]}.jpg")
            
            image_urls.loc[i, 'dl'] = 'Y'
            image_urls.to_csv(f"{proj_dir}/data/inat/urls/inat_urls_{s}.csv", sep=',', index = False)
        
        else:
            print(f"Image for metadata record {i+1} does not exist, moving on...")
            image_urls.loc[i, 'dl'] = 'N'
            image_urls.to_csv(f"{proj_dir}/data/inat/urls/inat_urls_{s}.csv", sep=',', index = False)

if (__name__ == '__main__'):
    main()
