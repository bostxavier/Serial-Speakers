#############################################################################################
# Defines functions used to log messages.
# 
# Usage:
# # start logging
# start.rec.log(text="mylogfile")
# # log some message
# tlog(<log offset>,"<log msg>")
# # close log file
# end.rec.log()
# 
# 05/2016 Vincent Labatut
#############################################################################################
FOLDER_LOG <- "log"
dir.create(path=FOLDER_LOG, showWarnings=FALSE, recursive=TRUE)

start.time <- Sys.time()
con <- NA




#############################################################################################
# Start recording the logs in a text file.
#############################################################################################
start.rec.log <- function(text=NA)
{	start.time <<- Sys.time()
	
	prefix <- format(start.time,"%Y%m%d_%H%M%S")
	log.file <- file.path(FOLDER_LOG,prefix)
	if(!is.na(text))
		log.file <- paste0(log.file,"_",text)
	log.file <- paste0(log.file,".txt")
	con <<- file(log.file, encoding="UTF8")
	sink(con, append=TRUE, split=TRUE)
}




#############################################################################################
# Stops recording the logs in a text file.
#############################################################################################
end.rec.log <- function()
{	end.time <- Sys.time()
	duration <- difftime(end.time, start.time, units="secs")
	tlog(0, "Total processing time: ", format(.POSIXct(duration,tz="GMT"),"%H:%M:%S"))
	sink()
	close(con)
}




#############################################################################################
# Logs the specified message on screen, adding current date and time, and possibly some
# offset (to represent the hierarchy of function calls).
#
# offset: number of "." used to represent the hierarchical level of the message.
# ...: parameters fetched to the cat function.
#############################################################################################
tlog <- function(offset=NA, ...)
{	prefix <- paste0("[",format(Sys.time(),"%a %d %b %Y %X"),"] ")
	if(!is.na(offset))
	{	if(is.numeric(offset))
		{	os <- paste(rep(".",offset), sep="", collapse="")
			prefix <- paste0(prefix, os)
		}
		else
			prefix <- paste0(prefix, offset)
	}
	cat(prefix, ..., "\n", sep="")
}
