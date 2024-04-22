******************************************************************************************************************************************
Adjusted Z-scores for NP summary scores
******************************************************************************************************************************************

Last updated: April 2024


The purpose of this SAS code is to allow users to create adjusted Z-scores (age and gender) for NP summary scores.
Please ensure you have the listed dataset(s) to run this SAS code optimally. It is highly recommended to have them in the same location.

Generic names are used for the datasets within this SAS code. 
Tip: You can copy and paste this SAS code onto a Word document and use the "find and replace" function to customize to your dataset names 

1)  np_summary_through2022_18053 (NP Summary Scores)


*Provide the location of these datasets to import from before you run the SAS code. ;
libname in1 'C:\Users\angtf\Desktop\Test_SAS\Input_data';
*Provide the location of the derived datasets to export to before you run the SAS code. ;
libname out1 'C:\Users\angtf\Desktop\Test_SAS\Output_data';


/*This macro requires you to first identify a subset of participants and assign them using the variable group. 
You can also use the variable ID instead if you want to get the Z-score for a specific participant*/

/*In this example, participants are assigned to group based on employment status*/

data np_summary; 
set in1.np_summary_through2022_18053;
if employment in (0,1,6,10,11) then group = 1;
else if employment in (2,3,4,5) then group = 2; 
else group = 3;
run;

%macro CalculateZScores(DV);
  /* Fit the Linear Regression Model */
  PROC REG DATA=np_summary;
    MODEL &DV = age sex educg;
    OUTPUT OUT=RegResults PREDICTED=Pred&DV RESIDUAL=Residuals&DV;
  RUN;

  /* Calculate Adjusted Z-Scores */
  PROC SQL;
    CREATE TABLE YourDataWithZScores AS
    SELECT *,
           (Residuals&DV - MEAN(Residuals&DV)) / STD(Residuals&DV) AS Adjusted_Z_Score&DV
    FROM RegResults;
  QUIT;

  /* Filter the dataset to select participants in a specific group
  You can also use the variable ID instead if you want to get the Z-score for a specific participant*/
DATA GroupData&DV;
    SET YourDataWithZScores;
    WHERE Group = 2; /* Change this to the appropriate filter condition */
  RUN;

  /* Calculate the mean and standard deviation of Z-scores the specific group */
  PROC SQL;
    SELECT MEAN(Adjusted_Z_Score&DV) AS Mean_Z_Score&DV,
           STD(Adjusted_Z_Score&DV) AS StdDev_Z_Score&DV
    FROM GroupData&DV;
  QUIT;
%mend;

/* Example of using the macro for different dependent variables */
%CalculateZScores(LMi);
%CalculateZScores(LMd);
%CalculateZScores(VRi);
%CalculateZScores(VRd);
%CalculateZScores(PASi);
%CalculateZScores(PASd);
%CalculateZScores(DSF);
%CalculateZScores(DSB);
%CalculateZScores(BNT30);
%CalculateZScores(FAS);
%CalculateZScores(FAS_Animal);
%CalculateZScores(HVOT);
