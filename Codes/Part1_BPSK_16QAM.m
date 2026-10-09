set(0, 'DefaultFigureWindowStyle', 'docked'); clear; clc;
%% ======== Single Carrier Communication System ========
%  Modulation : BPSK and 16QAM
%  Channel    : AWGN(0,No/2) (baseband equivalent)
%  =====================================================

%% ================ Variables Definition ===============
Eb     = 1;        % normalized to 1
Eb_No  = 1:1:30;   % Eb/No
BER_B  = zeros(size(Eb_No));
BER_16 = zeros(size(Eb_No));

N_bits = 1e6;      % num of bits (large enough for low BER)
Ns_B   = N_bits;   % num of symbols
Ns_16  = N_bits/4; % num of symbols
bits   = randi([0 1], N_bits, 1);

%% ==================== 1. Mapper ======================
%  -------------- BPSK:  1 bit  per symbol -------------
S_B = (2*bits - 1) * sqrt(Eb); % 1 -> sqrt(Eb), 0 -> -sqrt(Eb)

%  -------------- 16QAM: 4 bits per symbol -------------
Eo = Eb/2.5;

S_16_temp = zeros(N_bits/2,1);
for i = 1:1:length(S_16_temp)
    temp = [bits(2*i), bits(2*i - 1)];
    if temp == [0 0]
        S_16_temp(i) = -3;
    elseif temp == [0 1]
        S_16_temp(i) = -1;
    elseif temp == [1 1]
        S_16_temp(i) =  1;
    elseif temp == [1 0]
        S_16_temp(i) =  3;
    end
end

S_16 = zeros(Ns_16, 1);
for i = 1:1:length(S_16)
    S_16(i) = S_16_temp(2*i) + j * S_16_temp(2*i - 1); % I Q
end
S_16 = S_16 * sqrt(Eo);


for i = 1:1:length(Eb_No)
    %% ==================== 2. Channel =====================
    No = Eb / Eb_No(i);
    
    %------------------------- BPSK  -------------------------
    W  = sqrt(No/2) .* randn(Ns_B,1); 
    X_B  = S_B + W;
    
    %------------------------- 16QAM -------------------------
    W = sqrt(No/2) .* (randn(Ns_16,1) + j*randn(Ns_16,1));
    X_16 = S_16 + W;

    %% ==================== 2. Demapper ====================
    %  ----------- BPSK: Decision boundary is 0 ------------
    bits_B_hat  = X_B > 0; % X > 0 -> decide 1, X < 0 -> decide 0

    %  16QAM: Decision boundaries per axis are 0 and ±2*sqrt(Eo)
    XI_16  = real(X_16);
    XQ_16  = imag(X_16);

    b3_hat = XI_16 > 0;                     % sign of I
    b2_hat = abs(XI_16) < 2*sqrt(Eo);       % inner vs outer on I
    b1_hat = XQ_16 > 0;                     % sign of Q
    b0_hat = abs(XQ_16) < 2*sqrt(Eo);       % inner vs outer on Q

    bits_16_hat = [b0_hat, b1_hat, b2_hat, b3_hat]';
    bits_16_hat = bits_16_hat(:);
    
    %% ================= 2. BER Calculator =================
    %  ----------------------- BPSK  ------------------------
    BER_B(i)  = mean(bits ~= bits_B_hat ); % ~= is for XOR

    %  ----------------------- 16QAM -----------------------
    BER_16(i) = mean(bits ~= bits_16_hat);

end

%% ==================== Theoretical BER ====================
%  ------------------------- BPSK  -------------------------
BER_B_theo  = 0.5   * erfc(sqrt(Eb_No));

%  ------------------------- 16QAM -------------------------
BER_16_theo = 0.375 * erfc(sqrt(Eb_No/2.5));

%% ======================= Plotting ========================
Eb_No_dB = 10*log10(Eb_No);

figure;

%  ------------------------- BPSK  -------------------------
semilogy(Eb_No_dB, BER_B,       'b'  , 'LineWidth', 1); hold on;
semilogy(Eb_No_dB, BER_B_theo,  'b--', 'LineWidth', 1); hold on;

%  ------------------------- 16QAM -------------------------
semilogy(Eb_No_dB, BER_16,      'r'  , 'LineWidth', 1); hold on;
semilogy(Eb_No_dB, BER_16_theo, 'r--', 'LineWidth', 1); hold on;

grid on; xlabel('Eb/No (dB)'); ylabel('BER');
title ('BER vs Eb/No over AWGN channel');
legend('BPSK  (Simulated)', 'BPSK  (Theoretical)', ...
       '16QAM (Simulated)', '16QAM (Theoretical)');
ylim([1e-6 1]);