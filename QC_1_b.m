% Quality control Q1b
% Plot the anatomical image and check its initial position with reference to the MNI template
% Modified for BIDS structure
clear

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directory
output_dir = [bids_root '/QC_images/Q1b_anat_check'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Get SPM template path
spm_template = [spm('Dir') '/canonical/single_subj_T1.nii'];

for subji = 1:length(subjfolder)
    fprintf('Processing anatomical check for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Get anatomical file path
    anat_path = [bids_root '/' subj_id '/anat/' subj_id '_T1w.nii.gz'];
    
    % Check if compressed file exists, if not try uncompressed
    if ~exist(anat_path, 'file')
        anat_path = [bids_root '/' subj_id '/anat/' subj_id '_T1w.nii'];
    end
    
    if exist(anat_path, 'file')
        % Handle compressed files
        if endsWith(anat_path, '.gz')
            temp_anat = gunzip(anat_path);
            anat_path = temp_anat{1};
            cleanup = true;
        else
            cleanup = false;
        end
        
        % Create image array for spm_check_registration
        imgs = char(anat_path, spm_template);
        
        % Plot the two images using Check Registration 
        spm_check_registration(imgs);
        
        % Display the participant's ID
        spm_orthviews('Caption', 1, subj_id);
        spm_orthviews('Caption', 2, 'single_subj_T1 (MNI)');
        
        % Display contour of 1st image onto 2nd
        spm_orthviews('contour','display',1,2);
        
        % Save the figure
        output_file = [output_dir '/' subj_id '.jpg'];
        spm_print(output_file, 'Graphics', 'jpg');
        
        % Clean up temporary file if needed
        if cleanup && exist(anat_path, 'file')
            delete(anat_path);
        end
        
        fprintf('Saved: %s\n', output_file);
    else
        fprintf('Warning: No anatomical file found for %s\n', subj_id);
    end
end

fprintf('\nQ1b anatomical check completed!\n');
fprintf('Check images in: %s\n', output_dir);
fprintf('Look for: (1) Orientation vs template (2) Artifacts/ghosting (3) Brain lesions (4) Coverage\n');