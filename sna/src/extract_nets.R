#############################################################################################
# Extract character interaction networks from JSON files.
#
# Vincent Labatut 11/2019
#############################################################################################
library("rjson")
library("igraph")
source("src/constants.R")
source("src/logging.R")




#############################################################################################
# start logging
start.rec.log(text="NetExtraction")

				
				
				
#############################################################################################
# setup folders
in.folder <- file.path("in","raw_data")
out.folder <- file.path("out","nets")




#############################################################################################
# loop over all three datasets
for(prefix in SERIES_ACCRONYMS)
{	#prefix <- prefixes[1]
	tlog(0,"-------------------------------")
	tlog(0,"Processing \"",prefix,"\"")
	in.file <- file.path(in.folder,paste0(prefix,".json"))
	
	# read the json file
	data <- fromJSON(file=in.file)
	eps <- ANNOTATED_EPISODES[[prefix]]
	
	# init overall adjacency matrices
	ov.adj.mat.inter <- NA
	ov.adj.mat.dur <- NA
	
	# process each targeted episode
	tlog(0,"Epidodes to process: ",paste(eps,collapse=","))
	for(ep in eps)
	{	#ep <- eps[1]
		season <- as.integer(substr(ep,2,3))
		episode <- as.integer(substr(ep,5,6))
		tlog(2,"Processing Season ",season," Episode ",episode)
		
		# get the episode
		data.season <- data$seasons[[season]]
		tlog(4,"Verification : season=",data.season$id)
		data.episode <- data.season$episodes[[episode]]
		tlog(4,"Verification : episode=",data.episode$id)
		
		# get its scenes
		data.scenes <- data.episode$data$scenes
		tlog(4,"Retrieved ",length(data.scenes)," scenes")
		scene.starts <- sapply(data.scenes, function(data.scene) data.scene$start)
		
		# process the speech segments
		data.segments <- data.episode$data$speech_segments
		tlog(4,"Retrieved ",length(data.segments)," segments")
		interaction.counts <- list()
		interaction.durations <- list()
		s <- 1
		for(data.segment in data.segments)
		{	# data.segment <- data.segments[[45]]
			tlog(6,"Processing segment ",s,"/",length(data.segments))
			s <- s + 1
			
			# identify scene
			#idx.sc <- which.max(scene.starts<=data.segment$start)
			
			# get duration
			start <- data.segment$start
			end <- data.segment$end
			duration <- end - start
			tlog(8,"Duration: ",start,"-",end,"=",duration)
			
			# get speaker
			speaker <- data.segment$speaker
			tlog(8,"Speaker: ",speaker)
			# get interlocutor(s)
			interlocutors <- data.segment$interlocutors
			tlog(8,"Interlocutor(s): ",paste(interlocutors,collapse=","))
			
			# update interaction counts and durations
			ic <- interaction.counts[[speaker]]
			id <- interaction.durations[[speaker]]
			if(is.null(ic) || is.na(ic))
			{	ic <- c()
				id <- c()
			}
			for(interlocutor in interlocutors)
			{	#interlocutor <- interlocutors[1]
				val.ic <- ic[interlocutor]
				val.id <- ic[interlocutor]
				if(is.null(val.ic) || is.na(val.ic))
				{	val.ic <- 0
					val.id <- 0
				}
				val.ic <- val.ic + 1
				val.id <- val.id + duration
				ic[interlocutor] <- val.ic
				id[interlocutor] <- val.id
			}
			interaction.counts[[speaker]] <- ic
			interaction.durations[[speaker]] <- id
		}
		
		# extract unique character names for the episode
		speakers <- names(interaction.counts)
		interlocutors <- unlist(sapply(interaction.counts, function(v) names(v)))
		characters <- sort(unique(c(speakers,interlocutors)))

		# compute adjacency matrices
		adj.mat.inter <- matrix(0, nrow=length(characters), ncol=length(characters))
		rownames(adj.mat.inter) <- characters
		colnames(adj.mat.inter) <- characters
		adj.mat.dur <- matrix(0, nrow=length(characters), ncol=length(characters))
		rownames(adj.mat.dur) <- characters
		colnames(adj.mat.dur) <- characters
		for(i in 1:length(interaction.counts))
		{	c1 <- names(interaction.counts)[i]
			
			# update matrix with count values
			ic <- interaction.counts[[i]]
			for(j in 1:length(ic))
			{	c2 <- names(ic)[j]
				adj.mat.inter[c1,c2] <- ic[j]
			}
			
			# update matrix with duration values
			id <- interaction.durations[[i]]
			for(j in 1:length(id))
			{	c2 <- names(id)[j]
				adj.mat.dur[c1,c2] <- id[j]
			}
		}

		# extract utterance-oriented sequence-based graphs
			# utterance counts as weights
			g.inter <- graph_from_adjacency_matrix(
							adjmatrix=adj.mat.inter, 
							mode="directed",
							weighted=TRUE)
			graph.file <- file.path(out.folder, prefix, paste0(ep,"_counts.graphml"))
			write.graph(g.inter,graph.file,format="graphml")
			# utterance durations as weights
			g.dur <- graph_from_adjacency_matrix(
							adjmatrix=adj.mat.dur, 
							mode="directed",
							weighted=TRUE)
			graph.file <- file.path(out.folder, prefix, paste0(ep,"_durations.graphml"))
			write.graph(g.dur,graph.file,format="graphml")
			
		# add to overall matrix
		if(all(is.na(ov.adj.mat.inter)))
		{	ov.adj.mat.inter <- adj.mat.inter
			ov.adj.mat.dur <- adj.mat.dur
		}
		else
		{	characters <- sort(unique(c(colnames(ov.adj.mat.inter),colnames(adj.mat.inter))))
			tmp.inter <- matrix(0,nrow=length(characters),ncol=length(characters))
			rownames(tmp.inter) <- characters
			colnames(tmp.inter) <- characters
			tmp.dur <- matrix(0,nrow=length(characters),ncol=length(characters))
			rownames(tmp.dur) <- characters
			colnames(tmp.dur) <- characters
			#
			tmp.inter[rownames(ov.adj.mat.inter),colnames(ov.adj.mat.inter)] <- 
					tmp.inter[rownames(ov.adj.mat.inter),colnames(ov.adj.mat.inter)] + ov.adj.mat.inter
			tmp.inter[rownames(adj.mat.inter),colnames(adj.mat.inter)] <- 
					tmp.inter[rownames(adj.mat.inter),colnames(adj.mat.inter)] + adj.mat.inter
			tmp.dur[rownames(ov.adj.mat.dur),colnames(ov.adj.mat.dur)] <- 
					tmp.dur[rownames(ov.adj.mat.dur),colnames(ov.adj.mat.dur)] + ov.adj.mat.dur
			tmp.dur[rownames(adj.mat.dur),colnames(adj.mat.dur)] <- 
					tmp.dur[rownames(adj.mat.dur),colnames(adj.mat.dur)] + adj.mat.dur
			#
			ov.adj.mat.inter <- tmp.inter
			ov.adj.mat.dur <- tmp.dur
		}
	}
	
	# build and write overall graphs
		# utterance counts as weights
		g.inter <- graph_from_adjacency_matrix(
				adjmatrix=ov.adj.mat.inter, 
				mode="directed",
				weighted=TRUE)
		graph.file <- file.path(out.folder, prefix, paste0("overall_counts.graphml"))
		write.graph(g.inter,graph.file,format="graphml")
		# utterance durations as weights
		g.dur <- graph_from_adjacency_matrix(
				adjmatrix=ov.adj.mat.dur, 
				mode="directed",
				weighted=TRUE)
		graph.file <- file.path(out.folder, prefix, paste0("overall_durations.graphml"))
		write.graph(g.dur,graph.file,format="graphml")
}




#############################################################################################
# close the log file
tlog(0,"-------------------------------")
tlog(0,"Done")
end.rec.log()
