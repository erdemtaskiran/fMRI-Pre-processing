% Quality control Q1c
% Plot the first functional image and check its initial position with reference to the MNI template
% Modified for BIDS structure
clear

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directory
output_dir = [bids_root '/QC_images/Q1c_func_check'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Get SPM template path
spm_template = [spm('Dir') '/canonical/single_subj_T1.nii'];

for subji = 1:length(subjfolder)
    fprintf('Processing functional check for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Get ALL functional files for this subject
    func_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-*_bold.nii.gz']);
    
    if isempty(func_files)
        % Try without .gz extension
        func_files = dir([bids_root '/' subj_id '/func/' subj_id '_task-*_bold.nii']);
    end
    
    if ~isempty(func_files)
        % Process each functional run
        for runi = 1:length(func_files)
            fprintf('  Processing run %d/%d: %s\n', runi, length(func_files), func_files(runi).name);
            
            func_path = [bids_root '/' subj_id '/func/' func_files(runi).name];
            
            % Handle compressed files
            if endsWith(func_path, '.gz')
                temp_func = gunzip(func_path);
                func_path = temp_func{1};
                cleanup = true;
            else
                cleanup = false;
            end
            
            % Add ,1 to specify first volume of the 4D functional image
            func_first_vol = [func_path ',1'];
            
            % Create image array for spm_check_registration
            imgs = char(func_first_vol, spm_template);
            
            % Plot the two images using Check Registration 
            spm_check_registration(imgs);
            
            % Extract run info from filename for caption
            [~, filename, ~] = fileparts(func_files(runi).name);
            if endsWith(filename, '.nii')
                filename = filename(1:end-4);
            end
            
            % Display the participant's ID and run info
            spm_orthviews('Caption', 1, [subj_id ' - ' filename]);
            spm_orthviews('Caption', 2, 'single_subj_T1 (MNI)');
            
            % Display contour of 1st image onto 2nd
            spm_orthviews('contour','display',1,2);
            
            % Save the figure with run-specific filename
            output_file = [output_dir '/' subj_id '_' filename '.jpg'];
            spm_print(output_file, 'Graphics', 'jpg');
            
            % Clean up temporary file if needed
            if cleanup && exist(func_path, 'file')
                delete(func_path);
            end
            
            fprintf('  Saved: %s\n', output_file);
        end
    else
        fprintf('Warning: No functional files found for %s\n', subj_id);
    end
end

fprintf('\nQ1c functional check completed!\n');
fprintf('Check images in: %s\n', output_dir);
fprintf('Look for: (1) Orientation vs template (2) Artifacts/ghosting (3) Spatial coverage (4) Signal dropouts\n');