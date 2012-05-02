% load data
data;
t = 100;
logt = log(t);
[n,m] = size(follows);

% Find social opt (quite fast)
popt = p0(1:n);
options = optimset('GradObj','on','Display','iter',...
                ...'DerivativeCheck','on',...
                'Hessian','lbfgs','Algorithm','interior-point');
[popt,fval,exitflag,output] = fmincon( ...
    @(p)SocialWelfareObjGrad(p, follows, langs, logt, constants), ...
    popt, ...
    [],[],[],[], ...
    zeros(n,1),ones(n,1), ...
    [], options);

%% Find Nash (Takes a long time..)

% Somehow, starting from given proportions lead to numerical problems
% pNash = p0(1:n); 

% Better to start with SW opt or random.
pNash = popt;
% pNash = rand(n,1);
options = optimset('Display','iter',...
    ...'Algorithm','levenberg-marquardt',...
    'Algorithm','trust-region-reflective',...
    ...'Algorithm','trust-region-dogleg',...
    ...'MaxFunEvals',2000,...
    'Jacobian','on',...
    ...'DerivativeCheck','on',...
    'Diagnostics','on');
% [pNash,fval2,exitflag2,output2] = fsolve( ...
%     @(p)NashCondition(p, follows, langs, logt), ...
%     p0(1:n), options);

[pNash,fval2,exitflag2,output2] = lsqnonlin( ...
    @(p)NashCondition(p, follows, langs, logt, constants), ...
    pNash, zeros(n,1), ones(n,1), options);

%% Plot results
figure;
hold all;
title('Nash condition (sorted)');
plot(sort(NashCondition(pNash, follows, langs, logt, constants)),'.')
plot(sort(NashCondition(popt, follows, langs, logt, constants)),'.')
plot(sort(NashCondition(p0(1:n), follows, langs, logt, constants)),'.')
legend('Nash','Opt','Init','Location','NorthWest');
ylim([-30,40]);
hold off;

figure;
hold all;
title('Social welfare');
sw = -[SocialWelfareObjGrad(pNash, follows, langs, logt, constants),
      SocialWelfareObjGrad(popt, follows, langs, logt, constants),
      SocialWelfareObjGrad(p0(1:n), follows, langs, logt, constants)];
bar(sw);
set(gca,'XTick',1:3);
set(gca,'XTickLabel',{'Nash','Opt','Init'});
dy = max(sw)/30;
for i=1:3
    text(i,sw(i)+dy,sprintf('%f',sw(i)),'HorizontalAlignment','center');
end
hold off;

figure;
hold all;
title('Proportions (sorted)');
[dum,idx] = sort(popt);
plot((pNash(idx)),'.');
plot((popt(idx)),'.');
% plot((p0(idx)),'.');
legend('Nash','Opt','Init','Location','NorthWest');
hold off;
