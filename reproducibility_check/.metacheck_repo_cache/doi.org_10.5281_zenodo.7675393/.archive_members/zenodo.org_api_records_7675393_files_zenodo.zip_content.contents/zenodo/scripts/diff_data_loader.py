"""
Script to generate Diff ResNet data loader.
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

class DiffDataset(Dataset):
    def __init__(self, csv_path, files, format_transform):
        """
        Args:
            csv_path (string): path to csv file containing image labels
            files (list): list of file names in dataset
            format_transform (boolean): whether to apply format transformations e.g. RandomCrop
        """
        # Format transforms
        self.transforms = transforms.Compose([
            transforms.RandomHorizontalFlip()
        ])

        self.format_transform = format_transform

        # Conversion transforms
        self.conversion = transforms.Compose([
            transforms.ToTensor(),
      #      transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
        ])
        
        # read in image files        
        self.files = files
        
        # Read the csv file (id, class)
        self.data_info = pd.read_csv(csv_path)
        
        # extract ids 
        self.ids = [i.rsplit('/',1)[1].rsplit('.',1)[0] for i in files]

        # Load the class labels
 #       self.labels = np.asarray(self.data_info.iloc[:, 1])

        # Calculate len
        self.data_len = len(files)

    def __getitem__(self, index):
        # Get image file name
        file = self.files[index]
        # Open image
        img = Image.open(file)
        # Ensure that image is in RGB format
        img_as_img = img.convert('RGB')

        # Check if format transformation required
        format_transform = self.format_transform

        if format_transform:
            img_as_img = self.transforms(img_as_img)

        # Transform image to tensor and normalise
        img_as_tensor = self.conversion(img_as_img)

        # Get label of the image
        img_label = np.asarray(self.data_info.labels)[self.data_info.ids == self.ids[index]]

        return (img_as_tensor, img_label)

    def __len__(self):
        return self.data_len

if __name__ == "__main__":
    # Call dataset
    train_set = DiffDataset(csv_path='./data/labels/train_labels.csvs', files=glob.glob('./data/imgs/train/*'), format_transform=True)
    
    print(train_set[0])
