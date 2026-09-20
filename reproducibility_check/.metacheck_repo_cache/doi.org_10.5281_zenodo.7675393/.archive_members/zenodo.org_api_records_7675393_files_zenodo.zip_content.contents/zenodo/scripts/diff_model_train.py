"""
Script to train species interaction ResNet model.
Author: Ilan Havinga.
Date: February 2023.
Note: this requires the images downloaded into the folders using the flickr_download.py and inat_download.py
scripts to be split into folders named "train", "val" and "test" according to the training labels generated in 
sample_inat_flickr.R.
"""

# import libraries

import sys
import time
import os
import glob
from tqdm import trange, tqdm
import numpy as np
import pandas as pd

import torch
import torch.nn as nn
import torch.nn.functional as F
from torch.utils.data import DataLoader
import torch.optim as optim
import torchvision
from diff_data_loader import DiffDataset
from diff_resnet import ResNet

import warnings
warnings.filterwarnings("ignore", "Corrupt EXIF data", UserWarning)
warnings.filterwarnings("ignore", "Possibly corrupt EXIF data", UserWarning)

b = float(sys.argv[1]) # beta
d = str(sys.argv[2]) # device

os.environ['CUDA_DEVICE_ORDER'] = 'PCI_BUS_ID'
os.environ['CUDA_VISIBLE_DEVICES'] = d

proj_dir =  "[insert project directory here]"

###################################################################################################
# 1. General functions

# softmax
m = nn.Softmax(dim=1)

# function to obtain Flickr iNat misclassification indices
def bs_indices(preds, labs):
    dil_idx = []
    for i, pred in enumerate(preds):
        if pred == 1 and labs[i] == 0:
            dil_idx.append(i)
    return(dil_idx)

# data loading
def load_datasets(split, transform):
    dataset = DiffDataset(f"{proj_dir}/data/labels/{split}_labels.csv", glob.glob(f"{proj_dir}/data/imgs/{split}/*"), format_transform=transform)
    return(dataset)

def get_train_loader(train_set, batch_size):
    train_loader = DataLoader(dataset=train_set, batch_size=batch_size, shuffle=True, num_workers=6)
    return(train_loader)

# save model function
def save_model(net, epoch, optim, ckpt_fname):
    state_dict = net.state_dict()
    for key in state_dict.keys():
        state_dict[key] = state_dict[key].cpu()
    torch.save({
        'epoch': epoch,
        'state_dict': state_dict,
        'optimizer': optim},
        ckpt_fname)

# get learning rate function
def get_lr(optimizer):
    lr = []
    for g in optimizer.param_groups:
        lr.append(g['lr'])
        return lr[0]

# next epoch
def next_epoch(path, beta):
    """function to begin training from last completed epoch, if starting, results dataframe is created"""
    if beta == 1:
        beta = "base"
    else:
        beta = str(beta)[2:]
    if os.path.exists(f'{path}/val_oa_results/oa_val_{beta}_adam.csv'):
        df = pd.read_csv(f'{path}/val_oa_results/oa_val_{beta}_adam.csv')[:,0]
        epoch_start = pd.Series.last_valid_index(df) + 1
        print(f"results file exists, resuming from epoch {epoch_start}")
    else:
        df = pd.DataFrame(columns=['Epoch', 'OA'])
        df.to_csv(f'{path}/val_oa_results/oa_val_{beta}_adam.csv', sep=',', index=False)
        epoch_start = 0
        print(f"results file does not exists, creating and starting from epoch {epoch_start}")
    return(epoch_start)

# 2. train net function

def trainNet(net, batch_size, n_epochs, learning_rate, save_freq, write_path, train_set, val_set, beta, step_lr, device):
    """
    Main training function, with forward and backward pass and loss function, optimiser, batch loader applied.
    """
    # Print all of the hyperparameters of the training iteration:
    print("===== HYPERPARAMETERS =====")
    print("batch_size =", batch_size)
    print("epochs =", n_epochs)
    print("learning_rate =", learning_rate)
    print("step_lr =", step_lr)
    print("beta =", beta)
    print("=" * 30)

    # create results csv, start from last training epoch
    epoch_start = next_epoch(write_path, beta)
    
    if epoch_start != 0: # load weights if resuming
        print(f"...loading model weights from epoch {epoch_start}...")
        if beta != 1:
            net.load_state_dict(torch.load(open(f"{write_path}/weights/diff_model_{str(beta)[2:]}_{epoch_start}.pth", 'rb'))) # load weights
        else:
            net.load_state_dict(torch.load(open(f"{write_path}/weights/diff_model_base_{epoch_start}.pth", 'rb'))) # load weights
        net.to(device) # send to GPU
    else:
        net.to(device)

    # Get training data
    train_loader = get_train_loader(train_set, batch_size)
    n_batches = len(train_loader)

    # Create loss functions
    ce_loss = nn.CrossEntropyLoss()
    bce_loss = nn.BCELoss()

    # create optimizer functions
