******************************************************************************************************************************************
Petersen-Winblad and Mark-Bondi criteria
******************************************************************************************************************************************

Last updated: April 2024


The purpose of this SAS code is to allow users to create adjusted Z-scores (age, gender education) for NP summary scores.
Please ensure you have the listed dataset(s) to run this SAS code optimally. It is highly recommended to have them in the same location.

Generic names are used for the datasets within this SAS code. 
Tip: You can copy and paste this SAS code onto a Word document and use the "find and replace" function to customize to your dataset names

1)  np_summary_through2022_18053 (NP Summary Scores)


/*Provide the location of these datasets to import from before you run the SAS code.*/ ;
libname in1 'C:\Users\angtf\Desktop\Test_SAS\Input_data';
/*Provide the location of the derived datasets to export to before you run the SAS code.*/ ;
libname out1 'C:\Users\angtf\Desktop\Test_SAS\Output_data';


/*This macro requires you to first identify the specific cohort of FHS participants*/

******************************************************************************************************************************************
Residuals calculation using linear regression: Age + Age^2 + Educg 
******************************************************************************************************************************************;

data np_criteria; 
set in1.np_summary_through2022_18053; 
agesq = age*age;
/*In this example, Gen 2 participants are selected*/
if idtype = 1;
/*Log-transformation of the following NP summary scores*/
if trailsa in (.,0) then ltra=.; 
else ltra=log(trailsa);
if trailsb in (.,0) then ltrb=.;
else ltrb=log(trailsb);
if bnt30 in (.,0) then lbnt30=.;
else lbnt30=log(bnt30);
if hvot in (.,0) then lhvot=.;
else lhvot=log(hvot);
run; 

%macro educg_criteria(y);

/*Calculate residuals based on Age + Age^2 + Educg*/
/*You can use WRAT instead of educg for education covariate, please adjust the code accordingly*/ 
proc glm data=np_criteria;
class educg;
model &y=age agesq educg;
output out=resid residual=resid_&y;
run;
proc means data=resid mean std ;
var resid_&y;
output out=rstat_&y mean=mean_resid_&y std=std_resid_&y;
run;
data rstat2_&y;
set rstat_&y (drop= _type_ _freq_);
idtype = 1;
run;


/*Derived measures for Petersen-Winblad and Mark-Bondi criteria*/
data resid2_&y;
merge resid (keep=id idtype examdate resid_&y) rstat2_&y ;
by idtype;
z_resid_&y=((resid_&y - mean_resid_&y)/std_resid_&y);
if .<z_resid_&y<-1.5 then z_resid_&y._lt15=1;
else if z_resid_&y>=-1.5 then z_resid_&y._lt15=0;
if .<z_resid_&y<-1.0 then z_resid_&y._lt10=1;
else if z_resid_&y>=-1.0 then z_resid_&y._lt10=0;
if .<z_resid_&y<-2.0 then z_resid_&y._lt20=1;
else if z_resid_&y>=-2.0 then z_resid_&y._lt20=0;
run;

proc sort data=resid2_&y;
by idtype id examdate;
run;

%mend;


/* Example of using the macro for different NP summary scores*/
%educg_criteria(LMd);
%educg_criteria(LMr);
%educg_criteria(ltra);
%educg_criteria(ltrb);
%educg_criteria(lbnt30);
%educg_criteria(Sim);
%educg_criteria(lhvot);
%educg_criteria(vrd);
%educg_criteria(vrr);


/*Merging all residuals into one dataset*/

data resid_eudcg_all; 
merge resid2_LMd resid2_LMr resid2_ltra resid2_ltrb resid2_lbnt30 resid2_sim resid2_lhvot resid2_vrd resid2_vrr;
by idtype id examdate; 
run; 


******************************************************************************************************************************************
Petersen-Winblad criteria
******************************************************************************************************************************************;

/*1. Cognitive measure impairment*/
/*age/education group cutoffs*/
data resid_eudcg_pw_all;
set resid_eudcg_all;  
pw_lmd_i=z_resid_lmd_lt15;
pw_lmr_i=z_resid_lmr_lt15;
pw_ltra_i=z_resid_ltra_lt15;
pw_ltrb_i=z_resid_ltrb_lt15;
pw_lbnt30_i=z_resid_lbnt30_lt15; 
pw_sim_i=z_resid_sim_lt15;
pw_lhvot_i=z_resid_lhvot_lt15; 
pw_vrd_i=z_resid_vrd_lt15;
pw_vrr_i=z_resid_vrr_lt15;
pw_sum_mem_i=sum(z_resid_lmd_lt15, z_resid_lmr_lt15, z_resid_vrd_lt15,z_resid_vrr_lt15);
 

