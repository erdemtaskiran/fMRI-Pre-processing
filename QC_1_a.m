% Quality control Q1a
% Check imaging parameters and plot them across all the participants
% Modified for BIDS structure
clear

bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

run_counter = 0;

% Read image information for every participant
for subji = 1:length(subjfolder)
    fprintf('Processing subject %d ...',subji)
    
    subj_id = subjfolder(subji).name;
    
    % Get all functional runs
    func_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-*_bold.nii.gz']);
    
    for runi = 1:length(func_files)
        run_counter = run_counter + 1;
        
        func_path = [bids_root '/' subj_id '/func/' func_files(runi).name];
        
        % Unzip if needed
        if endsWith(func_path, '.gz')
            temp_func = gunzip(func_path);
            func_path = temp_func{1};
            cleanup = true;
        else
            cleanup = false;
        end
        
        v_func = spm_vol(func_path);
        
        n_image(run_counter,1) = length(v_func);
        tr(run_counter,1) = v_func(1).private.timing.tspace;
        di = spm_imatrix(v_func(1).mat);
        voxel_func(run_counter,:) = abs(di(7:9));
        
        if cleanup
            delete(func_path);
        end
    end
    
    % Anatomical
    anat_path = [bids_root '/' subj_id '/anat/' subj_id '_T1w.nii.gz'];
    
    % Unzip anatomical if needed
    if endsWith(anat_path, '.gz')
        temp_anat = gunzip(anat_path);
        anat_path = temp_anat{1};
        cleanup_anat = true;
    else
        cleanup_anat = false;
    end
    
    v_anat = spm_vol(anat_path);
    di = spm_imatrix(v_anat(1).mat);
    voxel_anat(subji,:) = abs(di(7:9));
    
    if cleanup_anat
        delete(anat_path);
    end
    
    fprintf('done!\n')
end

% Plot all the parameters across participants
fh = figure('DefaultAxesFontSize',18, 'Visible', 'off');
set(fh, 'Position', [100, 100, 1200, 800]);

% Calculate boundaries for subjects (5 runs per subject)
n_subjects = length(subjfolder);
boundaries = 5.5:5:(n_subjects*5);
centers = 3:5:(n_subjects*5);

subplot(4,1,1)
bar(n_image)
title('# of fMRI images')
if length(boundaries) > 1
    xline(boundaries(1:end-1));
end
xticks(centers)
for i = 1:n_subjects
    labels{i} = sprintf('Sub%d', i);
end
xticklabels(labels)
box off

subplot(4,1,2)
bar(tr)
title('TR of fMRI images')
if length(boundaries) > 1
    xline(boundaries(1:end-1));
end
xticks(centers)
xticklabels(labels)
box off

subplot(4,1,3)
bar(voxel_func)
title('Voxel sizes of fMRI images')
if length(boundaries) > 1
    xline(boundaries(1:end-1));
end
xticks(centers)
xticklabels(labels)
box off

subplot(4,1,4)
bar(voxel_anat)
title('Voxel sizes of structural images')
xticks(1:n_subjects)
xticklabels(labels)
box off

% Create output directory
output_dir = [bids_root '/QC_images'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Save the figure
try
    exportgraphics(fh, [output_dir '/Q1a_scanning_parameters.jpg'], 'Resolution', 300);
    fprintf('Figure saved successfully!\n');
catch
    print(fh, [output_dir '/Q1a_scanning_parameters.jpg'], '-djpeg', '-r300');
    fprintf('Figure saved using alternative method!\n');
end

% Close figure to free memory
close(fh);