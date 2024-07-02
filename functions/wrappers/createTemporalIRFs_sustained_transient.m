function f = createTemporalIRFs_sustained_transient(x)
% Create temporal IRFs for sustained and transient channel
irfSustained = tch_irfs('S', x.tau_s, x.n1, x.n2, x.kappa, x.fs);
irfTransient = tch_irfs('T', x.tau_t, x.n1, x.n2, x.kappa, x.fs);

f = struct();
f.temporal = zeros(max([length(irfSustained),length(irfTransient)]),3);

% Normalize such that area under the curve sums to 1
f.temporal(1:length(irfSustained),1) = normSum(irfSustained);

% For transient nrf, we do this separately for positive and negative parts:
% First find indices
pos_idx = irfTransient>=0;
neg_idx = irfTransient<0;

%         scf = 1;% 0.5; % sum of area under each pos/neg curve
scf = 0.5; % sum of area under each pos/neg curve

% Get positive part and normalize sum
irfT_pos = irfTransient(pos_idx);
irfT_pos = scf*normSum(irfT_pos);

% Get negative part and normalize sum
irfT_neg = abs(irfTransient(neg_idx));
irfT_neg = -scf*normSum(irfT_neg);

% Combine positive and negative parts
nrfT2 = NaN(size(irfTransient));
nrfT2(pos_idx) = irfT_pos;
nrfT2(neg_idx) = irfT_neg;

f.temporal(1:length(nrfT2),2) = nrfT2;
f.temporal(1:length(nrfT2),3) = -nrfT2;
f.scaleFactorNormSumTransChan = scf;

end