/* 2. Domain impairment*/
/*age/education group cutoffs*/
if pw_sum_mem_i>=1 then pw_mem_i=1;						/*Visual/verbal memory*/
if pw_sum_mem_i =0 then pw_mem_i=0;
if pw_ltra_i=1 or pw_ltrb_i=1 then pw_execf_i=1;		/*Executive function/attention*/
if pw_ltra_i=0 and pw_ltrb_i=0 then pw_execf_i=0;
if pw_lbnt30_i=1 or pw_sim_i=1 then pw_lang_i=1;		/*Language*/
if pw_lbnt30_i=0 and pw_sim_i=0 then pw_lang_i=0;


/*3. overall MCI*/
if pw_lmd_i=1 or pw_lmr_i=1 or pw_vrd_i=1 or pw_vrr_i=1 or pw_ltra_i=1 or pw_ltrb_i=1 or pw_lbnt30_i=1 or pw_sim_i=1 then pw_mci=1;
else pw_mci=0;


/*4. single domain amnestic*/
if pw_mem_i=1 and pw_execf_i=0 and pw_lang_i=0 then pw_mci_sdam=1;
else pw_mci_sdam=0;



/*5. multi-domain amnestic*/
if pw_mem_i=1 and (pw_execf_i=1 or pw_lang_i=1) then pw_mci_mdam=1;
else pw_mci_mdam=0;



/*6. single domain non-amnestic*/
pw_dsum=sum(of pw_execf_i pw_lang_i);

if pw_mem_i=0 and pw_dsum=1 then pw_mci_sdnam=1;
else pw_mci_sdnam=0;



/*6. multi domain non-amnestic*/
if pw_mem_i=0 and pw_dsum>1 then pw_mci_mdnam=1;
else pw_mci_mdnam=0;

run; 



******************************************************************************************************************************************
Mark-Bondi criteria
******************************************************************************************************************************************;


/*1. Cognitive measure impairment*/
/*age/education group cutoffs*/
data resid_eudcg_mb_all;
set resid_eudcg_all;  
jak_lmd_i=z_resid_lmd_lt10;
jak_lmr_i=z_resid_lmr_lt10;
jak_ltra_i=z_resid_ltra_lt10;
jak_ltrb_i=z_resid_ltrb_lt10;
jak_lbnt30_i=z_resid_lbnt30_lt10; 
jak_sim_i=z_resid_sim_lt10;
jak_lhvot_i=z_resid_lhvot_lt10; 
jak_vrd_i=z_resid_vrd_lt10;
jak_vrr_i=z_resid_vrr_lt10;
jak_sum_mem_i=sum(z_resid_lmd_lt10, z_resid_lmr_lt10, z_resid_vrd_lt10,z_resid_vrr_lt10);


/* 2. Domain impairment*/
/*age/education group cutoffs*/
	/*Visual/verbal memory*/

if jak_sum_mem_i>=2 then jak_mem_i=1;					
if jak_sum_mem_i in (0,1) then jak_mem_i=0;

/*Executive function/attention*/
if jak_ltra_i=1 and jak_ltrb_i=1 then jak_execf_i=1;		
else jak_execf_i=0;

/*Language*/
if jak_lbnt30_i=1 and jak_sim_i=1 then jak_lang_i=1;		
else jak_lang_i=0;


/*3. Overall mci*/
if jak_mem_i=1 or jak_execf_i=1 or jak_lang_i=1 then jak_mci=1;
else jak_mci=0;



/*4. single domain amnestic*/
if jak_mem_i=1 and jak_execf_i=0 and jak_lang_i=0 then jak_mci_sdam=1;
else jak_mci_sdam=0;


/*5. multi-domain amnestic*/
if jak_mem_i=1 and (jak_execf_i=1 or jak_lang_i=1) then jak_mci_mdam=1;
else jak_mci_mdam=0;



/*6. single domain non-amnestic*/
jak_dsum=sum(of jak_execf_i jak_lang_i);

if jak_mem_i=0 and jak_dsum=1 then jak_mci_sdnam=1;
else jak_mci_sdnam=0;



/*6. multi domain non-amnestic*/
if jak_mem_i=0 and jak_dsum>1 then jak_mci_mdnam=1;
else jak_mci_mdnam=0;

run;


