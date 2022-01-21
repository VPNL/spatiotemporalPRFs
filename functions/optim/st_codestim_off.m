function offs=st_codestim_off(stiminput)

   
   f = find(diff([0,stiminput',0]~=0));
   offs = (f(2:2:end)-1) ./1000;  % Consecutive oneset™ counts


end
