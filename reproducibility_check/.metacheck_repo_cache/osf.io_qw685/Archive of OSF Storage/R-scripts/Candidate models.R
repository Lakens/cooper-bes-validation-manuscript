
### Candidate Models ###

a1 <- data %>% filter(study_area == "1")
a2 <- data %>% filter(study_area == "2")
a3 <- data %>% filter(study_area == "3")
a4 <- data %>% filter(study_area == "4")
a5 <- data %>% filter(study_area == "5")
a6 <- data %>% filter(study_area == "6")
a7 <- data %>% filter(study_area == "7")
a8 <- data %>% filter(study_area == "8")
a9 <- data %>% filter(study_area == "9")
a10 <- data %>% filter(study_area == "10")
a11 <- data %>% filter(study_area == "11")

## unmarked frame, area 1 ##
a1_int <- a1 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a1_kov <- a1 %>% dplyr::select(ODF,TRI) # covariats  
a1_length <- a1$meters # Segment length  
umf_a1 <- unmarkedFrameDS(y=as.matrix(a1_int), siteCovs=a1_kov, survey="line",dist.breaks=breaks,tlength=a1_length,unitsIn="m")  
summary(umf_a1)

## unmarked frame, area 2 ##
a2_int <- a2 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a2_kov <- a2 %>% dplyr::select(ODF,BDF,LF) # covariats  
a2_length <- a2$meters # Segment length  
umf_a2 <- unmarkedFrameDS(y=as.matrix(a2_int), siteCovs=a2_kov, survey="line",dist.breaks=breaks,tlength=a2_length,unitsIn="m")  
summary(umf_a2)

## unmarked frame, area 3 ##
a3_int <- a3 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a3_kov <- a3 %>% dplyr::select(ODF,OSF) # covariats  
a3_length <- a3$meters # Segment length  
umf_a3 <- unmarkedFrameDS(y=as.matrix(a3_int), siteCovs=a3_kov, survey="line",dist.breaks=breaks,tlength=a3_length,unitsIn="m") 
summary(umf_a3)

## unmarked frame, area 4 ##
a4_int <- a4 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a4_kov <- a4 %>% dplyr::select(ODF,OSF,BSF) # covariats  
a4_length <- a4$meters # Segment length  
umf_a4 <- unmarkedFrameDS(y=as.matrix(a4_int), siteCovs=a4_kov, survey="line",dist.breaks=breaks,tlength=a4_length,unitsIn="m") 
summary(umf_a4)

## unmarked frame, area 4 ##
a5_int <- a5 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a5_kov <- a5 %>% dplyr::select(TRI,ODF) # covariats  
a5_length <- a5$meters # Segment length  
umf_a5 <- unmarkedFrameDS(y=as.matrix(a5_int), siteCovs=a5_kov, survey="line",dist.breaks=breaks,tlength=a5_length,unitsIn="m") 
summary(umf_a5)

## unmarked frame, area 6 ##
a6_int <- a6 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a6_kov <- a6 %>% dplyr::select(OSF,ODF) # covariats  
a6_length <- a6$meters # Segment length  
umf_a6 <- unmarkedFrameDS(y=as.matrix(a6_int), siteCovs=a6_kov, survey="line",dist.breaks=breaks,tlength=a6_length,unitsIn="m")  
summary(umf_a6)

## unmarked frame, area 7 ##
a7_int <- a7 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a7_kov <- a7 %>% dplyr::select(LF,ODF) # covariats  
a7_length <- a7$meters # Segment length  
umf_a7 <- unmarkedFrameDS(y=as.matrix(a7_int), siteCovs=a7_kov, survey="line",dist.breaks=breaks,tlength=a7_length,unitsIn="m")  
summary(umf_a7)

## unmarked frame, area 8 ##
a8_int <- a8 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a8_kov <- a8 %>% dplyr::select(BDF,ODF,LF) # covariats  
a8_length <- a8$meters # Segment length  
umf_a8 <- unmarkedFrameDS(y=as.matrix(a8_int), siteCovs=a8_kov, survey="line",dist.breaks=breaks,tlength=a8_length,unitsIn="m")  
summary(umf_a8)

