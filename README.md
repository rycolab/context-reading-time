# On The Role of Context in Reading Time Prediction

This repository contains the code used for the paper ["On The Role of Context in Reading Time Prediction"](https://arxiv.org/abs/2409.08160), accepted to EMNLP 2024 as a main conference short paper.

## Data preprocessing 

We use version 1.2 of the MECO dataset, stored in `joint_data_trimmed.rda`. However, an off-by-one issue was detected in the trial, sentence and word (interest area) ID
scheme for some of the tokens, which would lead to incorrect data when averaging across subjects. This is corrected in `preprocessing.R`. The corrected data is then merged with the surprisal estimates from mGPT, which are taken from [this project](https://github.com/wilcoxeg/xlang-processing) and given in `mgtp_lc/`. This script writes the csv files in `merged_data/`.

Our analysis uses the L1 (native speakers) data. For the sake of convenience for researchers who might be interested in using corrected L2 (second language learners) data, we provide code that performs the same correction in `MECO_L2_fix.R`. 

## Analysis

The analyses discussed in the paper can be found in `analysis.Rmd`. 

## Citation

Please cite our work as:

```
@inproceedings{opedal2024role,
  title = {On the Role of Context in Reading Time Prediction},
  author = {Opedal, Andreas and Chodroff, Eleanor and Cotterell, Ryan and Wilcox, Ethan},
  booktitle = {Proceedings of the 2024 Conference on Empirical Methods in Natural Language Processing},
  month = nov,
  year = {2024},
  publisher = {Association for Computational Linguistics},
  address = {Miami, Florida, USA},
  url = {https://arxiv.org/abs/2409.08160},
}
```
