% calculate absolute interconverting fluxes between circulating nutrients
%
% input includes the direct contribution matrix and the carbon atom Fcirc
% values
%
% Hui et al.

input_file = 'result_directContributions_fastedCD.xlsx';%result file generated by running the script 'calDirectContributions.m'
input_file2 = 'FcircPrime_fastedCD.xlsx'; %use the same order for the list of nutrients
output_file = 'result_interconvertingFluxes_fastedCD.xlsx';
[M_DC,text1,raw] = xlsread(input_file);


% for faster computation, exclude essential nutrients (close to zero contribution from others)
M_DC_mean = M_DC(:,1:2:end);
M_DC_sem = M_DC(:,2:2:end);
zind = find(sum(M_DC_mean,2)<0.03);%use a cutoff of 3%
M_DC_mean(zind,:) = []; M_DC_mean(:,zind) = [];
M_DC_sem(zind,:) = []; M_DC_sem(:,zind) = [];
% fill the diaganol entries with direct contribution from the storages
zm_mean = M_DC_mean;
zm_sem = M_DC_sem;
for zi = 1:size(M_DC_mean,2)
    zm_mean(zi,zi) = 1-sum(M_DC_mean(zi,:));
    zm_sem(zi,zi) = sqrt(M_DC_sem(zi,:)*(M_DC_sem(zi,:)'));
end


% calculate the correction factors between carbon atom Fcirc values and
% total fluxes
M = zm_mean';
SEM = zm_sem';

N = size(M,1); %size of the square matrix
C = zeros(1,N);

for n = 1:N
C(n) = M(n,n); %initiate the coefficient

I1 = setdiff([1:N],n);

    for i1 = I1
        I2 = setdiff(I1,i1);
        P = perms(I2);
        C_i1 = M(i1,i1)*M(i1,n);
        C(n) = C(n)+C_i1;

        N_P = size(P,2);
        for i2 = 1:N_P
            P2 = unique(P(:,1:i2),'rows');
            [N_r,N_c] = size(P2);
            for i3 = 1:N_r
                C_i3 = M(i1,i1)*M(i1,P2(i3,1));
                for i4 = 2:N_c
                    C_i3 = C_i3*M(P2(i3,i4-1),P2(i3,i4));
                end
                C_i3 = C_i3*M(P2(i3,end),n);
                
                C(n) = C(n)+C_i3;
            end
        end
    end
end

NN = size(M_DC,1);
correctionFactor = ones(NN,1);
zind2 = setdiff(1:NN,zind);
correctionFactor(zind2) = C;


% calculate the absolute interconverting fluxes
[values,text2,raw] = xlsread(input_file2);
J = values./repmat(correctionFactor,1,2);
J_mean = J(:,1);
J_sem = J(:,2);
J_sem_rel = J_sem./J_mean;

% fill the diaganol entries with direct contribution from the storages
M_DC_mean = M_DC(:,1:2:end);
M_DC_sem = M_DC(:,2:2:end);
zm_mean = M_DC_mean;
zm_sem = M_DC_sem;
for zi = 1:size(M_DC_mean,2)
    zm_mean(zi,zi) = 1-sum(M_DC_mean(zi,:));
    zm_sem(zi,zi) = sqrt(M_DC_sem(zi,:)*(M_DC_sem(zi,:)'));
end
M_DC_mean = zm_mean;
M_DC_sem = zm_sem;
M_DC_sem_rel = M_DC_sem./M_DC_mean;

M_flux_mean = M_DC_mean.*repmat(J_mean,1,NN);
M_flux_sem_rel = sqrt(M_DC_sem_rel.^2+repmat(J_sem_rel,1,NN).^2);
M_flux_sem = M_flux_mean.*M_flux_sem_rel;
output = NaN(size(M_DC));
output(:,1:2:end) = M_flux_mean;
output(:,2:2:end) = M_flux_sem;


%output results
nutrients = text2(2:end,1);
rownames = [{''};nutrients];
columnnames = repmat({''},size(nutrients));
columnnames = [nutrients columnnames]';
columnnames = columnnames(:)';

output = [columnnames; num2cell(output)];
output = [rownames output];

writetable(table(output),output_file,'WriteVariableNames',false);
