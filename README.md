# spatiotemporalPRFs
Code repository to reconstruct, fit, and use spatiotemporal pRF models.

This code is used in the following two papers:
1. **Characterizing Spatiotemporal Population Receptive Fields in Human Visual Cortex with fMRI**
by Insub Kim, Eline R. Kupers, Garikoitz Lerma-Usabiaga and Kalanit Grill-Spector (2024)
_Journal of Neuroscience_, 44(2) e0803232023; https://doi.org/10.1523/JNEUROSCI.0803-23.2023

2. **Rethinking simultaneous suppression in visual cortex via compressive spatiotemporal population receptive fields**
by Eline R. Kupers, Insub Kim, and Kalanit Grill-Spector (2024)
_Nature Communications_, 15, 6885. https://doi.org/10.1038/s41467-024-51243-7

## Overview
* stPRFsRootPath.m        : function to define root path
* stPredictBOLDFromStim.m : main function to reconstruct spatiotemporal pRFs and generate predicted time series (neural and BOLD) given the stimulus sequence
  - INPUTS:
    * Stim
    * Params struct with modeling options: what pRF model to use, what HRF, etc.
    
  - STEPS:
    1. get3DSpatiotemporalpRFs(params)               --> create pRF filters (linear step)
    2. getPRFStimResponse(stim, PRF filters, params) --> stim * pRF = pRF response (linear step)
    3. applyReLU(pRFResponse(pRF response, params)   --> relu(pRF response) (nonlinear step)
    4. applyNonlinearity(relu pRF Response, params)   --> predicted neural response (nonlinear step)
    5. (Optional) Combine neural channels (e.g., transient on and transient off)
    6. (Optional) Normalize height of neural channels to max = 1.
    7. getPredictedBOLDresponse(predicted neural response, HRF, params) --> predicted neural response * HRF = predited BOLD response (linear step)
    
  - OUTPUTS: 
    * Predicted time series: linear filtered pRF response, (final) neural response, and BOLD response
    * pRFs
    * HRF
    * params

## Folder organization
* functions
  - external
  - utils
  - wrappers
  - example

## Example:
* run example/s_simpleTutorial.m!
