function [A,comm] = direct_load_lfr(net,lab)
% net:  network.dat adjacency matrix
% lab:  community.dat labels for communities
% A:    Adjacency matrix
% comm: community matrix.  comm(i,j) = 1 if node i belongs to comm j

network = load(net);
n = max(network(:));
if size(network,2) == 2 % unweighted
A = sparse(network(:,1),network(:,2),1,n,n);
elseif size(network,2) == 3 % weighted
A = sparse(network(:,1),network(:,2),network(:,3),n,n);
end

comm = sparse(n,n);
f = fopen(lab,'r');
for k=1:n
    tline = fgetl(f);
    s2 = regexp(tline,'\t','split');
%     fprintf('%s  ',s2{1});
    s2 = regexp(deblank(s2{2}),' ','split');
    for l=1:numel(s2)
%         fprintf('%s ',s2{l});
        j = str2double(s2{l});
        comm(k,j) = 1;
    end
%     fprintf('\n');
end
fclose(f);

comm = comm( :, sum(comm) > 0);

end