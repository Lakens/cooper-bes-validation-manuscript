"""
Diff model for application (note: load trained weights in your application script)
Author: Ilan Havinga
Date: February 2023
"""

# import libraries

import torch.nn as nn
import torch.nn.functional as F
import torchvision

###################################################################################################
# download pre-trained resnet model
resnet = torchvision.models.resnet18(pretrained=True)

# build class module with resnet and custom final layers
class ResNet(nn.Module):
    def __init__(self):
        super(ResNet, self).__init__()

        # defining layers in convnet
        self.resnet = nn.Sequential(*list(resnet.children())[:-2])
        self.conv2d = nn.Conv2d(in_channels=512, out_channels=200, kernel_size=1)
        self.adpool = nn.AdaptiveAvgPool2d(3)
        self.fc1 = nn.Linear(in_features=1800, out_features=600, bias=True)
        self.fc2 = nn.Linear(in_features=600, out_features=200, bias=True)
        self.fc3 = nn.Linear(in_features=200, out_features=2, bias=True)

    def forward(self, x):
        x = self.resnet(x)
        x = self.conv2d(x)
        x = self.adpool(x)
        x = x.view(-1, 1800)
        x = F.relu(self.fc1(x))
        x = F.relu(self.fc2(x))
        x = self.fc3(x)
        return x

###################################################################################################
