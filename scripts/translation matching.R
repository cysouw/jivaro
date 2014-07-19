library(qlcRecode)
library(qlcMatrix)
library(SnowballC)
library(igraph)

data <- read.table("../data.tsv",sep="\t",header=T,quote="",comment.char="")

# ==========

trans <- stri_extract_words(data[,"TRANSLATION"])
trans <- sapply(trans,function(x){wordStem(x,"spanish")})
tmp <- ttMatrix(unlist(trans))
tmp2 <- sparseMatrix(
			i = rep(1:length(trans),sapply(trans,length)),
			j = 1:length(unlist(trans))
		)
words <- tmp$rownames
WT <- (tmp$M*1) %*% t(tmp2*1)  

simT <- drop0(cosSparse(WT,weight="idf"),tol=.3)

# ========

words <- tokenize(data[,"WORD"],"../orthography profiles/simplified.prf",graphemes="Graphemes",replacements="Simplified")

simW11 <- drop0(sim.strings(words[1:15000],sep=" "),tol=.3)
simW22 <- drop0(sim.strings(words[15001:30000],sep=" "),tol=.3)
simW33 <- drop0(sim.strings(words[30001:45872],sep=" "),tol=.3)

simW12 <- drop0(sim.strings(words[1:15000],words[15001:30000],sep=" "),tol=.3)
simW13 <- drop0(sim.strings(words[1:15000],words[30001:45872],sep=" "),tol=.3)
simW23 <- drop0(sim.strings(words[15001:30000],words[30001:45872],sep=" "),tol=.3)

simW <- rBind(cBind(simW11,simW12,simW13),cBind(t(simW12),simW22,simW23),cBind(t(simW13),t(simW23),simW33))

rownames(simW) <- colnames(simW) <- NULL
rm(simW11,simW22,simW33,simW12,simW13,simW23)

# ==========

sim <- simW*simT

tmp <- as(drop0(sim,tol=.4),"nMatrix")*1
g <- graph.adjacency(tmp,mode="undirected",diag=F)
clus <- clusters(g)

clusters <- vector(mode="integer",length=length(words))
for (i in c(1:clus$no)[clus$csize>1]) {
	cl <- clus$membership==i
	cut <- cutree(hclust(as.dist(-sim[cl,cl]),method="average"),h= -0.05)
	clusters[cl] <- cut + max(clusters)
}

# ===========

data[,"ETYMONID"] <- clusters
write.table(data,"../data.tsv",sep="\t",row.names=F,quote=F)


# ===========
# cl <- clus$membership==1
# tmp <- sim[cl,cl]
# rownames(tmp) <- data[cl,"WORD"]
# colnames(tmp) <- data[cl,"TRANSLATION"]
# plot(hclust(as.dist(-tmp),method="average"),cex=.7)
# abline(h = -0.05,col="red")
