"""
Script to generate predictions on Flickr images in GB.
Author: Ilan Havinga.
Date: February 2023.
"""

# import libraries

import time
import os
import glob
from tqdm import trange, tqdm
import pandas as pd

import torch
import torch.nn as nn
from torch.utils.data import DataLoader
from data_loader import FolderDataset
from diff_resnet import ResNet

import warnings
warnings.filterwarnings("ignore", "Corrupt EXIF data", UserWarning)
warnings.filterwarnings("ignore", "Possibly corrupt EXIF data", UserWarning)

os.environ['CUDA_DEVICE_ORDER'] = 'PCI_BUS_ID'
os.environ['CUDA_VISIBLE_DEVICES'] = '3'

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
        
    net = ResNet()
    net.load_state_dict(torch.load(open(f"{proj_dir}/data/models/diff_model/weights/diff_model_001_9.pth", 'rb'))) # for example, beta 0.01
    net.to(device) # send to GPU
    net.eval()
    
    for i in range(1,16):
        
        print(f"Predicting on Flickr images in folder{i}")
        
        image_set = load_datasets(f"/{i}")
        image_loader = DataLoader(image_set, batch_size=256, shuffle=True, num_workers=6)
    
        batches = tqdm(enumerate(image_loader), desc=f'Folder {i}', leave=False, ncols=100, total=len(image_loader), mininterval=3)
        
        with torch.no_grad():

            for _, (inputs, ids) in batches:

                # send to GPU
                inputs = inputs.to(device)
                
                # Inference pass
                pred = net(inputs)
                pred = m(pred)
                pred_binary = torch.max(pred.data, 1)[1]
                pred_confidence = torch.max(pred.data, 1)[0]

                results_df = pd.DataFrame({'id':ids, 'pred':pred_binary.tolist(), 'confidence':pred_confidence.tolist()})
                
                if os.path.exists(f'{proj_dir}/data/flickr/gb/preds/diff/beta_01/gb_preds_{i}.csv'): # change to appropriate model folder
                    results_df.to_csv(f'{proj_dir}/data/flickr/gb/preds/diff/beta_01/beta_001/gb_preds_{i}.csv', sep=',', header=False, index=False, mode='a')
                
                else:
                    results_df.to_csv(f'{proj_dir}/data/flickr/gb/preds/diff/beta_01/gb_preds_{i}.csv', sep=',', index=False)
                    

if (__name__ == '__main__'):
    main()
