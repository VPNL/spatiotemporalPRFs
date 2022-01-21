function ons=st_codestim_on(stiminput)

   
   f = find(diff([0,stiminput',0]~=0));
   ons = (f(1:2:end-1)) ./1000;  % Start indices


end
