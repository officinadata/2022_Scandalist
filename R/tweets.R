#install.packages("academictwitteR")
#install.packages("tidyverse")

library(academictwitteR)
library(tidyverse)

dirs <- list.dirs(path = "~/Data", full.names = TRUE, recursive = TRUE)[-1]

for (dir in dirs) {
  name <- basename(dir)
  
  tweets_raw <- bind_tweets(data_path = dir)
  tweets_tidy <- bind_tweets(data_path = dir, output_format = "tidy")
  
  ref_types <- tweets_raw %>% mutate(temp = lapply(referenced_tweets, function(x) x[["type"]])) %>% select(temp)
  ref_ids <- tweets_raw %>% mutate(temp = lapply(referenced_tweets, function(x) x[["id"]])) %>% select(temp)
  
  tweets_join <- tweets_tidy %>% mutate(true_type = as.character(flatten(ref_types)), true_id = as.character(flatten(ref_ids)), reply_count = tweets_raw$public_metrics$reply_count)
  
  write_csv(tweets_join, paste(name, ".csv", sep="") )
}
