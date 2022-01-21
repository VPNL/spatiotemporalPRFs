function onoffs=st_codestim_onoff(stiminput,fs)

   
   f = find(diff([0,stiminput',0]~=0));
   ons = (f(1:2:end-1)) ./fs;  % Start indices
   offs = (f(2:2:end)-1) ./fs;  % Consecutive oneset™ counts


   onoffs = [ons; offs];
end
