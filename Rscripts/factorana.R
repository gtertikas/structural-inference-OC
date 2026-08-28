# factor analysis on structural inference task, Jan 23, Nadescha Trudel
#
#clear existing data and graphics
rm(list=ls())


# libraries
required_packages = c("ggplot2", "tidyr", "dplyr", 
                      "gghalves", "reshape2","readxl","gridExtra",
                      "lme4", "effsize","emmeans", "car", "lmerTest",
                      "polycor","nFactors","corrplot","GPArotation","psych",
                      "scales","paran","R.matlab","doBy","corrplot")
pacman::p_load(char = required_packages)
outdir = "/Users/nadeschatrudel/Dropbox/Postdoc_UCL/02_project/Matlab/analyse_data/Rscripts/FAoutput"
dataFolder = "/Users/nadeschatrudel/Dropbox/Postdoc_UCL/02_project/Matlab/analyse_data/Rscripts/data"

setwd(dataFolder)
# __________________________________________________________________________
# 0.load questionnaire
# __________________________________________________________________________

qnames = c('OCIR','LSAS_fear','LSAS_avoid','AMI','BIS','DASS','SSMS','RSS')
qnr <-  c(18, 24 ,24, 18 ,30, 42, 43 ,10)

# study 1:
# data <- read.csv("behStudy_questdat.csv")

# study 2:
data <- read.csv("behStudy_questdat_new.csv")
newname <- list()
for (i in 1:length(qnames)) for (iq in 1:qnr[i])  newname <- append(newname, paste(qnames[[i]], as.character(iq) , sep = ""))
names(data) <- newname

newdata <- data

# __________________________________________________________________________
# subscales
# __________________________________________________________________________
# no subscales: RSS, 

##### AMI subscale:
# behaviour : c(5,9,10,11,12,15)
# social : c(5,9,10,11,12,15)
# emotional : c(5,9,10,11,12,15)

amidat <- newdata %>% dplyr::select(starts_with("AMI"))
newdata <- newdata %>%
  mutate(AMIbeh = apply(amidat[,c(5,9,10,11,12,15)],1,sum),
         AMIsoc= apply(amidat[,c(2,3,4,8,14,17)],1,sum),
         AMIemot= apply(amidat[,c(1,6,7,13,16,18)],1,sum))

##### BIS subscale:
# attention : c(5,9,11,20,28,6,24,26)
# motor : c(2,3,4,17,19,22,25,16,21,23,30)
# non-planning : c(10,15,18,27,29,1,7,8,12,13,14

bisdat <- newdata %>% dplyr::select(starts_with("BIS"))
newdata <- newdata %>%
  mutate(BISatt = apply(bisdat[,c(5,9,11,20,24,28,6,26)],1,sum),
         BISmot= apply(bisdat[,c(2,3,4,17,19,22,25,16,21,23,30)],1,sum),
         BISnonpl= apply(bisdat[,c(10,15,18,27,29,1,7,8,12,13,14)],1,sum))

##### SSMS subscale:
# unusual experience: c(1:12)
# cog disorganisation: c(13:23)
# introvertive anhedonia: c(24:34)
# impulsive nonconfirmity: c(35:45)
ssmsdat <- newdata %>% dplyr::select(starts_with("SSMS"))
newdata <- newdata %>%
  mutate(SSMSunuExp = apply(ssmsdat[,c(1:12)],1,sum),
         SSMScogDis= apply(ssmsdat[,c(13:23)],1,sum),
         SSMSinAnh= apply(ssmsdat[,c(24:33)],1,sum),
         SSMSimNC= apply(ssmsdat[,c(34:43)],1,sum))

##### OCIR subscales
# 

ocirdat <- newdata %>% dplyr::select(starts_with("OCIR"))
newdata <- newdata %>%
  mutate(OCIRwash = apply(ocirdat[,c(5,11,17)],1,sum),
         OCIRobs = apply(ocirdat[,c(6,12,18)],1,sum),
         OCIRhoar = apply(ocirdat[,c(1,7,13)],1,sum),
         OCIRord = apply(ocirdat[,c(3,9,15)],1,sum),
         OCIRcmp = apply(ocirdat[,c(2,8,14)],1,sum),
         OCIRneut = apply(ocirdat[,c(4,10,16)],1,sum))

##### DASS subscales
# depression, anxiety, stress

dassdat <- newdata %>% dplyr::select(starts_with("DASS"))
newdata <- newdata %>%
  mutate(DASSdep = apply(dassdat[,c(3, 5, 10, 13, 16, 17, 21, 24, 26, 31, 34, 37, 38, 42)],1,sum),
         DASSanx = apply(dassdat[,c(2, 4, 7, 9, 15, 19, 20, 23, 25, 28, 30, 36, 40, 41)],1,sum),
         DASSstress = apply(dassdat[,c(1, 6, 8, 11, 12, 14, 18, 22, 27, 29, 32, 33, 35, 39)],1,sum))
      

