function normedResponse = normMax(response)
% Function to set max height of response to 1
    normedResponse = response./max(response,[],'omitnan');
end