"""
Script to generate species classification predictions on iNaturalist images in GB.
Author: Ilan Havinga.
Date: February 2023.
Note: this script requires downloading 
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
import urllib
import http
from io import BytesIO


import torch
from torch.autograd import Variable as V
import torchvision.models as models
from torchvision import transforms as trn
import torch.nn as nn
from torch.nn import functional as F
from torchvision import transforms
from inception import inception_v3

from PIL import Image, ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True

s = sys.argv[1] # image file number range start to process

# set gpu

os.environ['CUDA_DEVICE_ORDER'] = 'PCI_BUS_ID'
os.environ['CUDA_VISIBLE_DEVICES'] = str(sys.argv[2]) # option to select gpu device if multiple devices


proj_dir =  "[insert project directory here]"

# softmax
m = nn.Softmax(dim=1)

# General functions

def save_inat_results(image_id, species_df, softmax_df, file_n):
    """function to save species scores"""
    
    if os.path.exists(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_preds_{file_n}.csv'):
        species_df.to_csv(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_preds_{file_n}.csv', sep=',', header=False, index=False, mode='a')
            
    else:
        species_df.to_csv(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_preds_{file_n}.csv', sep=',', index=False)
        
    if os.path.exists(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_sm_{file_n}.csv'):
        softmax_df.to_csv(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_sm_{file_n}.csv', sep=',', header=False, index=False, mode='a')
            
    else:
        softmax_df.to_csv(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_sm_{file_n}.csv', sep=',', index=False)

def bio_prediction(image_id, img, net, device, file_n):
    """function to generate SoN ResNet scores"""

    img_tensor = transforms.ToTensor()(img).unsqueeze(0) # transform to tensor, add a batch dimension
    img_tensor = img_tensor.to(device) # send to GPU

    with torch.no_grad():
        net.eval()
        pred = net(img_tensor)
        pred = m(pred)
        pred = pred.sort(descending=True)
        
        species = [species[0:30].tolist() for species in pred[1]]
        species_df = pd.DataFrame(species)
        species_df.insert(0, "id", image_id)
        
        sm  = [sm[0:30].tolist() for sm in pred[0]]
        sm_df = pd.DataFrame(sm)
        sm_df.insert(0, "id", image_id)
    
    save_inat_results(image_id, species_df, sm_df, file_n)


def open_image(entry):
    """function to open image"""
    
    img = [] # empty img list object as default
    
    image_url = entry.iloc[0,1]  # start with lowest resolution image
    
    if type(image_url) != float: # to catch "nan"

        e = None # empty error object
        n = 0  # create request error counter

        while True:

            try:

                response = urllib.request.urlopen(image_url)
                img = Image.open(BytesIO(response.read()))
                img = img.convert('RGB')
                img = [img.resize((250,250))]
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
                if str(ex) in ('HTTP Error 404: Not Found", "HTTP Error 410: Gone'):
                    
                    print('...does not exist...moving on...')
                    e = ex
                    break
                
                else:
                    print('...retrying...')
                    time.sleep(2)
                    continue

    return(img)

def image_analysis(image_id, file, net, device, file_n):
    """function to predict scenes, attributes and scenicness in outdoor images"""

    if image_id is not None: # reduce dataframe to begin after the last examined image if results file already exists
        img_idx = file.index[file['id'] == image_id][-1] + 1 # -1 to deal with duplicate image error
        file = file.iloc[img_idx:]

    for idx in range(0, len(file)):
        
        print(f"Examining image {idx+1} out of remaining {len(file)} in file {file_n}...")
        image_id = file.iloc[idx,0]
        
        print(f"...retrieving image...")
        image = open_image(file.loc[file.id == image_id])
        
        if image: # if list is not empty
            bio_prediction(image_id, image[0], net, device, file_n)
        
        else:
            print(f"Image for metadata record {idx+1} does not exist, moving on...")
        
def last_id(file_n):
    """function to load latest model results if file already exists"""

    if os.path.isfile(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_preds_{file_n}.csv') == False: # use attributes file as id check
        print("Image classification file does not exist...")

        img_id = None # mark image id as None if results file does not exist

    else:
        print("Image classification file exists...returning image id")
        line = 0
        for chunk in pd.read_csv(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_preds_{file_n}.csv', chunksize=10000, usecols=['id']): # chunksize for loop to deal with size
            line += chunk.shape[0]

        img_id = pd.read_csv(f'{proj_dir}/data/inat/gb/inat_obs_preds/gb_obs_preds_{file_n}.csv', skiprows = line-1).iloc[-1,0]

    return(img_id)

def main():
    
    file = natsort.natsorted(glob.glob(f"{proj_dir}/data/inat/gb/obs_urls/*.csv"))[int(s)] # generate using obs_gb metadata file
    
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu") # set device to GPU

    torch.cuda.empty_cache()
        
    net = inception_v3(pretrained=True)
    net.fc = nn.Linear(2048, 8142)
    net.aux_logits = False
    #model = torch.nn.DataParallel(model).cuda()
    net = net.cuda()
    net.load_state_dict(torch.load(f"{proj_dir}/data/models/inat_2018/iNat_2018_InceptionV3.pth.tar")['state_dict']) # load weights
    net.to(device) # send to GPU
    
    file_n = re.search(r'([^\/]+$)', file).group(0) # search for everything after last forward slash
    file_n = re.search(r'\d+', file_n).group(0) # extract digits to return cell id
    
    file = pd.read_csv(file)

    img_id = last_id(file_n)  # load last image id if file exists already

    print(f"Analysing outdoor images in file {file_n}")

    image_analysis(img_id, file, net, device, file_n)
        

if (__name__ == '__main__'):
    main()
