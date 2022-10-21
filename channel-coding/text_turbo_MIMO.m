function [] = transmission_of_utf(language, modOrd, channel, K, perfect_csi)
%   channel: set the simulation physical channels  % 0 is AWGN, 1 is Fading Channel
%   K: set the simulatin fading channels  % 0 is Rayleigh Channel, 1 is Rician channel
%   perfect_csi: set the perfect channel state information  % 0 is perfect CSI, 1 is imperfect CSI

%% System Setting
% modOrd = 4; % Modulation order
bps = log2(modOrd); % Bits per symbol
L = 256; % Input packet length in bits
snr = [-6, -3, 0, 3, 6, 9, 12, 15, 18]; % Signal to noise ratio in dB
N_t = 2;  % The number of antennas at transmitter
N_r = 2;  % The number of antennas at receiver
sigma_e = 0.05;

% Path
InputPath = ['./utf-8/utf_encoded_bytes-' language '.txt'];  %'./utf_encoded_bytes-en.txt'
PathOutComm = ['./utf-8/' language '/' num2str(channel) num2str(K) num2str(perfect_csi) num2str(modOrd) '-final'];
%% Turbo Setting
% trellis = poly2trellis(4,[13 15 17],13);
trellis = poly2trellis(4,[13 15],13);
n = log2(trellis.numOutputSymbols);
numTails = log2(trellis.numStates)*n;
M = L*(2*n - 1) + 2*numTails; % Output codeword packet length
rate = L/M; % Coding rate
numiter = 4;
intrlvrIndices = randperm(L);

errRate = zeros(1, length(snr));
%% Simulation 
parfor i = 1:length(snr)
    turboenc = comm.TurboEncoder(trellis,intrlvrIndices);
    turbodec = comm.TurboDecoder(trellis,intrlvrIndices,numiter);
%     bpskmod = comm.BPSKModulator;
%     bpskdemod = comm.BPSKDemodulator('DecisionMethod','Log-likelihood ratio', ...
%         'Variance',noiseVar);

    
    [msgInBytes] = textread(InputPath,'%n');
    msg_len = length(msgInBytes);
    msgInBits = de2bi(msgInBytes, 8);
    msgInBits = reshape(msgInBits, msg_len*8, 1);
    m = mod(length(msgInBits), L);
    pad_data = randi([0 1],L-m,1);
    Bit_Stream = [msgInBits; pad_data];
    msgOutBits = zeros(length(Bit_Stream),1);
    ttlErr = 0;
    ttlBits = 0;
    for j = 1:length(Bit_Stream)/L
        data = Bit_Stream((j-1)*L + 1: j*L);
        encData = turboenc(data);
        modSig = qammod(encData,modOrd,'InputType','bit','UnitAveragePower',true);
        % receivedSignal = awgnchan(modSignal);
        % Channel
        if channel == 0 % AWGN
            rxSig = awgn(modSig, snr(i));
        elseif channel == 1 % Fading Channel
            paddingBits = randi([0,1], length(encData), N_t-1);
            paddingSigs = qammod(paddingBits,modOrd,'InputType','bit','UnitAveragePower',true);
            modSigs = [modSig, paddingSigs];
            % Create Channel Matrix
            mu = sqrt(K / (2 * (K + 1)));
            sigma = sqrt(1 / (2 * (K + 1)));
            H = mu + sigma*randn(N_t, N_r) + 1j*(mu + sigma*randn(N_t, N_r));
            % Fading
            rxSigs = modSigs*H;
            % awgn
            noise_std = 1 / sqrt(2 * (10 ^ (snr(i) / 10)));
            noise_std = noise_std*sqrt(N_t);
            noise = noise_std*(randn(size(rxSigs)) + 1j*randn(size(rxSigs)));
            rxSigs = rxSigs + noise;
            % MIMO detection
            if perfect_csi == 0
                H_hat = H'*pinv(H*H' + 2*noise_std^2*eye(N_t));
            else
                H_est = H + noise_std*(randn(N_t, N_r) + 1j*randn(N_t, N_r));
                H_hat = H_est'*pinv(H_est*H_est' + 2*noise_std^2*eye(N_t));
            end
            rxSigs = rxSigs*H_hat; 
            rxSig = rxSigs(:, 1);
        end
        demodSig = qamdemod(rxSig, modOrd, 'OutputType', 'approxllr', 'UnitAveragePower', true);
        rxBits = turbodec(-demodSig);
        msgOutBits((j-1)*L + 1 : j*L) = rxBits;
    end
    msgOutBits = msgOutBits(1:length(msgInBits));
    % count the bit error 
    numErr = biterr(msgInBits, msgOutBits);
    ttlErr = ttlErr + numErr;
    ttlBits = ttlBits + length(msgOutBits);
    errRate(i) = ttlErr/ttlBits;
    
    msgOutBytes = reshape(msgOutBits, msg_len, 8);
    msgOutBytes = bi2de(msgOutBytes);
    
    % record the decoded bits
    if exist(PathOutComm, 'dir')==0
        mkdir(PathOutComm);
    end
    path = [PathOutComm '/' num2str(snr(i), '%02d') '.txt'];
    fid = fopen(path,'wt');
    fprintf(fid,'%g\n',msgOutBytes);
    fclose(fid);
    
end
