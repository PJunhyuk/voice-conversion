clear
clc
tic

%% read input and target signals
[ input, ~ ] = audioread('junhyuk_1.wav');
[ target, fs ] = audioread('jamsoo_1.wav');

%% normalize signals
input_normalized = 100 * input / norm(input);
target_normalized = 100 * target / norm(target);

%% global variable setting
pvoc_ratio = 0;
mse_min = Inf;
mse_array = zeros(200, 1);

%% plot input&target signal in time domain
% subplot(2, 1, 1);
% plot(input);
% title('coffee jun: time - amp');
% xlabel('samples');
% ylabel('amplitude');
% ylim([-1 1]);
% subplot(2, 1, 2);
% plot(target);
% title('coffee bbbg4: time - amp');
% xlabel('samples');
% ylabel('amplitude');
% ylim([-1 1]);

%% plot input&target signal in frequency domain
% k = 0: size(input, 1)/2 - 1;
% freq = k * fs / size(input, 1);
% input_fft = abs(fft(input));
% plot(freq, input_fft(1:size(input, 1)/2), 'r');
% hold on;
% target_fft = abs(fft(target));
% plot(freq, target_fft(1:size(input, 1)/2), 'b');
% xlim([1 2000]);
% title('coffee: frequency - amp');
% xlabel('frequency(Hz)');
% ylabel('amplitude');
% legend('input', 'target');

%% finding optimal pvoc_ratio
for pvoc_ratio = 30: 200
    input_pvoc = pvoc(input_normalized, pvoc_ratio/100);
    input_resample = resample(input_pvoc, pvoc_ratio, 100);
    input_resample_normalized = 100 * input_resample / norm(input_resample);

    input_resample_normalized_fft = abs(fft(input_resample_normalized));
    target_normalized_fft = abs(fft(target_normalized));
    
    min_size = min(size(target_normalized_fft, 1), size(input_resample_normalized_fft, 1));
    min_size = round(min_size/2);
    mse_dif = target_normalized_fft(1: min_size) - input_resample_normalized_fft(1: min_size);

    mse = sum(mse_dif .^ 2);
    mse_array(pvoc_ratio) = mse;
    
    if mse < mse_min
        pvoc_ratio_opt = pvoc_ratio;
        mse_min = mse;
    end
end

%% plot mse_array 
% plot(mse_array);
% xlabel('pvoc ratio');
% ylabel('mse');
% title('mse array graph');

%% make optimal result of phase vocoding
input_pvoc_opt = pvoc(input_normalized, pvoc_ratio_opt / 100);
input_resample_opt = resample(input_pvoc_opt, pvoc_ratio_opt, 100);

input_pvoc = input_resample_opt;
input_pvoc_normalized = 100 * input_pvoc / norm(input_pvoc);

%% frequency optimizing using weight value
input_pvoc_normalized_fft = fft(input_pvoc_normalized);
target_normalized_fft = fft(target_normalized);

weight_value = 0.1;

input_pvoc_weighted_fft = zeros(size(input_pvoc_normalized_fft, 1), 1);

for i = 1: round(size(input_pvoc_normalized_fft, 1)/2)
    if abs(input_pvoc_normalized_fft(i)) * (1 - weight_value) > abs(target_normalized_fft(i))
        input_pvoc_weighted_fft(i) = input_pvoc_normalized_fft(i) * (1 - weight_value);
        input_pvoc_weighted_fft(size(input_pvoc_normalized_fft, 1) - i) = input_pvoc_normalized_fft(size(input_pvoc_normalized_fft, 1) - i) * (1 - weight_value);
    elseif abs(input_pvoc_normalized_fft(i)) * (1 + weight_value) < abs(target_normalized_fft(i))
        input_pvoc_weighted_fft(i) = input_pvoc_normalized_fft(i) * (1 + weight_value);
        input_pvoc_weighted_fft(size(input_pvoc_normalized_fft, 1) - i) = input_pvoc_normalized_fft(size(input_pvoc_normalized_fft, 1) - i) * (1 + weight_value);
    else
        input_pvoc_weighted_fft(i) = input_pvoc_normalized_fft(i);
        input_pvoc_weighted_fft(size(input_pvoc_normalized_fft, 1) - i) = input_pvoc_normalized_fft(size(input_pvoc_normalized_fft, 1) - i);
    end
end

%% plot input&target&input_weighted graph
% k = 0: size(input_pvoc_normalized, 1)/2 - 1;
% freq = k * fs / size(input_pvoc_normalized, 1);
% input_pvoc_temp = abs(input_pvoc_normalized_fft);
% plot(freq, input_pvoc_temp(1: size(input_pvoc_normalized, 1)/2), 'r');
% hold on;
% target_fft_temp = abs(target_normalized_fft);
% plot(freq, target_fft_temp(1: size(input_pvoc_normalized, 1)/2), 'b');
% hold on;
% input_pvoc_weighted_temp = abs(input_pvoc_weighted_fft);
% plot(freq, input_pvoc_weighted_temp(1: size(input_pvoc_normalized, 1)/2), 'g');
% title('input pvoc, input pvoc weighted, target graph');
% xlabel('frequency(Hz)');
% ylabel('amplitude');
% legend('input', 'target', 'input weighted');
% xlim([0 2000]);

%% make final result
input_pvoc_weighted = real(ifft(input_pvoc_weighted_fft));

%% save final result
% audiowrite('junhyuk_to_jamsoo_1.wav', input_pvoc_weighted, fs);

toc