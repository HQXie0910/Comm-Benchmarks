%% This is file is used to achieve the separate coding communication
%  The imaged is encoded by various source coding algorithm
%  The channel coding is LDPC with various rate

function [] = jpeg_ldpc(dataset, source_cod, channel, K, perfect_csi)
% channel = 1; % 0 is AWGN, 1 is Fading Channel
% K = 1; % 0 is Rayleigh Channel, 1 is Rician channel
% perfect_csi = 1; % 0 is perfect CSI, 1 is imperfect CSI


%% Sys setting
% source_cod = 0; % 0 is jpeg; 1 is the webp
M = 8;  % the modulation order, i.e., 16 equals to 16-QAM
rate = 1/3;  % specided as 1/4, 1/3, 2/5, 1/2, 3/5, 2/3, 3/4, 4/5, 5/6, 8/9, or 9/10.
snr = -6:3:18;
N_t = 2;  % the number of users
N_r = 2; % the number of antennas at receiver
PathInput = ['/home/hx301/data/' dataset '/CommOutput/ref'];  % this is the compression output path
PathOutComm = ['/home/hx301/data/' dataset '/CommOutput/' num2str(channel) num2str(K) num2str(perfect_csi)]; % this is the output path after transmissio


fail_count = zeros(length(snr),1); % this is used to count the faild transmision image
errRate = zeros(length(snr), 1); % count the bit error rate

%% Channel coding--LDPC 
% parfor_progress(length(snr));
parfor ii = 1:length(snr)
    H = dvbs2ldpc(rate);     % parity-check martrix based by dvd standard
    msgLength = size(H,2) - size(H,1); 
    ldpcEncoder = comm.LDPCEncoder(H);  % LDPC encoder
    ldpcDecoder = comm.LDPCDecoder(H);  % LDPC decoder
    list_Out = dir(PathInput);
    fileNums_Out = size(list_Out);
    ttlBits = 0;  % used to count the total of transmitted bits
    ttlErr = 0;  % count the num of error bits
    PathSNR = [PathOutComm '/' num2str(snr(ii), '%02d')]; % check the path exist
    if exist(PathSNR, 'dir')==0
        mkdir(PathSNR);
    end
    for j = 3:fileNums_Out
        % read the compressed data
        path = [PathInput '/' list_Out(j).name];
        fileID = fopen(path,'rb');
        [msgIn, ~] = fread(fileID);
        msg_len = length(msgIn);
        fclose(fileID);
        % convert msg to bit stream
        msgInBits = de2bi(msgIn, 8);
        msgInBits = reshape(msgInBits, msg_len*8, 1);
        [supBits, ~, b] = ComputeSupBits(msgInBits, msgLength);
        Bits_Stream = [msgInBits; supBits];
        msgOutBits = zeros(length(Bits_Stream),1);
        for k = 1:b
            data = Bits_Stream((k-1)*msgLength + 1 : k*msgLength);
            % LDPC coding
            encData = ldpcEncoder(data);
            % modulation by QAM
            modSig = qammod(encData,M,'InputType','bit','UnitAveragePower',true);
            % Channel
            if channel == 0 % AWGN
                noise_std = 1 / sqrt(2 * (10 ^ (snr(ii) / 10)));
                noise = noise_std*(randn(size(rxSigs)) + 1j*randn(size(rxSigs)));
                rxSig = modSig + noise;
            elseif channel == 1 % Fading Channel
                paddingBits = randi([0,1], length(encData), N_t-1);
                paddingSigs = qammod(paddingBits,M,'InputType','bit','UnitAveragePower',true);
                modSigs = [modSig, paddingSigs];
                % Create Channel Matrix
                mu = sqrt(K / (2 * (K + 1)));
                sigma = sqrt(1 / (2 * (K + 1)));
                H = mu + sigma*randn(N_t, N_r) + 1j*(mu + sigma*randn(N_t, N_r));
                % Fading
                rxSigs = modSigs*H;
                % awgn
                noise_std = 1 / sqrt(2 * (10 ^ (snr(ii) / 10)));
                noise_std = noise_std*sqrt(N_t);
                noise = noise_std*(randn(size(rxSigs)) + 1j*randn(size(rxSigs)));
                rxSigs = rxSigs + noise;
                % MIMO detection
                if perfect_csi == 0
                    H_hat = H'*pinv(H*H' + 2*noise_std^2*eye(N_t));
                else
                    H_est = H + noise_std*(randn(N_t, N_r) + 1j*randn(N_t, N_r));
                    H_hat = H_est'*pinv(H_est*H_est' + 2*(noise_std^2)*eye(N_t));
                end
                rxSigs = rxSigs*H_hat; 
                rxSig = rxSigs(:, 1);
            end
            % demodulation
            demodSig = qamdemod(rxSig, M, 'OutputType', 'approxllr', 'UnitAveragePower', true);
            % LDPC decoding
            rxBits = ldpcDecoder(demodSig);
            msgOutBits((k-1)*msgLength + 1 : k*msgLength) = rxBits;
        end
        msgOutBits = msgOutBits(1:length(msgInBits));
        msgOut = reshape(msgOutBits, msg_len, 8);
        msgOut = bi2de(msgOut);
        % count the bit error 
        numErr = biterr(msgInBits, msgOutBits);
        ttlErr = ttlErr + numErr;
        ttlBits = ttlBits + length(msgInBits);
        % source decoding

        try
            pathOutComm = [PathSNR '/' list_Out(j).name];
            [fileID, msg] = fopen(pathOutComm, 'w');
            if fileID < 0
                error('Failed to create file "%s" because "%s"', outfile, msg);
            end
            fwrite(fileID, msgOut, 'uint8');
            fclose(fileID);
        catch
            % if the head file is broken, then record the faild
            % transmission image
            fail_count(ii) = fail_count(ii) + 1;
            pathOutComm = [PathOutComm '/' num2str(snr(ii), '%02d') '.txt'];
            fileID = fopen(pathOutComm, 'w');
            fprintf(fileID, [list_Out(j).name]);
            fclose(fileID);
        end     
    end
    errRate(ii) = ttlErr/ttlBits;
end

    
