function result = st_tModel(tModel, param, rfResponse, time)
% Function to select model that predicts fMRI responses to time-varying 
% visual stimuli.
%
% INPUTs:
% tModel        :   which model to use
%                   Hemodynamic models:
%                   * '1ch-glm': general linear model for fMRI (Boynton 1996)
%                   Optimized single-channel models:
%                   * '1ch-dcts': dynamic CTS (dCTS; Zhou 2017)
%                   Optimized two-channel models:
%                   * '2ch-exp-sig': adapted sustained and sigmoid transient
%                     (Stigliani et al. 2018)
% param        :   Struct with temporal parameters
% rfResponse   :   Stimulus time course (for full field response) or spatial 
%                   pRF time course to given stimulus (in milliseconds)
% time          :   time axis corresponding to stim_ts          
%
% OUTPUT:
% result    :   struct with predicted neural response for each channel.
%
% Note: This function is adapted from Stigliani et al. 2018 PLoS CB
% temporal channel code repository called "cstmodel"

fprintf('Generating irf for %s model...\n', tModel)

switch tModel
    case {'glm','1ch-glm'}
        result  = linearModel(param, rfResponse, time);
    case {'DN','1ch-dcts'}
        result  = DNmodel2(param, rfResponse, time);
    case {'2ch','2ch-exp-sig'}
        result  = twoChansmodel(param, rfResponse, time);
    case {'2ch-css-sig'}
        result  = twoChansmodel_Scss_Tsig(param, rfResponse, time);
end

end
