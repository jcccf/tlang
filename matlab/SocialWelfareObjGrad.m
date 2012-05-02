function [f,g] = SocialWelfareObjGrad(p, follows, langs, logt, constants)
% follows: n-by-m (sparse) 0-1 matrix.  follows(j,i) = 1 if i follows j
%          m = total number of users in graph
%          n = total number of bilingual users who are followed-by
% langs  : 2-by-m 0-1 matrix.  langs(j,i) = 1 if i speaks language j.
% logt   : Some constant multiplier (see paper)
% p      : n-by-1 vector of current iterate proportions in [0,1]

%   j in {1,...,m},  i in {1,...,n}
[n,m] = size(follows);
f = 0;
g = zeros(n,1);
for i=1:m
    if langs(1,i) == 1
        sj = follows(:,i)' * p + constants(1,i);
        if sj > 1e-30
            f = f + log(sj) + logt;
            g = g + follows(:,i) ./ sj;
        end
    end
    if langs(2,i) == 1
        q = 1-p;
        rj = follows(:,i)' * q + constants(2,i);
        if rj > 1e-30
            f = f + log(rj) + logt;
            g = g - follows(:,i) ./ rj;
        end
    end
end
% Change sign since we are maximizing
f = -f;
g = -g;
end
