function normedResponse = normSum(response)
% Function to set sum of response to 1
    normedResponse = response./sum(response,[],'omitnan');
end