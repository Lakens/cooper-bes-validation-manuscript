"""
Script to generate data loader for Flickr images in GB.
Author: Ilan Havinga.
Date: February 2023.
"""

import glob
import numpy as np
import pandas as pd
from torch.utils.data.dataset import Dataset
from torchvision import transforms
from PIL import Image, ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True

class FolderDataset(Dataset):
    def __init__(self, files):
        """
        Args:
            files (list): list of file names in dataset
        """

        # Conversion transforms
        self.conversion = transforms.Compose([
            transforms.ToTensor(),
      #      transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])
        
        # read in image files        
        self.files = files
        
        # extract ids 
        self.ids = [i.rsplit('/',1)[1].rsplit('.',1)[0] for i in files]
        
        # Calculate len
        self.data_len = len(files)

    def __getitem__(self, index):
        # Get image file name
        file = self.files[index]
        # Open image
        img = Image.open(file)
        # Ensure that image is in RGB format
        img_as_img = img.convert('RGB')

        # Transform image to tensor
        img_as_tensor = self.conversion(img_as_img)
        
        # Get id
        img_id = self.ids[index]

        return (img_as_tensor, img_id)

    def __len__(self):
        return self.data_len

if __name__ == "__main__":
    # Call dataset
    train_set = GBDataset(files=glob.glob('./data/imgs/train/*'), format_transform=True)
    
    print(train_set[0])
