library(qlcRecode)

convert <- function(source) {
	
	datafile <- paste("../sources/", source, ".csv", sep = "")
	opfile <- paste("../orthography profiles/", source, ".prf", sep = "")
	
	data <- read.table(datafile, header = TRUE, sep = "\t", quote = "", comment.char = "@")

	WORD <- as.character(levels(data[,"HEAD"]))
	TRANSLATION <- sapply(levels(data[,"HEAD"]),function(x) {
		paste(unique(data[data[,"HEAD"]==x, "TRANSLATION"]),collapse = "; ")
	})

	PAGE <- sapply(levels(data[,"HEAD"]),function(x) {
		paste(
			gsub(source, "", unique(data[data[,"HEAD"]==x, "QLCID"]))
				, collapse = "; ")
	})

	WORD <- stri_trans_nfc(WORD)
	TRANSLATION <- stri_trans_nfc(TRANSLATION)
	ALIGNMENT <- tokenize(WORD, opfile, graphemes = "Graphemes", sep = " ")

	n <- length(WORD)
	SOURCE <- rep(source, times = n)
	ETYMONID <- rep(NA, times = n)
	LANGUAGE <- rep(as.character(data[1,"HEAD_DOCULECT"]), times = n)
	
	result <- cbind(LANGUAGE,SOURCE,PAGE,WORD,ETYMONID,ALIGNMENT,TRANSLATION)
	rownames(result) <- NULL
	return(result)
}

# =============

files <- gsub(".csv","",list.files("../sources"))
all <- sapply(files,convert)
joined <- do.call(rbind, all)
ID <- 1:dim(joined)[1]
joined <- cbind(ID,joined)

# write.table(joined,"../data.tsv",sep="\t",row.names=F,quote=F)