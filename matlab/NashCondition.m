function [F,J] = NashCondition(p, follows, langs, logt, constants, k)
% follows: n-by-m (sparse) 0-1 matrix.  follows(j,i) = 1 if i follows j
%          m = total number of users in graph
%          n = total number of bilingual users who are followed-by
% langs  : 2-by-m 0-1 matrix.  langs(j,i) = 1 if i speaks language j.
% logt   : Some constant multiplier (see paper)
% p      : n-by-1 vector of current iterate proportions in [0,1]

%   j in {1,...,m},  i in {1,...,n}
[n,m] = size(follows);
F = -k.*(1-2*p);
if nargout > 1
    if length(k) == 1
        J = 2*k*eye(n,n);
    elseif length(k) == n
        J = diag(2*k);
    else
        disp('ERROR: length of k is not 1 or n');
    end
end
q = 1-p;
for i=1:m
    if langs(1,i) == 1
        sj = follows(:,i)' * p + constants(1,i);
        if sj > 1e-8
            sj2 = sj*sj;
            F = F + (1/sj2)*follows(:,i) .* ( (log(sj)+logt)*(sj-p) + p );
            if nargout > 1
                sj3 = sj*sj2;
                g = follows(:,i) .* ((1-2*log(sj)-2*logt)/sj3*(sj-p) + (log(sj)+logt)/sj2 - 2/sj3*p);
                G = (g * follows(:,i)') - spdiags(g,0,n,n);
                g = follows(:,i) .* (2/sj2 - 3/sj3*p - 2/sj3*(log(sj)+logt)*(sj-p));
                J = J + G + spdiags(g,0,n,n);
            end
        end
    end
    if langs(2,i) == 1
        rj = follows(:,i)' * q + constants(2,i);
        if rj > 1e-8
            rj2 = rj*rj;
            F = F - (1/rj2)*follows(:,i) .* ( (log(rj)+logt)*(rj-q) + q );
            if nargout > 1
                rj3 = rj*rj2;
                g = follows(:,i) .* ((1-2*log(rj)-2*logt)/rj3*(rj-q) + (log(rj)+logt)/rj2 - 2/rj3*q);
                G = (g * follows(:,i)') - spdiags(g,0,n,n);
                g = follows(:,i) .* (2/rj2 - 3/rj3*q - 2/rj3*(log(rj)+logt)*(rj-q));
                J = J + G + spdiags(g,0,n,n);
            end
        end
    end
end

% fprintf('%g\n',norm(F,2));
end
