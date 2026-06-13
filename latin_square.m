function A = latin_square(N,M)
%latin_square Generates NxM Latin Square matrix of integers 1:N
%   Each row and column contains each integer once in random order
switchMN = 0;
if nargin < 2
    M = N;
else
    if ( M > N )
        switchMN = 1;
        N_new = M;
        M = N;
        N = N_new;
    end
end

A = zeros(N,M);

A(1,:) = randperm(M);
for i = 2:N
    A(i,:) = [A(i-1,2:M) A(i-1,1)];
end
A = A(randperm(N),:);
A = A(:,randperm(M));

if ( switchMN )
    A = A';
end

end

