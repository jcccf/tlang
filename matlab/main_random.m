%% Load data
raw_data;
n = length(p0);

%% Remove nodes that have neither in-degree nor out-degree
d_in = sum(follows,1)';
d_out = sum(follows,2);
idx = d_in > 0 & d_out > 0;
follows = follows(idx,idx);
langs = langs(:,idx);
p0 = p0(idx);
d_in = sum(follows,1)';
d_out = sum(follows,2);
n = length(d_in);
m = sum(d_in);
% hold all;
% plot(log10(sort(d_in)));
% plot(log10(sort(d_out)));
% hold off;

%% Calculate stats about graph
avg_deg = full(sum(d_in) / n);
max_deg = full(max(d_in));
comm_min = full(min(sum(langs,2)));
comm_max = full(max(sum(langs,2)));
n_overlap = full(sum(sum(langs)) - n);
alpha_deg = full(1 + n / (sum(log(d_in))));
alpha_comm = full(1 + 2 / (sum(log(sum(langs,2)))));
c1 = logical(langs(1,:)'); c2 = logical(langs(2,:)');
mix_in_1 = full(sum(sum(follows(~c1,c1))) / sum(sum(follows(:,c1))));
mix_in_2 = full(sum(sum(follows(~c2,c2))) / sum(sum(follows(:,c2))));
mix_out_1 = full(sum(sum(follows(c1,~c1))) / sum(sum(follows(c1,:))));
mix_out_2 = full(sum(sum(follows(c2,~c2))) / sum(sum(follows(c2,:))));
fprintf('./benchmark -N %d -k %.1f -maxk %d -mu %.2f -t1 %.1f -t2 %.1f -minc %d -maxc %d -on %d -om 2\n', ...
    n, avg_deg, max_deg, mix_in_1, alpha_deg, alpha_comm, comm_min, comm_max, n_overlap);

%% Generate a uniform random graph
% edge_prob = (sum(sum(follows)) + n) / (n*n);
% A = sprand( n, n, edge_prob );
% A = spdiags(zeros(n,1),0,A);

%% Load LFR graph
base_dir = '../directed_networks/';
[A,comm] = direct_load_lfr([base_dir,'network.dat'],[base_dir,'community.dat']);
follows = A';
langs = comm';
logt = log(100);
global_k = 10;

[follows, langs, constants, nodemap] = filter_graph_for_optimization(...
                    follows, langs, p0);
[n,m] = size(follows);
p0 = rand(n,1);

%% Find social opt (quite fast)
pOpt = find_social_opt(follows, langs, logt, constants, global_k, p0);

%% Find Nash (Takes a long time..)
pNash = find_nash(follows, langs, logt, constants, global_k);
% pNash = find_nash(follows, langs, logt, constants, global_k, pNash);

%% Assuming given p0 is Nash, find values of k that makes it satisfy Nash
% cost_k = Findk(p0(1:n), follows, langs, logt, constants);
% cost_k = Findk(pNash, follows, langs, logt, constants);
cost_k = Findk(pOpt, follows, langs, logt, constants);

%% Show random graphs
% [dum,idx] = sortrows([sum(A,1)' + sum(A,2)]);
% spy(A(idx,idx));
% [dum,idx] = sortrows([sum(follows,1)' + sum(follows,2)]);
% figure; spy(follows(idx,idx));
% figure; hold all;
% plot(log10(sort(sum(A))));
% plot(log10(sort(sum(follows))));
% legend('LFR','Twitter','Location','NorthWest');
% ylabel('Node degree (log10)');
% xlabel('Sorted nodes');
% hold off;


