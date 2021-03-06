% Step size değişiyor 
% Rayleigh

% 4 değişken var
% monte ,  node sayısı (node_min ve node_max değiştirilerek belirlenebilir) , monte değişkeni(tavsiye edilen değer en az: 1e4), SNR

clear; clc; close all;dbstop if error;
%% Defining the System
p = 1; %Signal power 
monte_counter = 0;
counter = 0;
nodes = 4 ;
N = nodes^2 ;
MaxIt = 2000;
SNR = [1:1:20];
f1 = figure;
f2 = figure;
min_node = 3; 
max_node = 6;                               
Allowed_Error = 1/10000;  

%% This is for naming the data
number = [min_node:1:max_node]';
names = int2str(number);
for nodes = min_node:1:max_node
switch nodes
      case 3
          Measured = [-6 ; -3 ; 7];   
      case 4
          Measured = [-6 ; -3 ; 7 ; 14 ];
      case 5
          Measured = [-6 ; -3 ; 7 ; 14; 21];
      case 6
          Measured = [-6; -3; 7; 14; 21; -12.5];
      case 7
          Measured = [-6; -3; 7; 14; 17; -12.5; 8.5];
      case 8
          Measured = [-6; -3; 7; 14; 17; -12.5; 8.5; -9.5];
end   
    Edge_num = nchoosek(nodes,2);
IterMeasured = Measured;
%% Calculating Average
sz = size(Measured);
Mysum = sum(Measured);
Average = Mysum/sz(1);
%% Starting to Monte Carlo
montemax = 1e4;                           %how many times monte carlo                         
L_Networks = zeros(montemax,nodes,nodes); %this is L matrix container
Ranks = zeros(montemax,6);                %this will keep everything about matrices
for SNR_counter = 1:length(SNR)      %(SNR conuter kullanılmasın) 
for monte = 1:montemax
    % *** data rate bölümü başlangıcı ***
     R = 1 ;                            % Data rate = 1 alindi
     gama = 10^(SNR(SNR_counter)/10);                % Bu threshold tamamen Kimon'un formülüne göre belirlendi, detay bilmiyorum.
     threshold = (2^R - 1) / gama ;
    % *** data rate bölümü bitişi ***
     StateContainer = zeros(size(Measured,1), MaxIt + 1 ); %for every monte, this will keep states
     
     StateContainer(:,1) = Measured(:); %içine alamýyor tranpoz sorunu
     
     FeedbackContainer = zeros(MaxIt,size(Measured,2));   %for every monte this will keep feedbacks
     
     h_edge = randn(1,Edge_num) + 1i*randn(1,Edge_num); %assign values for every edge
     Edge_con = abs(h_edge).^2 > threshold ;
      
     
     [ii,jj] = ndgrid(1:nodes);              % Used to choose the upper triangle of The Matrix
      A = zeros(nodes);                       % Adjacency Matrix's for all
      A(jj>ii) =  Edge_con;                   % Filling the upper Triangle
     
      Ranks(monte,6) = sum(sum(A));
      A = A + A';                             % Adjacency Matrix created
      D = diag(sum(A));                       % In-Degree Matrix created  
      L = D - A ;                             % Laplacian Matrix
           
      L_Networks(monte,:,:) = L ; %her bir monte deðiþkeni birer L A ve D oluþturacak

     
      Ranks(monte,1) = rank(L) ;  %her bir monte deðiþkeni için matrix rank toplamaca

      
      %% Now let's start iterating for every matrix in monte carlo
      
      if rank(L) == nodes - 1 %bu saðlanmýyorsa alphaya ulaþýlamadý ranks5 = 0
      d = max(max(D));
      epsilon_max = (1/d); %determining maximum step size
      epsilon = epsilon_max /1; %choosing the step size 
      %% step size dýþarý
      Ranks(monte,4) = 1; %we can reach alpha,consensus
      monte_counter = monte_counter + 1;
      
      for k = 1:MaxIt

      P_epsilon = eye(nodes) - epsilon * L;
      IterMeasured = P_epsilon * IterMeasured;  
      StateContainer(1:end,k) = IterMeasured(1:end);
      %% Defining an Error Rule
      if max(IterMeasured) - min(IterMeasured) > Allowed_Error 
      counter = counter + 1;
      else
          Ranks(monte,5) = counter;
          IterMeasured = Measured;
          counter = 0;
          break 
      end
      
      end
      
      else
      Ranks(monte,4) = 0;
      end
      
end
%% Calculating the Probabilities of Ranks

   Average_It_per_SNR = sum(Ranks(:,5))/sum(Ranks(:,4));
   Average_It_Container(1,SNR_counter) = Average_It_per_SNR;
   Succ_Probability = sum(Ranks(:,4)) / montemax;
   Probability_Container(1,SNR_counter) =  Succ_Probability;
   
end
figure(f1);
hold on;
semilogy(SNR,Probability_Container,'x -');
legend(names);
title('Propability of Reaching Consensus vs. Different SNR');

figure(f2);
hold on;
semilogy(SNR,Average_It_Container,'x -');
legend(names);
title('Average Number of Iterations vs. Different SNR');
end
