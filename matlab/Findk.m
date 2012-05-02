function k = Findk(p, follows, langs, logt, constants)
[n,m] = size(follows);
k = zeros(n,1);
F = NashCondition(p, follows, langs, logt, constants, 0);
k = F ./ (1-2*p);
end