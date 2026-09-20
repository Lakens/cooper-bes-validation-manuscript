"""
Script to generate species classification predictions on Flickr images in GB.
Author: Ilan Havinga.
Date: February 2023.
Note: this script requires downloading 
"""

# import libraries

import time
import os
import glob
from tqdm import trange, tqdm
import pandas as pd
import numpy as np

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from data_loader import FolderDataset
from inception import inception_v3

import warnings
warnings.filterwarnings("ignore", "Corrupt EXIF data", UserWarning)
warnings.filterwarnings("ignore", "Possibly corrupt EXIF data", UserWarning)

os.environ['CUDA_DEVICE_ORDER'] = 'PCI_BUS_ID'
os.environ['CUDA_VISIBLE_DEVICES'] = '4'

proj_dir =  "[insert project directory here]"

###################################################################################################
# 1. General functions

# softmax
m = nn.Softmax(dim=1)

# data loading
def load_datasets(folder):
    dataset = FolderDataset(glob.glob(f"{proj_dir}/data/flickr/gb/imgs/*"))
    return(dataset)

def main():
        
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu") # set device to GPU

    torch.cuda.empty_cache()
        
    net = inception_v3(pretrained=True)
    net.fc = nn.Linear(2048, 8142)
    net.aux_logits = False
    #model = torch.nn.DataParallel(model).cuda()
    net = net.cuda()
      net.load_state_dict(torch.load(f"{proj_dir}/data/models/inat_2018/iNat_2018_InceptionV3.pth.tar")['state_dict']) # load weights
    net.to(device) # send to GPU
    
    for i in range(1,15): # note, imgs for gb were split between 15 folders
        
        print(f"Predicting on Flickr images in folder{i}")
        
        image_set = load_datasets(f"/{i}")
        image_loader = DataLoader(image_set, batch_size=256, shuffle=True, num_workers=6)
    
        batches = tqdm(enumerate(image_loader), desc=f'Folder {i}', leave=False, ncols=100, total=len(image_loader), mininterval=3)
        
        with torch.no_grad():

            for _, (inputs, ids) in batches:
                
                # send to GPU
                inputs = inputs.to(device)

                with torch.no_grad():
                    net.eval()
                    preds = net(inputs)
                    preds = m(preds)
                    preds = preds.sort(descending=True)
                
                etrpy = [-np.sum(sm*np.log2(sm)) for sm in preds[0].cpu().detach().numpy()]
                
                species = [species[0:30].tolist() for species in preds[1]]
                species_df = pd.DataFrame(species)
                species_df.insert(0, "id", ids)
                species_df.insert(1, "entropy", etrpy)
                
                if os.path.exists(f'{proj_dir}/data/flickr/gb/preds/inat_2018/gb_species_preds_{i}.csv'):
                    species_df.to_csv(f'{proj_dir}/data/flickr/gb/preds/inat_2018/gb_species_preds_{i}.csv', sep=',', header=False, index=False, mode='a')
                
                else:
                    species_df.to_csv(f'{proj_dir}/data/flickr/gb/preds/inat_2018/b_species_preds_{i}.csv', sep=',', index=False)
                
            
if (__name__ == '__main__'):
    main()
