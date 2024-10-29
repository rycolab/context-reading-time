# Multilingual Eye-Tracking Corpus (MECO) ID Fix
# A. Opedal, E. Chodroff, R. Cotterell, E. Wilcox
# 29 Oct 2024

library(tidyverse)
path <- "INSERT"

##############################
### LOAD L1 MECO V1.2 DATA ###
##############################
# Load MECO V1.1 or V1.2 L1 joint_data_trimmed dataset
load(paste0(path,"joint_data_trimmed.rda"))

#############################
### FIX L1 MECO V1.2 DATA ###
#############################
# Identify non-unique IDs based on the Trial ID and IA Number columns (trialid, ianum)  
# We are ignoring Sentence Number (sentnum) errors.
non_unique_ids <- joint.data %>% 
  group_by(lang, trialid, ianum) %>%
  summarise(unique_words = length(unique(ia))) %>%
  filter(unique_words > 1)

# English: fix trialid 3 - ianum 149 on: 149 is blank for half of the participants, 
# but even for these participants, sometimes there is collected data (i.e., ia = "" and nrun = 1, not NA)
# the solution below makes 149 a "dead row" and removes it - 
# note this inflates the total ianum for trialid 3 by one
affected_subjs <- subset(joint.data, lang == "en" & trialid == 3 & ianum == 149 & ia == "performance-")$subid
joint.data <- joint.data %>% 
  mutate(ianum = ifelse(lang == "en" & subid %in% affected_subjs & trialid == 3 & ianum >= 150, 
                        ianum + 1, ianum)) %>%
  filter(!(trialid == 3 & ianum == 149))

# Russian: add 1 to trialid from 4 on for ru_8
joint.data <- joint.data %>%
  mutate(trialid = ifelse(subid == "ru_8" & trialid >= 4, trialid + 1, trialid))

# Estonian: add 1 to trialid from 1 on for ee_22, add 1 to trialid from 4 on for ee_09
joint.data <- joint.data %>%
  mutate(trialid = ifelse(subid == "ee_22" & trialid >= 1, trialid + 1, trialid),
         trialid = ifelse(subid == "ee_09" & trialid >= 4, trialid +1, trialid))

# Check for non-unique IDs again: it should have 0 rows now
non_unique_ids <- joint.data %>% 
  group_by(lang, trialid, ianum) %>%
  summarise(unique_words = length(unique(ia)), nSubj = n()) %>%
  filter(unique_words > 1)

#########################
### TRANSFORM COLUMNS ###
#########################  

# HUMAN RT DATA
rt_data <- joint.data
rt_data <- rt_data %>%
  # dur = total reading time
  mutate(dur = as.double(dur)) %>%
  mutate(dur = if_else(is.na(dur), 0, dur)) %>% #Set the reading time for skipped words to 0
  rename(total_rt = dur) %>%
  
  # firstrun.dur = "gaze duration"
  mutate(firstrun.dur = as.double(firstrun.dur)) %>%
  mutate(firstrun.dur = if_else(is.na(firstrun.dur), 0, firstrun.dur)) %>% #Set the reading time for skipped words to 0
  rename(gaze_rt = firstrun.dur) %>%
  
  # firstfix.dur = "first fixation"
  mutate(firstfix.dur = as.double(firstfix.dur)) %>%
  mutate(firstfix.dur = if_else(is.na(firstfix.dur), 0, firstfix.dur)) %>% #Set the reading time for skipped words to 0
  rename(firstfix_rt = firstfix.dur) %>%
  
  group_by(lang, trialid, ianum, ia) %>%
  summarise(total_rt = mean(total_rt, na.rm = T),
            gaze_rt = mean(gaze_rt, na.rm = T),
            firstfix_rt = mean(firstfix_rt, na.rm = T)) %>%
  ungroup()

# Remove Estonian and Norwegian
rt_data <- rt_data %>%
  filter(!lang %in% c("ee", "no"))

########################################################################
### LOAD IN WORD FREQUENCY AND MULTILINGUAL GPT LONG CONTEXT RESULTS ###
########################################################################
# LONG CONTEXT = full window size of 512 previous characters
# Word frequency results are from Python library wordfreq

do_lags <- function(df) {
  result <- df %>%
    arrange(trialid, ianum) %>%
    group_by(trialid) %>%
    mutate(
      prev_surp = lag(surp),
      prev2_surp = lag(prev_surp),
      
      prev_freq = lag(freq),
      prev2_freq = lag(prev_freq),
      
      prev_len = lag(len),
      prev2_len = lag(prev_len),
      
      prev_ent = lag(ent),
      prev2_ent = lag(prev_ent)
    ) %>%
    ungroup()
}

langs <- c("du", "en", "fi", "ge", "gr", "he", "it", "sp", "ko", "tr", "ru")
mgpt_lc_df <- data.frame()
# MGPT LONG CONTEXT DATA
for (lang in langs) {
  mgpt_lc_df_i <- read.csv(paste0(path, "mgpt_lc/", lang, "_preds.csv"), header = T, sep = "\t") %>%
    rename(model_ia = ia) %>%
    mutate(ianum = ianum + 1) %>%
    dplyr::select(-X) %>%
    mutate(model = "mgpt_lc",
           lang = lang) %>%
    mutate(len = str_length(model_ia)) %>%
    do_lags(.)

  mgpt_lc_df <- rbind(mgpt_lc_df, mgpt_lc_df_i)
}

rt_data <-  rt_data %>%
  merge(mgpt_lc_df, by=c("lang", "trialid", "ianum")) %>%
  mutate(mismatch = model_ia != ia)

print(paste0(lang, " / MGPT LC: Filtered a total of ", sum(rt_data$mismatch), "rows, or ", sum(rt_data$mismatch)/nrow(rt_data), " of the data."))

##########################  
### SEPARATE LANGUAGES ###
##########################
for (l in langs) {
  langi <- subset(rt_data, lang == l)
  langi <- langi[order(langi$trialid, langi$ianum), ]
  langi$mismatch <- NULL
  write.csv(langi, paste0(path, "merged_data/", l, ".csv"), quote = T, row.names = F)
}

