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
    @(p)SocialWelfareObjGrad(p, follows, langs, logt), ...
    popt, ...
    [],[],[],[], ...
    zeros(n,1),ones(n,1), ...
    [], options);

% Find Nash (Takes a long time..)
pNash = p0(1:n);
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
    @(p)NashCondition(p, follows, langs, logt), ...
    pNash, zeros(n,1), ones(n,1), options);

% Plot results
figure;
hold all;
title('Nash condition (sorted)');
plot(sort(NashCondition(pNash, follows, langs, logt)),'.')
plot(sort(NashCondition(popt, follows, langs, logt)),'.')
plot(sort(NashCondition(p0(1:n), follows, langs, logt)),'.')
legend('Nash','Opt','Init','Location','NorthWest');
ylim([-40,50]);
hold off;

figure;
hold all;
title('Social welfare');
sw = -[SocialWelfareObjGrad(pNash, follows, langs, logt),
      SocialWelfareObjGrad(popt, follows, langs, logt),
      SocialWelfareObjGrad(p0(1:n), follows, langs, logt)];
bar(sw);
set(gca,'XTick',1:3);
set(gca,'XTickLabel',{'Nash','Opt','Init'});
dy = max(sw)/30;
for i=1:3
    text(i,sw(i)+dy,sprintf('%f',sw(i)),'HorizontalAlignment','center');
end
hold off;
