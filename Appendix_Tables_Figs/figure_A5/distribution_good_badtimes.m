clear all
close all
clc

%% load data
load bzdata.mat  % this contains a subset of the variables from bz_oecd_data.csv
id =bzdata(:,1);

%%
for i=1:13 
    cid=find(id==i);
    vdata_i= bzdata(cid, :);
    vdata_i = vdata_i(19:end,:);  % in order to start data at 1978
    gdp(:,i)=vdata_i(:,6);
    cpi(:,i) =vdata_i(:,7);
    real_gdp(:,i)= log(gdp(:,i)./cpi(:,i));
    realgdp_growth(:,i)=(real_gdp(2:end,i)- real_gdp(1:end-1,i));
    unemp(:,i)=vdata_i(:,8);
    major_nodelay(:,i)= vdata_i(:,9);
    major_delay(:,i) =  vdata_i(:,10);
    growthsignmean(:,i)=sign(realgdp_growth(:,i)-nanmean(realgdp_growth(:,i)));
    growthsign(:,i)=sign(realgdp_growth(:,i));
    unempgapsign(:,i) = sign(unemp(:,i) - nanmean(unemp(:,i)));
    oecd_rec(:,i) = vdata_i(:,11);
            
end

%% calculate the share of reforms in each category
disp('major_nodelay, major_delay')

reformtype =cat(3, major_nodelay, major_delay);
for ii=1:2
refconsid=reformtype(:,:,ii); %Specify the type of reform we want to consider

[refconsidnzexp]=find(refconsid~=0 & oecd_rec ==0); %Find reform during expansion
[refconsidnzrec]=find(refconsid~=0 & oecd_rec ==1); %Find reform during OECD recession
percent_expansion(ii,:)= size(refconsidnzexp)/(size(refconsidnzexp)+size(refconsidnzrec))*100;
percent_recession(ii,:)=100-percent_expansion(ii,:);

[refconsidnzlowu]=find(refconsid~=0 & unempgapsign ==-1); 
[refconsidnzhighu]=find(refconsid~=0 &unempgapsign ==1); 
percent_lowunemp(ii,:)= size(refconsidnzlowu)/(size(refconsidnzlowu)+size(refconsidnzhighu))*100;
percent_highunemp(ii,:)=100-percent_lowunemp(ii,:);


refconsid=refconsid(2:end,:);
[refconsidnzp]=find(refconsid~=0 & growthsignmean ==1); %Find reform during high growth periods
[refconsidnzn]=find(refconsid~=0 & growthsignmean ==-1); %Find reform during low growth periods
percent_highgrowth(ii,:)= size(refconsidnzp)/(size(refconsidnzp)+size(refconsidnzn))*100;
percent_lowgrowth(ii,:)=100-percent_highgrowth(ii,:);


[refconsidnzp]=find(refconsid~=0 & growthsign >=0); %Find reform during positive growth periods
[refconsidnzn]=find(refconsid~=0 & growthsign<0); %Find reform during negative growth periods
percent_posgrowth(ii,:)= size(refconsidnzp)/(size(refconsidnzp)+size(refconsidnzn))*100;
percent_neggrowth(ii,:)=100-percent_posgrowth(ii,:);

end

% display underlying data for figure A5 (to be used in figure_A5.xlsx)
disp('Percent of reforms in good/bad times using growth rate of GDP above/below country mean')
[percent_highgrowth, percent_lowgrowth]'
disp('Percent of reforms in good/bad times using positive and negative growth rate of GDP ')
[percent_posgrowth, percent_neggrowth]'
disp('Percent of reforms in good/bad times using OECD recession indicator')
[percent_expansion, percent_recession]'
disp('Percent of reforms in good/bad times using unemployment below/above country mean')
[percent_lowunemp, percent_highunemp]'


%% plot figure A5 in matlab

chart_data = [percent_highgrowth(1) percent_lowgrowth(1);
    percent_highgrowth(2) percent_lowgrowth(2);
    percent_posgrowth(1) percent_neggrowth(1);
    percent_posgrowth(2) percent_neggrowth(2);
    percent_expansion(1) percent_recession(1);
    percent_expansion(2) percent_recession(2);
    percent_lowunemp(1) percent_highunemp(1);
    percent_lowunemp(2) percent_highunemp(2);];
bar(chart_data,'stack')

xt = get(gca, 'XTick');
set(gca, 'XTick', xt, 'XTickLabel', ...
    {'GDP growth high/low' 'GDP growth high/low' ...
    'GDP growth positive/negative' 'GDP growth positive/negative' ...
    'OECD expansion/recession' 'OECD expansion/recession' ...
    'Unemployment low/high' 'Unemployment low/high' ...
    })
ax = gca;
labels = string(ax.XAxis.TickLabels); % extract
labels(1:2:end-1) = nan; % remove every other one
ax.XAxis.TickLabels = labels; % set
