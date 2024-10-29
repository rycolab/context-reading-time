# Multilingual Eye-Tracking Corpus (MECO) ID Fix - L2
# E. Chodroff, R. Cotterell, A. Opedal, E. Wilcox
# 16 Oct 2024

# Load MECO L2 data - V1.1
load("./joint_data_l2_trimmed.rda")

# Identify non-unique IDs based on the Trial ID and IA Number columns (trialid, ianum)  
# We are ignoring Sentence Number (sentnum) errors.
non_unique_ids <- joint.data %>% 
  group_by(lang, trialid, ianum) %>%
  summarise(unique_words = length(unique(ia))) %>%
  filter(unique_words > 1)

# Spanish - spa36 is off by one from trialid 5
joint.data <- joint.data %>%
  mutate(trialid = ifelse(subid == "spa36" & trialid >= 5, trialid + 1, trialid))

# Dutch - DU_30 is off by one from trialid 6
# Italian - L2_025 is off by one from trialid 6
joint.data <- joint.data %>%
  mutate(trialid = ifelse(subid %in% c("DU_30", "L2_025") & trialid >= 6, trialid + 1, trialid))

# Greek - Gr45 is off by one from trialid 7
joint.data <- joint.data %>%
  mutate(trialid = ifelse(subid == "Gr45" & trialid >= 7, trialid + 1, trialid))

# Check for non-unique IDs again: it should have 0 rows now
non_unique_ids <- joint.data %>% 
  group_by(lang, trialid, ianum) %>%
  summarise(unique_words = length(unique(ia)), nSubj = n()) %>%
  filter(unique_words > 1)