##### LSAS subscales
# fear
lsasdat <- newdata %>% dplyr::select(starts_with("LSAS"))
newdata <- newdata %>%
 mutate(LSASfear = apply(lsasdat[,1:24],1,sum),
        LSASavoid = apply(lsasdat[,25:48],1,sum))



##### RSS
# has no subsbcale, but make it 1 item
rssdata <- newdata %>% dplyr::select(starts_with("RSS"))
newdata <- newdata %>%
  mutate(RSSmean = apply(rssdata,1,sum))


#### merge 
subdata <-  newdata %>% dplyr::select(c("DASSdep", "DASSanx","DASSstress","LSASfear", "LSASavoid",
                                     "OCIRwash","OCIRobs", "OCIRhoar","OCIRord","OCIRcmp", "OCIRneut",
                                   "SSMSunuExp","SSMScogDis", "SSMSinAnh","SSMSimNC",
                                   "BISatt","BISmot", "BISnonpl","AMIbeh","AMIsoc","AMIemot"),
                                   "RSSmean")
                         
                                   
write.csv(subdata,'subdata_Feb23.csv')


# __________________________________________________________________________
# Factor analysis across all individual item loadings
# __________________________________________________________________________


het.mat <- hetcor(data)$cor

fa <- psych::fa(r = het.mat, nfactors=3, n.obs = nrow(data), rotate = "oblimin", fm="ml", scores="regression")
fa.scores <- factor.scores(x=data, f=fa) # individual scores per factor per subject
scores   = data.frame(fa.scores$scores)
weights  = data.frame(fa.scores$weights)
loadings <- data.frame(fa$loadings[])

# save as csv file
write.csv(scores,'fa_scores_Feb23.csv')

# __________________________________________________________________________
# Sceerplot; plot eigenvalues
# __________________________________________________________________________

eigenval = data.frame(fa$e.values)

e1 <- ggplot(eigenval, aes(x = (1:length(data)), y = fa.e.values)) +  geom_bar(stat = "identity", position=position_dodge(),color="black", fill="white") +
  labs(title=" ", x="Factor Number", y = "Eigenvalue") +theme_classic() + theme(axis.title.y = element_text(size = rel(2.5), angle = 90))  + theme(axis.title.y=element_text(margin=margin(0,20,0,0))) +
  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0))) + theme(plot.title = element_text(size = rel(3), angle = 00)) +
  theme(axis.text.x = element_text(angle = 00, size=25)) +theme(axis.text.y = element_text(angle = 00, size=25)) +theme(axis.line.x = element_line(color="black", size = 1),axis.line.y = element_line(color="black", size = 1))
e1

# Get number of factors from CNG test
results = nCng(eigenval[[1]], details=TRUE)



# __________________________________________________________________________
# plot item loadings across factors 
# __________________________________________________________________________

loadingsplot<- 0
loadingsplot = loadings


loadingsplot$qn <- c( rep("OCIR",18) , rep('LSAS_fear',24),  rep("LSAS_avoid",24)  ,rep("AMI",18) ,rep("BIS",30),rep("DASS",42), rep("SSMS",43),rep("RSS",10))
loadingsplot$qn <- factor(loadingsplot$qn, levels = c("OCIR","LSAS_fear","LSAS_avoid","AMI","BIS","DASS","SSMS","RSS"))




loadingsplot<-loadingsplot[order(loadingsplot$qn),]
loadingsplot$x <- rownames(loadingsplot)
loadingsplot$x <- factor(loadingsplot$x, levels = loadingsplot$x)
values=c(rep("#4daf4a",18), rep('#984ea3',24), rep("#377db8",24),rep("#f781bf",18),  rep("#ff7f00",30), rep("#ffff33",42), rep("#e31a1c",43),rep("#B4D4DA",10))

M1loads <-ggplot(loadingsplot[1], aes(x = loadingsplot$x, y = loadingsplot$ML1, group=loadingsplot$qn)) +
  geom_bar(stat = "identity", position=position_dodge(),color="black",fill=values)+
  labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
  theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
  theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
  theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)



M2loads <-ggplot(loadingsplot[2], aes(x = loadingsplot$x, y = loadingsplot$ML2,group=loadingsplot$qn)) + geom_bar(stat = "identity", position=position_dodge(),color="black", fill=values) +
  labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
  theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
  theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
  theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)


M3loads <-ggplot(loadingsplot[3], aes(x = loadingsplot$x, y = loadingsplot$ML3,group=loadingsplot$qn))+ geom_bar(stat = "identity", position=position_dodge(),color="black", fill=values) +
  labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
  theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
  theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
  theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)


