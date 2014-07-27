library(qlcRecode)
library(qlcMatrix)
library(SnowballC)
library(igraph)

# Help function for large matrices

doInParts <- function(X, FUN, tol, size) {
	
	FUN <- match.fun(FUN)	
	items <- dim(X)[2]
	ranges <- seq(0, items, size)
	if (max(ranges)!=items) { ranges <- c(ranges,items) }
	chunks <- length(ranges)-1
	
	# prepare partition
	parts <- vector("list",chunks^2)
	dim(parts) <- c(chunks,chunks)
	
	# compute individual parts
	for (i in 1:chunks) {
		for (j in 1:i) {
			tmp <- drop0(
				FUN(	X[,(ranges[j]+1):ranges[j+1], drop = F],
						X[,(ranges[i]+1):ranges[i+1], drop = F]
					), tol = tol)
			parts[j,i][[1]] <- tmp
			parts[i,j][[1]] <- t(tmp)
		}
	}
	
	# bind parts together
	result <- do.call(cBind,
			sapply(1:chunks,function(x){do.call(rBind,parts[,x])})
						)	
	return(result)	
}

# == read data ==

data <- read.table("../data.tsv",sep="\t",header=T,quote="",comment.char="")

# == similarity between form of words ==

words <- tokenize(data[,"WORD"],"../orthography profiles/simplified.prf",graphemes="Graphemes",replacements="SCA")
M <- splitStrings(words, sep = " ")
BW <- (M$BS*1) %*% (M$SW*1)
rm(M,words)

system.time(simW <- doInParts(BW, function(X,Y){cosSparse(X,Y,weight=idf)}, tol = 0.3, size = 10e3))

# == similarity between meanings ==

# quick and dirty removal of punctuation
trans <- stri_extract_words(data[,"TRANSLATION"])

# stemming using SnowballC
trans <- sapply(trans,function(x){wordStem(x,"spanish")})

# type-token matrix of stems
ST <- ttMatrix(unlist(trans))

# token to translation linkage
TT <- sparseMatrix(
			i = rep(1:length(trans),sapply(trans,length)),
			j = 1:length(unlist(trans))
		)
ST <- (ST$M*1) %*% t(TT*1)  

system.time(simT <- drop0(cosSparse(ST,weight="idf"),tol=.3))

# ==========

sim <- simW*simT

# communities
g <- graph.adjacency(sim,mode="undirected",diag=F,weight=T)
clus <- walktrap.community(g)
# system.time(fast <- fastgreedy.community(g))
# system.time(edge <- edge.betweenness.community(g))

tmp <- as(drop0(sim,tol=.4),"nMatrix")*1
g <- graph.adjacency(tmp,mode="undirected",diag=F,weight=NULL)
clus <- clusters(g)
rm(tmp,g)

m <- clus$membership
clusters <- vector(mode="integer",length=length(words))
for (i in c(1:max(m))[table(m)>1]) {
	cl <- m==i
	cut <- cutree(hclust(as.dist(-sim[cl,cl]),method="average"),h= -0.05)
	clusters[cl] <- cut + max(clusters)
}

# == try combining clusters ==

# similarity between clusters

clus <- clusters
clus[clus==0] <- c((max(clusters)+1):(max(clusters)+sum(clusters==0)))
M <- ttMatrix(clus)$M*1
D <- Diagonal(x = 1/rowSums(M))
S <- D %*% M %*% sim %*% t(M) %*% D

distr <- as(xtabs(~data[,"SOURCE"]+clus,sparse=T),"nMatrix")
R <- drop0(1-crossprod(distr))

S <- S*R

#g <- graph.adjacency(S,mode="undirected",diag=F,weight=T)
#clus2 <- walktrap.community(g)
#clusters2 <- drop(clus2$membership %*% M)

clus2 <- cutree(hclust(as.dist(-S),method="average"),h= -0.05)
clusters2 <- drop(clus2 %*% M)

distr2 <- xtabs(~data[,"SOURCE"]+clusters2,sparse=T)

for (i in which(colSums(distr2)==1)) {
	clusters2[clusters2==i] <- 0
}

# ===========


data[,"ETYMONID"] <- clusters2
write.table(data,"../data2.tsv",sep="\t",row.names=F,quote=F)


# ===========
# cl <- walk$membership==15
# tmp <- sim[cl,cl]
# rownames(tmp) <- data[cl,"WORD"]
# colnames(tmp) <- data[cl,"SOURCE"]
# plot(hclust(as.dist(-t(tmp)),method="average"),cex=.7)
# abline(h = -0.05,col="red")