## unmarked frame, area 9 ##
a9_int <- a9 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a9_kov <- a9 %>% dplyr::select(ODF) # covariats  
a9_length <- a9$meters # Segment length  
umf_a9 <- unmarkedFrameDS(y=as.matrix(a9_int), siteCovs=a9_kov, survey="line",dist.breaks=breaks,tlength=a9_length,unitsIn="m")  
summary(umf_a9)

## unmarked frame, area 10 ##
a10_int <- a10 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a10_kov <- a10 %>% dplyr::select(OSF,ODF, TRI) # covariats  
a10_length <- a10$meters # Segment length  
umf_a10 <- unmarkedFrameDS(y=as.matrix(a10_int), siteCovs=a10_kov, survey="line",dist.breaks=breaks,tlength=a10_length,unitsIn="m")  
summary(umf_a10)

## unmarked frame, area 11 ##
a11_int <- a11 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a11_kov <- a11 %>% dplyr::select(BDF,ODF,LF) # covariats  
a11_length <- a11$meters # Segment length  
umf_a11 <- unmarkedFrameDS(y=as.matrix(a11_int), siteCovs=a11_kov, survey="line",dist.breaks=breaks,tlength=a11_length,unitsIn="m")  
summary(umf_a11)


m1  <- distsamp(~ODF~ODF+poly(TRI,2),umf_a1,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
m2  <- distsamp(~ODF~BDF+LF,umf_a2,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
m3  <- distsamp(~ODF~poly(OSF,2),umf_a3,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
m4  <- distsamp(~ODF~OSF+BSF,umf_a4,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
m5  <- distsamp(~ODF~ODF+poly(TRI,2),umf_a5,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
m6  <- distsamp(~ODF~poly(OSF,2),umf_a6,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq")) 
m7  <- distsamp(~ODF~ODF+LF,umf_a7,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
m8  <- distsamp(~ODF~BDF+LF,umf_a8,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
m9  <- distsamp(~ODF~poly(ODF,2),umf_a9,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  
m10 <- distsamp(~ODF~OSF+poly(TRI,2),umf_a10,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
m11 <- distsamp(~ODF~BDF+LF,umf_a11,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))  

m1
m2
m3
m4  
m5
m6
m7
m8
m9
m10
m11


###############
## Landscape ##
###############

## unmarked frame, area 1 ##
a1_int <- a1 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a1_kov <- a1 %>% dplyr::select(FA,OA) # covariats  
a1_length <- a1$meters # Segment length  
umf_a1 <- unmarkedFrameDS(y=as.matrix(a1_int), siteCovs=a1_kov, survey="line",dist.breaks=breaks,tlength=a1_length,unitsIn="m")  
summary(umf_a1)

## unmarked frame, area 2 ##
a2_int <- a2 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a2_kov <- a2 %>% dplyr::select(FA,OA) # covariats  
a2_length <- a2$meters # Segment length  
umf_a2 <- unmarkedFrameDS(y=as.matrix(a2_int), siteCovs=a2_kov, survey="line",dist.breaks=breaks,tlength=a2_length,unitsIn="m")  
summary(umf_a2)

## unmarked frame, area 3 ##
a3_int <- a3 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a3_kov <- a3 %>% dplyr::select(FA,OA) # covariats  
a3_length <- a3$meters # Segment length  
umf_a3 <- unmarkedFrameDS(y=as.matrix(a3_int), siteCovs=a3_kov, survey="line",dist.breaks=breaks,tlength=a3_length,unitsIn="m") 
summary(umf_a3)

## unmarked frame, area 4 ##
a4_int <- a4 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a4_kov <- a4 %>% dplyr::select(FA,OA) # covariats  
a4_length <- a4$meters # Segment length  
umf_a4 <- unmarkedFrameDS(y=as.matrix(a4_int), siteCovs=a4_kov, survey="line",dist.breaks=breaks,tlength=a4_length,unitsIn="m") 
summary(umf_a4)

## unmarked frame, area 4 ##
a5_int <- a5 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a5_kov <- a5 %>% dplyr::select(FA,OA) # covariats  
a5_length <- a5$meters # Segment length  
umf_a5 <- unmarkedFrameDS(y=as.matrix(a5_int), siteCovs=a5_kov, survey="line",dist.breaks=breaks,tlength=a5_length,unitsIn="m") 
summary(umf_a5)

## unmarked frame, area 6 ##
a6_int <- a6 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a6_kov <- a6 %>% dplyr::select(FA,OA) # covariats  
a6_length <- a6$meters # Segment length  
umf_a6 <- unmarkedFrameDS(y=as.matrix(a6_int), siteCovs=a6_kov, survey="line",dist.breaks=breaks,tlength=a6_length,unitsIn="m")  
summary(umf_a6)

## unmarked frame, area 7 ##
a7_int <- a7 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a7_kov <- a7 %>% dplyr::select(FA,OA) # covariats  
a7_length <- a7$meters # Segment length  
umf_a7 <- unmarkedFrameDS(y=as.matrix(a7_int), siteCovs=a7_kov, survey="line",dist.breaks=breaks,tlength=a7_length,unitsIn="m")  
summary(umf_a7)

## unmarked frame, area 8 ##
a8_int <- a8 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a8_kov <- a8 %>% dplyr::select(FA,OA) # covariats  
a8_length <- a8$meters # Segment length  
umf_a8 <- unmarkedFrameDS(y=as.matrix(a8_int), siteCovs=a8_kov, survey="line",dist.breaks=breaks,tlength=a8_length,unitsIn="m")  
summary(umf_a8)

## unmarked frame, area 9 ##
a9_int <- a9 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a9_kov <- a9 %>% dplyr::select(FA,OA) # covariats  
a9_length <- a9$meters # Segment length  
umf_a9 <- unmarkedFrameDS(y=as.matrix(a9_int), siteCovs=a9_kov, survey="line",dist.breaks=breaks,tlength=a9_length,unitsIn="m")  
summary(umf_a9)

## unmarked frame, area 10 ##
a10_int <- a10 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a10_kov <- a10 %>% dplyr::select(FA,OA) # covariats  
a10_length <- a10$meters # Segment length  
umf_a10 <- unmarkedFrameDS(y=as.matrix(a10_int), siteCovs=a10_kov, survey="line",dist.breaks=breaks,tlength=a10_length,unitsIn="m")  
summary(umf_a10)

## unmarked frame, area 11 ##
a11_int <- a11 %>% dplyr::select(N1,N2,N3,N4,N5,N6,N7,N8,N9,N10) # intervals 
a11_kov <- a11 %>% dplyr::select(FA,OA) # covariats  
a11_length <- a11$meters # Segment length  
umf_a11 <- unmarkedFrameDS(y=as.matrix(a11_int), siteCovs=a11_kov, survey="line",dist.breaks=breaks,tlength=a11_length,unitsIn="m")  
summary(umf_a11)


LS[[8]]


l1  <- distsamp(~FA~poly(FA,2),umf_a1,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
l2  <- distsamp(~FA~poly(FA,2),umf_a2,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
l3  <- distsamp(~FA~poly(FA,2),umf_a3,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))

l4 <- distsamp(~FA~poly(OA,2),umf_a4,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
l5 <- distsamp(~FA~poly(OA,2),umf_a5,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))

l6 <- distsamp(~FA~poly(FA,2),umf_a6,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))

l7 <- distsamp(~FA~OA,umf_a7,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
l8 <- distsamp(~FA~OA,umf_a8,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))

l9 <- distsamp(~FA~poly(OA,2),umf_a9,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))
l10 <- distsamp(~FA~poly(OA,2),umf_a10,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))

l11 <- distsamp(~FA~poly(OA,2),umf_a11,keyfun = c("halfnorm"),output = "dens",unitsOut = c("kmsq"))

l1
l2
l3
l4
l5
l6
l7
l8
l9
l10
l11

