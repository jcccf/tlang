function [f,g] = NashCondition2(p, follows, langs, logt, constants, k)
% follows: n-by-m (sparse) 0-1 matrix.  follows(j,i) = 1 if i follows j
%          m = total number of users in graph
%          n = total number of bilingual users who are followed-by
% langs  : 2-by-m 0-1 matrix.  langs(j,i) = 1 if i speaks language j.
% logt   : Some constant multiplier (see paper)
% p      : n-by-1 vector of current iterate proportions in [0,1]
if nargout > 1
    [F,J] = NashCondition(p, follows, langs, logt, constants, k);
    f = F'*F;
    g = (2*F'*J)';
else
    F = NashCondition(p, follows, langs, logt, constants, k);
    f = F'*F;
end
end
