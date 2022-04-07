clc;

%% Define Directory and Files
DatasetFold = ['Z:\VSD_EEG_motion\Data\Participant_EEG_data\P12 Analysis\P12 DiffWaves\'];

Filenames ={'NinetyFiveGrandAverageP1-12DiffWavesTA-NTA_Raw_Data.mat','NinetyFiveGrandAverageP1-12DiffWavesTA-NTA_Sum_Upper_Limit_Diff_Waves_TA-NTA.mat','NinetyFiveGrandAverageP1-12DiffWavesTA-NTA_Diff._Waves_Lower_Limit_Diff_Waves_TA-NTA.mat';
            'NinetyFiveGrandAverageP1-12DiffWavesTS-NTS_Raw_Data.mat','NinetyFiveGrandAverageP1-12DiffWavesTS-NTS_Sum_Upper_Limit_Diff_Waves_TS-NTS.mat','NinetyFiveGrandAverageP1-12DiffWavesTS-NTS_Diff._Waves_Lower_Limit_Diff_Waves_TS-NTS.mat'};
  
%% Import Files into PtSegments
Paradigms = {'TA-NTA', 'TS-NTS'};
BaselineDuration = 0.2; % Baseline correction (in seconds)
PtSegments = {};

for i = 1:length(Paradigms)
    for j = 1:3 %j = 1 -> GrandAverage, j=2 -> Upperlimit, j=3 -> Lowerlimit
        
        tmpfileAdd = [DatasetFold Filenames{i,j}];
        [PtSegments{i,j}, Labels, Fs, ChannInfo] = ImportingBCIData(tmpfileAdd);
    end
end

%% Plotting 95% CI figures
ymin = -10; %Sets cutoff on y-axis of plot
ymax = 10;

xlabelmin = -200; %Does not trim plot only re-labels x-axis. The program plots all x values using the range defined within brainvision when you do the segmentation transformation.
xlabelmax = 1000; %!!!Set the x label values to the segmentation values from brainvision!!!

ElectrodesOfInterest = {'P3','P4','P7','P8','PZ','OZ','O1','O2'};

ElecDict = containers.Map(...
    {'FP1', 'FZ', 'F3', 'F7', 'FT9', 'FC5', 'FC1', 'C3', 'T7', 'TP9', 'CP5', 'CP1', 'PZ',...
     'P3','P7','O1','OZ','O2','P4','P8','TP10','CP6','CP2','CZ','C4','T8','FT10','FC6','FC2','F4','F8','FP2'},...
    {'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12', '13',...
     '14','15','16','17','18','19','20','21','22','23','24','25','26','27','28','29','30','31','32'});
 
ElectrodesNum = {};

for n = 1:numel(ElectrodesOfInterest)
    ElectrodesNum{n} = str2num(ElecDict(ElectrodesOfInterest{n}));
end

for i = 1:length(ElectrodesNum)
    ElectrodIdx = ElectrodesNum{i};
    ElectrodeLabel = ChannInfo(ElectrodIdx).Name;

    figure
    Plot95CIAll(PtSegments, Paradigms, ElectrodIdx, ElectrodeLabel, BaselineDuration, Fs, ymin, ymax, xlabelmin, xlabelmax)
    set(gcf, 'Position', get(0, 'Screensize'))
    print(gcf, '-dtiff', '-r300', [ElectrodeLabel '-GrandAverages-95CIplot.tiff']); %Saves file to directory from which code is being run
    close all force
end

%% Done        
disp('---------DONE--------');

%% Functions

%Changing Structure BCI raw structure:
function [Segments, Labels, Fs, ChannInfo] = ImportingBCIData(Filename)
    load(Filename);

    Fs = SampleRate;
    Segments = zeros(SegmentCount,ChannelCount,length(t));
    Labels = cell(ChannelCount,1);
    for ch = 1:ChannelCount
        for Seg = 1:SegmentCount
            Segments(Seg,ch,:) = eval([Channels(ch).Name '(Seg,:)']);
        end
        Labels{ch} = Channels(ch).Name;
    end
    ChannInfo = Channels;
    Segments(:,33:end,:) = [];
end

function [] = Plot95CIAll(PtSegments,Paradigms,ElectrodIdx,ElectrodeLabel, BaselineDuration,Fs, ymin, ymax, xlabelmin, xlabelmax)
    FaceAlphaVal = 0.1; %Transparency
     
    GrandAverage = squeeze(PtSegments{1,1}); %This block prepares the shaded region for paradigm 1
    Upperlimit = squeeze(PtSegments{1,2});
    Lowerlimit = squeeze(PtSegments{1,3});

    t = 1:size(GrandAverage,2); % where t is the number of data points
    plot(t, GrandAverage(ElectrodIdx,:),'k','LineWidth',5)  %Number after 'LineWidth' is the line width of the grandaverage plot                                                                
    hold on
    patch([t, fliplr(t)], [Upperlimit(ElectrodIdx,:), fliplr(Lowerlimit(ElectrodIdx,:))], 'k', 'EdgeColor', 'none', 'FaceAlpha',FaceAlphaVal) %Uses upper and lower limits to add shaded region

    GrandAverage = squeeze(PtSegments{2,1}); %This block prepares the shaded region for paradigm 2
    Upperlimit = squeeze(PtSegments{2,2});
    Lowerlimit = squeeze(PtSegments{2,3});

    plot(t, GrandAverage(ElectrodIdx,:),'r','LineWidth',5)                                                                  
    hold on
    patch([t, fliplr(t)], [Upperlimit(ElectrodIdx,:), fliplr(Lowerlimit(ElectrodIdx,:))], 'r', 'EdgeColor', 'none', 'FaceAlpha',FaceAlphaVal)

    if length(Paradigms) == 3 %Triggered to be used with 3 paradigms
        GrandAverage = squeeze(PtSegments{3,1});
        Upperlimit = squeeze(PtSegments{3,2});
        Lowerlimit = squeeze(PtSegments{3,3});

        plot(t, GrandAverage(ElectrodIdx,:),'b','LineWidth',3)                                                                  
        hold on
        patch([t, fliplr(t)], [Upperlimit(ElectrodIdx,:), fliplr(Lowerlimit(ElectrodIdx,:))], 'b', 'EdgeColor', 'none', 'FaceAlpha',FaceAlphaVal)
        %legend(Paradigms) %Uncommnet to add a legend
    end
    
    ylim([ymin ymax])
    line([0 size(GrandAverage,2)],[0 0],'Color','k','LineStyle',':')
    tmpylim = get(gca,'ylim');
    line([BaselineDuration*Fs BaselineDuration*Fs],[tmpylim(1) tmpylim(2)],'Color','k','LineStyle',':') %Adds dashed lines at 0

    xlabel('Time (ms)', 'fontweight', 'bold', 'fontsize', 16) %Font for x-axis label
    ylabel('Amlitude (\muV)','Interpreter','tex', 'fontweight', 'bold', 'fontsize', 16) %Font for y-axis label
%     title(['Grand Average of ', ElectrodeLabel]); %Uncomment to add title to the plot
    set(gca,'XTick',[1 BaselineDuration*Fs:BaselineDuration*Fs:length(t)], 'XTickLabel',linspace(xlabelmin,xlabelmax,(((length(t)-BaselineDuration*Fs)/(BaselineDuration*Fs))+2)), 'FontWeight', 'bold', 'fontsize', 14) %Font for numbers on axes

end