#M4loads <-ggplot(loadingsplot[4], aes(x = loadingsplot$x, y = loadingsplot$ML4,group=loadingsplot$qn))+ geom_bar(stat = "identity", position=position_dodge(),color="black", fill=values) +
#labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
# theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
# theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
# theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)


pall <- grid.arrange(M1loads,M2loads,M3loads,ncol=1,nrow=3)
ggsave("Fig_FA3.pdf", plot=pall,path=outdir)








# __________________________________________________________________________
# per subscale
# __________________________________________________________________________


# __________________________________________________________________________
# Factor analysis for subscales
# __________________________________________________________________________

het.mat <- hetcor(subdata)$cor

fa <- psych::fa(r = het.mat, nfactors=3, n.obs = nrow(subdata), rotate = "oblimin", fm="ml", scores="regression")
fa.scores <- factor.scores(x=subdata, f=fa) # individual scores per factor per subject
scores   = data.frame(fa.scores$scores)
weights  = data.frame(fa.scores$weights)
loadings <- data.frame(fa$loadings[])

# save as csv file
write.csv(scores,'fa_subs_scores_Feb23.csv')


# __________________________________________________________________________
# Sceerplot; plot eigenvalues
# __________________________________________________________________________

eigenval = data.frame(fa$e.values)

e1 <- ggplot(eigenval, aes(x = (1:length(subdata)), y = fa.e.values)) +  geom_bar(stat = "identity", position=position_dodge(),color="black", fill="white") +
  labs(title=" ", x="Factor Number", y = "Eigenvalue") +theme_classic() + theme(axis.title.y = element_text(size = rel(2.5), angle = 90))  + theme(axis.title.y=element_text(margin=margin(0,20,0,0))) +
  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0))) + theme(plot.title = element_text(size = rel(3), angle = 00)) +
  theme(axis.text.x = element_text(angle = 00, size=25)) +theme(axis.text.y = element_text(angle = 00, size=25)) +theme(axis.line.x = element_line(color="black", size = 1),axis.line.y = element_line(color="black", size = 1))
e1

# Get number of factors from CNG test
results = nCng(eigenval[[1]], details=TRUE)

# __________________________________________________________________________
# plot item loadings across factors 
# __________________________________________________________________________

loadingsplot<- 0
loadingsplot = loadings

loadingsplot$qn <- c( rep("DASS",3) , rep('LSAS',2),  rep("OCIR",6)  ,rep("SSMS",4) ,rep("BIS",3),rep("AMI",3), rep("RSS",1))
loadingsplot$qn <- factor(loadingsplot$qn, levels = c("DASS","LSAS","OCIR","SSMS","BIS","AMI","RSS"))

loadingsplot<-loadingsplot[order(loadingsplot$qn),]
loadingsplot$x <- rownames(loadingsplot)
loadingsplot$x <- factor(loadingsplot$x, levels = loadingsplot$x)
values=c(rep("#4daf4a",3), rep('#984ea3',2), rep("#377db8",6),rep("#f781bf",4),  rep("#ff7f00",3), rep("#ffff33",3),rep("#B4D4DA",1))

M1loads <-ggplot(loadingsplot[1], aes(x = loadingsplot$x, y = loadingsplot$ML1, group=loadingsplot$qn)) +
  geom_bar(stat = "identity", position=position_dodge(),color="black",fill=values)+
  labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
  theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
  theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
  theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)



M2loads <-ggplot(loadingsplot[2], aes(x = loadingsplot$x, y = loadingsplot$ML2,group=loadingsplot$qn)) + geom_bar(stat = "identity", position=position_dodge(),color="black", fill=values) +
  labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
  theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
  theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
  theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)


M3loads <-ggplot(loadingsplot[3], aes(x = loadingsplot$x, y = loadingsplot$ML3,group=loadingsplot$qn))+ geom_bar(stat = "identity", position=position_dodge(),color="black", fill=values) +
  labs(title=" ", x=" ", y = "Loadings") +  theme_classic() + theme(axis.ticks.x = element_blank() ,axis.text.x = element_blank(),axis.line = element_blank()) + geom_hline(yintercept=0,size=1) +
  theme(axis.ticks.y=element_line(size=(1.5)))+theme(axis.ticks.length=unit(0.2, "cm")) + theme(axis.title.y = element_text(size = rel(2), angle = 90)) +  theme(legend.text = element_text(size = 20))+
  theme(legend.title = element_blank()) +  theme(axis.title.x = element_text(size = rel(3), angle = 00)) + theme(axis.title.x=element_text(margin=margin(20,0,0,0)))  + theme(plot.title = element_text(size = rel(2), angle = 00)) +
  theme(axis.text.y = element_text(angle = 00, size=20)) + scale_x_discrete(expand = c(0,0.5)) + ylim(-1,1)

pall <- grid.arrange(M1loads,M2loads,M3loads,ncol=1,nrow=3)
ggsave("Fig_FA_sub.pdf", plot=pall,path=outdir)
