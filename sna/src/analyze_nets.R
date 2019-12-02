#############################################################################################
# Extract character interaction networks from JSON files.
#
# Vincent Labatut 11/2019
#############################################################################################
library("rjson")
library("igraph")
library("latex2exp")
source("src/constants.R")
source("src/logging.R")




#############################################################################################
# start logging
start.rec.log(text="NetAnalysis")

				
				
				
#############################################################################################
# setup folders
in.folder <- file.path("out","nets")
out.folder <- file.path("out","plots")




#############################################################################################
# loop over all three datasets
for(prefix in SERIES_ACCRONYMS)
{	#prefix <- prefixes[1]
	tlog(0,"-------------------------------")
	tlog(0,"Processing \"",prefix,"\"")
	
	# process each targeted episode
	eps <- ANNOTATED_EPISODES[[prefix]]
	tlog(0,"Epidodes to process: ",paste(eps,collapse=","))
	for(ep in c(eps,"overall"))
	{	#ep <- eps[1]
		tlog(2,"Processing episode ",ep)
		
		
		# load the graphml files
		graph.file <- file.path(in.folder, prefix, paste0(ep,"_counts.graphml"))
		g.inter <- read.graph(graph.file,format="graphml")
		graph.file <- file.path(in.folder, prefix, paste0(ep,"_durations.graphml"))
		g.dur <- read.graph(graph.file,format="graphml")
		gs <- list(counts=g.inter,durations=g.dur)
		
		# init graph measure table
		tab.graph <- NA
		
		# process both weighting schemes
		for(i in 1:length(gs))
		{	#i <- 1
			graph.name <- names(gs)[i]
			g <- gs[[i]]
			prefix.file <- file.path(out.folder, prefix, paste0(ep,"_",graph.name,"_"))
			
			# init nodal measure table
			tab.nodal <- matrix(nrow=gorder(g),ncol=0)
			rownames(tab.nodal) <- V(g)$name
			# init graph measure column
			col.graph <- c()
			
			# compute degree
				# incoming
				in.deg <- degree(graph=g,mode="in")
				pdf(file=paste0(prefix.file,"degree_in.pdf"))
					plot(sort(in.deg), 1-ecdf(in.deg)(sort(in.deg)), log="xy", col="RED",
							xlab=TeX("Incoming Degree $k_{in}$"), ylab=TeX("$P(k_{in})$"))
				dev.off()
				# outgoing
				out.deg <- degree(graph=g,mode="out")
				pdf(file=paste0(prefix.file,"degree_out.pdf"))
					plot(sort(out.deg), 1-ecdf(out.deg)(sort(out.deg)), log="xy", col="RED",
							xlab=TeX("Outgoing Degree $k_{out}$"), ylab=TeX("$P(k_{out})$"))
				dev.off()
				# total
				all.deg <- degree(graph=g,mode="total")
				pdf(file=paste0(prefix.file,"degree_all.pdf"))
					plot(sort(all.deg), 1-ecdf(all.deg)(sort(all.deg)), log="xy", col="RED",
							xlab=TeX("Total Degree $k$"), ylab=TeX("$P(k)$"))					
				dev.off()
				# in vs. out
				pdf(file=paste0(prefix.file,"degree_out_vs_in.pdf"))
					plot(x=out.deg, y=in.deg, log="xy", col="RED",
							xlab=TeX("Outgoing Degree $k_{out}$"), ylab=TeX("Incoming Degree $k_{in}$"))					
				dev.off()
				# update tables
				tab.nodal <- cbind(tab.nodal,in.deg,out.deg,all.deg)
				colnames(tab.nodal)[(ncol(tab.nodal)-2):ncol(tab.nodal)] <- c("InDegree","OutDegree","AllDegree")
				col.graph <- c(col.graph, mean(in.deg), mean(out.deg), mean(all.deg))
				names(col.graph)[(length(col.graph)-2):length(col.graph)] <- c("AvgInDegree","AvgOutDegree","AvgAllDegree")
			
			# compute strength
				# incoming
				in.str <- strength(graph=g,mode="in")
				pdf(file=paste0(prefix.file,"strength_in.pdf"))
					plot(sort(in.str), 1-ecdf(in.str)(sort(in.str)), log="xy", col="RED", 
							xlab=TeX("Incoming Strength $s_{in}$"), ylab=TeX("$P(s_{in})$"))
				dev.off()
				# outgoing
				out.str <- strength(graph=g,mode="out")
				pdf(file=paste0(prefix.file,"strength_out.pdf"))
					plot(sort(out.str), 1-ecdf(out.str)(sort(out.str)), log="xy", col="RED",
							xlab=TeX("Outgoing Strength $s_{out}$"), ylab=TeX("$P(s_{out})$"))
				dev.off()
				# total
				all.str <- strength(graph=g,mode="total")
				pdf(file=paste0(prefix.file,"strength_all.pdf"))
					plot(sort(all.str), 1-ecdf(all.str)(sort(all.str)), log="xy", col="RED",
							xlab=TeX("Total Strength $s$"), ylab=TeX("$P(s)$"))					
				dev.off()
				# in vs. out
				pdf(file=paste0(prefix.file,"strength_out_vs_in.pdf"))
					plot(x=out.str, y=in.str, log="xy", col="RED",
						xlab=TeX("Outgoing Strength $s_{out}$"), ylab=TeX("Incoming Strength $s_{in}$"))					
				dev.off()
				# update tables
				tab.nodal <- cbind(tab.nodal,in.str,out.str,all.str)
				colnames(tab.nodal)[(ncol(tab.nodal)-2):ncol(tab.nodal)] <- c("InStrength","OutStrength","AllStrength")
				col.graph <- c(col.graph, mean(in.str), mean(out.str), mean(all.str))
				names(col.graph)[(length(col.graph)-2):length(col.graph)] <- c("AvgInStrength","AvgOutStrength","AvgAllStrength")
			
			# degree assortativity
			deg.ass.undir <- assortativity_degree(graph=g, directed=FALSE)
			deg.ass.dir <- assortativity_degree(graph=g, directed=TRUE)
			col.graph <- c(col.graph, deg.ass.undir, deg.ass.dir)
			names(col.graph)[(length(col.graph)-1):length(col.graph)] <- c("UndirectedDegreeAssortativity","DirectedDegreeAssortativity")
			
			# strength assortativity
			str.ass.undir <- assortativity(graph=g, types1=in.str, types2=NULL, directed=FALSE)
			str.ass.dir <- assortativity(graph=g, types1=in.str, types2=out.str, directed=TRUE)
			col.graph <- c(col.graph, str.ass.undir, str.ass.dir)
			names(col.graph)[(length(col.graph)-1):length(col.graph)] <- c("UndirectedStrengthAssortativity","DirectedStrengthAssortativity")
			
			# link weights
			weights <- E(g)$weight
			pdf(file=paste0(prefix.file,"weights.pdf"))
			plot(sort(weights), 1-ecdf(weights)(sort(weights)), log="xy", col="RED", 
					xlab=TeX("Weights $w$"), ylab=TeX("$P(w)$"))
			dev.off()
			# average link weight
			col.graph <- c(col.graph, mean(weights))
			names(col.graph)[length(col.graph)] <- "AvgWeight"
			
			# write nodal measures
			write.csv(tab.nodal, file=paste0(prefix.file,"nodal_meas.csv"))
			
			# update graph table
			if(all(is.na(tab.graph)))
				tab.graph <- as.matrix(col.graph,ncol=1)
			else
				tab.graph <- cbind(tab.graph, col.graph)
			colnames(tab.graph)[i] <- graph.name
		}
		
		# write graph measures
		table.file <- file.path(out.folder, prefix, paste0(ep,"_graph_meas.csv"))
		write.csv(tab.graph, table.file)

		# add to larger graph
		
	}
	
}




#############################################################################################
# close the log file
tlog(0,"-------------------------------")
tlog(0,"Done")
end.rec.log()
