%% load data
data;
t = 100;
logt = log(t);
[n,m] = size(follows);
global_k = 10;

%% Find social opt (quite fast)
pOpt = p0(1:n);
options = optimset('GradObj','on','Display','iter',...
                ...'DerivativeCheck','on',...
                'Hessian','lbfgs',...
                'Algorithm','interior-point'...
                ...'Algorithm','active-set'...
                );
[pOpt,fval,exitflag,output] = fmincon( ...
    @(p)SocialWelfareObjGrad(p, follows, langs, logt, constants, global_k), ...
    pOpt, ...
    [],[],[],[], ...
    zeros(n,1),ones(n,1), ...
    [], options);

%% Find Nash (Takes a long time..)

% Somehow, starting from given proportions lead to numerical problems
% pNash = p0(1:n); 

% Better to start with SW opt or random.
pNash = pOpt;
% pNash = rand(n,1);
options = optimset('Display','iter',...
    ...'Algorithm','levenberg-marquardt',...
    'Algorithm','trust-region-reflective',...
    ...'Algorithm','trust-region-dogleg',...
    ...'MaxFunEvals',2000,...
    'MaxIter',100,...
    'Jacobian','on',...
    ...'DerivativeCheck','on',...
    'Diagnostics','on');
% [pNash,fval2,exitflag2,output2] = fsolve( ...
%     @(p)NashCondition(p, follows, langs, logt), ...
%     p0(1:n), options);

[pNash,fval2,exitflag2,output2] = lsqnonlin( ...
    @(p)NashCondition(p, follows, langs, logt, constants, global_k), ...
    pNash, zeros(n,1), ones(n,1), options);

%% Assuming given p0 is Nash, find values of k that makes it satisfy Nash
k = Findk(p0(1:n), follows, langs, logt, constants);

%% Plot results
figure;
% Filter positive and not inf
kk = k( (k>=0) & (k<Inf) );
hist(log10(kk),25);
title('Histogram of log_{10} k');
xlabel('log_{10} k');
ylabel('Frequency');

figure;
hold all;
title('Nash condition (sorted)');
plot(sort(NashCondition(pNash, follows, langs, logt, constants, global_k)),'.')
plot(sort(NashCondition(pOpt, follows, langs, logt, constants, global_k)),'.')
plot(sort(NashCondition(p0(1:n), follows, langs, logt, constants, global_k)),'.')
legend('Nash','Opt','Init','Location','NorthWest');
ylim([-30,40]);
hold off;

figure;
hold all;
title('Social welfare');
sw = -[SocialWelfareObjGrad(pNash, follows, langs, logt, constants, global_k),
      SocialWelfareObjGrad(pOpt, follows, langs, logt, constants, global_k),
      SocialWelfareObjGrad(p0(1:n), follows, langs, logt, constants, global_k)];
rand_sw = 0;
for i=1:30
    rand_sw = rand_sw - SocialWelfareObjGrad(rand(n,1), follows, langs, logt, constants, global_k);
end
rand_sw = rand_sw / 30;
sw = [sw; rand_sw];
bar(sw);
set(gca,'XTick',1:4);
set(gca,'XTickLabel',{'Nash','Opt','Init','Random'});
dy = max(sw)/30;
for i=1:4
    text(i,sw(i)+dy,sprintf('%f',sw(i)),'HorizontalAlignment','center');
end
hold off;

figure;
subplot(1,2,1);
hold all;
title('Proportions (sorted by Opt)');
[dum,idx] = sort(pOpt);
plot((pNash(idx)),'.');
plot((pOpt(idx)),'.');
% plot((p0(idx)),'.');
legend('Nash','Opt','Location','NorthWest');
hold off;

subplot(1,2,2);
hold all;
title('Proportions (sorted individually)');
[dum,idx] = sort(pOpt);
plot(sort(pNash(idx)),'.');
plot(sort(pOpt(idx)),'.');
plot(sort(p0(idx)),'.');
legend('Nash','Opt','Init','Location','NorthWest');
hold off;
