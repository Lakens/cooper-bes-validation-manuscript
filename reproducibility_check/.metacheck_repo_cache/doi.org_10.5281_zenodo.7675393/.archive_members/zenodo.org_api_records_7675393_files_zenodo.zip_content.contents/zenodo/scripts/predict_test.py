"""
Script to generate predictions on test dataset.
Author: Ilan Havinga.
Date: February 2023.
"""

# import libraries

import sys
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
os.environ['CUDA_VISIBLE_DEVICES'] = '2'

b = sys.argv[1] # beta model
e = sys.argv[2] # epoch weights to load

proj_dir =  "[insert project directory here]"

###################################################################################################
# 1. General functions

# softmax
m = nn.Softmax(dim=1)

def main():
        
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu") # set device to GPU

    torch.cuda.empty_cache()
        
    net = ResNet()
    net.load_state_dict(torch.load(open(f"{proj_dir}/data/models/diff_model/weights/diff_model_{str(b)}_{str(e)}.pth", 'rb')))
    net.to(device) # send to GPU
    net.eval()
    
    image_set = FolderDataset(glob.glob(f"{proj_dir}/data/imgs/test/*"))
    image_loader = DataLoader(image_set, batch_size=256, shuffle=True, num_workers=6)

    batches = tqdm(enumerate(image_loader), desc=f'Test', leave=False, ncols=100, total=len(image_loader), mininterval=3)
    
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
            
            if os.path.exists(f'{proj_dir}/data/models/diff_model/preds/test_preds_{str(b)}.csv'):
                results_df.to_csv(f'{proj_dir}/data/models/diff_model/preds/test_preds_{str(b)}.csv', sep=',', header=False, index=False, mode='a')
            
            else:
                results_df.to_csv(f'{proj_dir}/data/models/diff_model/preds/test_preds_{str(b)}.csv', sep=',', index=False)
    
if (__name__ == '__main__'):
    main()
