% Quality control Q2
% Plot the segmented images in MNI space and plot the MNI template as a reference
% Check quality of anatomical image segmentation
% Modified for BIDS structure
clear

% Base BIDS directory
bids_root = '/Users/erdemtaskiran/Desktop/Depression/Depression';
subjfolder = dir([bids_root '/sub*']);

% Create output directory
output_dir = [bids_root '/QC_images/Q2_segmentation_check'];
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Get SPM template path
spm_template = [spm('Dir') '/canonical/single_subj_T1.nii'];

for subji = 1:length(subjfolder)
    fprintf('Processing segmentation check for subject %d (%s)...\n', subji, subjfolder(subji).name);
    
    subj_id = subjfolder(subji).name;
    
    % Check if segmentation files exist
    wc1_file = [bids_root '/' subj_id '/anat/wc1' subj_id '_T1w.nii'];
    wc2_file = [bids_root '/' subj_id '/anat/wc2' subj_id '_T1w.nii'];
    wc3_file = [bids_root '/' subj_id '/anat/wc3' subj_id '_T1w.nii'];
    
    if exist(wc1_file, 'file') && exist(wc2_file, 'file') && exist(wc3_file, 'file')
        
        % Create image array for spm_check_registration
        imgs = char(wc1_file, spm_template);
        
        % Plot the segmented gray matter and MNI template
        spm_check_registration(imgs);
        
        % Display the participant's ID
        spm_orthviews('Caption', 1, [subj_id ' - Gray Matter']);
        spm_orthviews('Caption', 2, 'single_subj_T1 (MNI)');
        
        % Display contour of 1st image onto 2nd
        spm_orthviews('contour','display',1,2);
        
        global st
        
        % Overlay gray matter (RED), white matter (GREEN), and CSF (BLUE) images
        
        % Gray Matter (RED)
        vol = spm_vol(wc1_file);
        mat = vol.mat;
        st.vols{1}.blobs = cell(1,1);
        bset = 1;
        st.vols{1}.blobs{bset} = struct('vol', vol, 'mat', mat, ...
            'max', 1, 'min', 0, 'colour', [1 0 0]);  % Red
       
        % White Matter (GREEN)
        vol = spm_vol(wc2_file);
        mat = vol.mat;
        bset = 2;
        st.vols{1}.blobs{bset} = struct('vol', vol, 'mat', mat, ...
            'max', 1, 'min', 0, 'colour', [0 1 0]);  % Green
        
        % CSF (BLUE)
        vol = spm_vol(wc3_file);
        mat = vol.mat;
        bset = 3;
        st.vols{1}.blobs{bset} = struct('vol', vol, 'mat', mat, ...
            'max', 1, 'min', 0, 'colour', [0 0 1]);  % Blue
        
        % Redraw with overlays
        spm_orthviews('Redraw');
        
        % Turn off crosshairs for cleaner image
        spm_orthviews('Xhairs', 'off');
        
        % Save the figure
        output_file = [output_dir '/' subj_id '.jpg'];
        spm_print(output_file, 'Graphics', 'jpg');
        
        fprintf('Saved: %s\n', output_file);
        
    else
        fprintf('Warning: Segmentation files not found for %s\n', subj_id);
        fprintf('  Expected files:\n');
        fprintf('    %s\n', wc1_file);
        fprintf('    %s\n', wc2_file);
        fprintf('    %s\n', wc3_file);
    end
end

fprintf('\nQ2 segmentation check completed!\n');
fprintf('Check images in: %s\n', output_dir);
fprintf('\nWhat to look for in the saved images:\n');
fprintf('- RED overlay: Gray matter segmentation\n');
fprintf('- GREEN overlay: White matter segmentation\n');
fprintf('- BLUE overlay: CSF segmentation\n');
fprintf('\nCheck for:\n');
fprintf('1. Proper tissue classification (GM in cortex, WM in center, CSF in ventricles)\n');
fprintf('2. No misclassification of tissues\n');
fprintf('3. Good spatial normalization to MNI template\n');
fprintf('4. No obvious segmentation failures\n');
fprintf('\nIf segmentation looks poor for any subject, consider excluding from analysis.\n');