#    optimizer = optim.Adam(net.parameters(), lr=learning_rate)
    
    optimizer = optim.Adam(
    [
        {"params": list(net.parameters())[:-2], "lr": learning_rate},
        {"params": net.fc3.parameters(), "lr": learning_rate*10},
    ],
    lr=learning_rate,
    )

    # Time for printing
    training_start_time = time.time()

    # Loop for n_epochs
    for epoch in range(epoch_start, n_epochs):

        net.train()
        
        print_every = n_batches // 10
        start_time = time.time()

        tqdm.write("Epoch {}, \t learning rate: {}".format(epoch, get_lr(optimizer)))

        batches = tqdm(enumerate(train_loader),
                       desc='Epoch {}/{}, lr={}'.format(epoch, n_epochs, get_lr(optimizer)),
                       leave=False, ncols=100, total=len(train_loader), mininterval=3)

        # running loss counter
        running_loss = 0.0
        # correct counter for overall accuracy metric
        correct = 0
        
        for i, (inputs, labels) in batches:
            
            # Get inputs
            inputs, labels = inputs, labels.squeeze(dim=1)

            # Send to GPU
            inputs, labels = inputs.to(device), labels.to(device)

            # Set the parameter gradients to zero
            optimizer.zero_grad()

            # Forward pass
            outputs = net(inputs)
            
            # Update overall accuracy
            predictions = m(outputs)
            predictions = torch.max(predictions.data, 1)[1]
            
            correct += (predictions == labels).float().sum()
            
            if beta != 1:
                
                # get the list indices of Flickr iNat misclassifications to dilute with boostrap labels
                dil_idx = labels == 0#bs_indices(predictions, labels)
                
                # one-hot encode labels
                bs_labels = torch.zeros(len(inputs), 2).to(device)
                bs_labels[range(bs_labels.shape[0]), labels]=1
                
                #bootstrap ground truth labels using beta, softmax outputs first
                bs_labels[dil_idx,:] = m(outputs.detach()[dil_idx,:])*(1-beta) + bs_labels[dil_idx,:]*beta # list on two dim?
                
                # apply binary cross-entropy loss
                loss_size = bce_loss(m(outputs), bs_labels)
                
                #backward pass
                loss_size.backward()
            
            else:
                # normal cross-entropy loss if beta == 1
                loss_size = ce_loss(outputs, labels)
                # backward pass
                loss_size.backward()

            optimizer.step()
            
            # running loss
            running_loss += loss_size

            # Print every 10th batch of an epoch
            if (i + 1) % (print_every + 1) == 0:
                tqdm.write("Epoch {}, {:d}% \t Running loss: {:.2f} \t Overall accuracy: {:.2f} \t "
                            "Time taken: {:.2f}s".format(epoch, int(100 * (i + 1) / n_batches),
                                                        running_loss / i,
                                                        100 * correct / (i*batch_size),
                                                        time.time() - start_time))

        # At the end of the epoch, do a pass on the validation set
        
        val_loader = DataLoader(val_set, batch_size=batch_size, shuffle=True, num_workers=6)
        
        batches = tqdm(enumerate(val_loader),desc='Epoch {} validation'.format(epoch),
                       leave=False, ncols=100, total=len(val_set), mininterval=3)

        with torch.no_grad():

            correct = 0

            for _, (inputs, labels) in batches:
                
                # Get inputs
                inputs, labels = inputs, labels.squeeze(dim=1)

                # Format and send to GPU
                inputs, labels = inputs.to(device), labels.to(device)

                # Forward pass
                net.eval()
                outputs = net(inputs)

                # Update overall accuracy
                predictions = m(outputs)
                predictions = torch.max(predictions.data, 1)[1]
                
                correct += (predictions == labels).float().sum()

            accuracy = 100 * correct / len(val_set)
            tqdm.write("Epoch {} validation overall accuracy = {:.2f}".format(epoch, accuracy))
        
            # log to csv
            score_df = pd.DataFrame({'Epoch': [epoch], 'OA': [accuracy.item()]})
            if beta != 1:
                score_df.to_csv(f'{write_path}/val_oa_results/oa_val_{str(beta)[2:]}_adam.csv', sep=',', header=False, index=False, mode='a')
            else:
                score_df.to_csv(f'{write_path}/val_oa_results/oa_val_base_adam.csv', sep=',', header=False, index=False, mode='a')

        if epoch % save_freq == 0:
            tqdm.write("Saving model..")
            if beta != 1:
                torch.save(net.state_dict(), open(f"{write_path}/weights/diff_model_{str(beta)[2:]}_{epoch}.pth", 'wb'), _use_new_zipfile_serialization=False)
            else:
                torch.save(net.state_dict(), open(f"{write_path}/weights/diff_model_base_{epoch}.pth", 'wb'), _use_new_zipfile_serialization=False)

        # step-reduce learning rate
        for g in optimizer.param_groups:
            g['lr'] *= step_lr

    tqdm.write("Training finished, took {:.2f}s".format(time.time() - training_start_time))

# train model

def main():
            
    device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu") # set device to GPU

    CNN = ResNet()

    torch.cuda.empty_cache()

    train_set = load_datasets("train", transform=False)
    val_set = load_datasets("val", transform=False)

    trainNet(net=CNN, batch_size=128, n_epochs=10, learning_rate=1e-05, save_freq=1,
            write_path=f'{proj_dir}/data/models/diff_model/', train_set=train_set, val_set=val_set, beta=b, 
            step_lr=0.5, device=device)

if (__name__ == '__main__'):
    main()
