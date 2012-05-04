;%% load data
data;
t = 100;
logt = log(t);
[n,m] = size(follows);
global_k = 10;

%% Find social opt (quite fast)
pOpt = p0(1:n);
options = optimset('GradObj','on','Display','iter',...
                ...'DerivativeCheck','on',...
                'Hessian','lbfgs','Algorithm','interior-point');
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

%% Load Data and Plot for Infinite Consumption Model
data;
[n,m] = size(follows);
infcon_p = []; % Original proportions
infcon_o = []; % Optimal proportions
% Select users who speak both languages
for i = 1:n
    infcon_p = [infcon_p; p0(i)];
    followers = follows(i,:);
    [~, j, ~] = find(followers);
    total_followers = length(j);
    qA = 0;
    qB = 0;
    for k = j
        if langs(1,k) == 1
            qA = qA + 1;
        end
        if langs(2,k) == 1
            qB = qB + 1;
        end
    end
    q0 = qA/(qA+qB);
    infcon_o = [infcon_o; q0];
end
figure;
subplot(1,2,1);
hold all;
title('Proportions (sorted by Opt)');
[~,idx] = sort(infcon_o);
plot((infcon_p(idx)),'o');
plot((infcon_o(idx)),'o');
% plot((p0(idx)),'.');
legend('Init','Opt','Location','NorthWest');
hold off;

subplot(1,2,2);
hold all;
title('Proportions (independent sort)');
[~,idx] = sort(infcon_o);
plot(sort(infcon_p(idx)),'o');
plot(sort(infcon_o(idx)),'o');
legend('Init','Opt','Location','NorthWest');
hold off;
% Plot p

% Plot qA/(qA+qB)

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
plot(sort(NashCondition(pNash, follows, langs, logt, constants, global_k)),'o')
plot(sort(NashCondition(pOpt, follows, langs, logt, constants, global_k)),'o')
plot(sort(NashCondition(p0(1:n), follows, langs, logt, constants, global_k)),'o')
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
plot((p0(idx)),'o');
plot((pOpt(idx)),'o');
plot((pNash(idx)),'o');
% plot((p0(idx)),'.');
legend('Init','Opt','Nash','Location','NorthWest');
hold off;

subplot(1,2,2);
hold all;
title('Proportions (sorted individually)');
[dum,idx] = sort(pOpt);
plot(sort(p0(idx)),'o');
plot(sort(pOpt(idx)),'o');
plot(sort(pNash(idx)),'o');
legend('Init','Opt','Nash','Location','NorthWest');
hold off;
