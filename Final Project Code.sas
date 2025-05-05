proc import out=heart  datafile="/home/u63735895/heart.xlsx"
dbms=xlsx replace;
run;

/* Calculate percentages for positive heart disease cases for each categorical feature */
proc freq data=heart;
  tables sex;
run;

proc freq data=heart(where=(HeartDisease=1));
    tables Sex / out=sex_counts;
run;

proc freq data=heart(where=(HeartDisease=1));
    tables ChestPainType / out=cp_counts;
run;

proc freq data=heart(where=(HeartDisease=1));
    tables FastingBS / out=fbs_counts;
run;

proc freq data=heart(where=(HeartDisease=1));
    tables RestingECG / out=restecg_counts;
run;


proc freq data=heart(where=(HeartDisease=1));
    tables ExerciseAngina / out=exang_counts;
run;

proc freq data=heart(where=(HeartDisease=1));
    tables ST_Slope / out=slope_counts;
run;

/* Step 3: Create the plot */
PROC SGPLOT DATA=heart;
    VBAR Sex / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    TITLE 'Heart Disease Distribution Based on Gender';
RUN;

PROC SGPLOT DATA=heart;
    VBAR Age / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    xaxis values=(30 to 77 by 1);
    TITLE 'Heart Disease Distribution Based on Age';
RUN;

PROC SGPLOT DATA=heart;
    VBAR ChestPainType / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    TITLE 'Heart Disease Distribution Based on Chest Pain Type';
RUN;

PROC SGPLOT DATA=heart;
    VBAR RestingECG / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    TITLE 'Heart Disease Distribution Based on Resting ECG';
RUN;

PROC SGPLOT DATA=heart;
    VBAR ExerciseAngina / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    yaxis values=(0 to 350 by 50);
    TITLE 'Heart Disease Distribution Based on Exercise Angina';
RUN;

PROC SGPLOT DATA=heart;
    VBAR ST_Slope / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    yaxis values=(0 to 400 by 50);
    TITLE 'Heart Disease Distribution Based on ST Slope';
RUN;

PROC SGPLOT DATA=heart;
    VBAR FastingBS / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    TITLE 'Heart Disease Distribution Based on Fasting BS';
RUN;

PROC SGPLOT DATA=heart;
    VBAR RestingBP / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    xaxis values=(0 to 200 by 10);
    yaxis values=(0 to 100 by 10);
    TITLE 'Heart Disease Distribution Based on Resting BP';
RUN;

PROC SGPLOT DATA=heart;
    VBAR MaxHR / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    xaxis values=(80 to 200 by 5);
    TITLE 'Heart Disease Distribution Based on Max HR';
RUN;

PROC SGPLOT DATA=heart;
    VBAR Oldpeak / GROUP=HeartDisease GROUPDISPLAY=CLUSTER;
    xaxis values=(-0.2 to 6.2 by 0.3);
    yaxis values=(0 to 100 by 5);
    TITLE 'Heart Disease Distribution Based on Old peak';
RUN;

/* Calculate correlation matrix */
proc corr data=heart;
    var Age RestingBP Cholesterol FastingBS MaxHR Oldpeak HeartDisease;
run;

/* Building a regression model  */
proc surveyselect data=heart samprate=0.8 method=srs out=heart_part outall seed=12345;
run;

data heart_train heart_val;
        set heart_part;
        if selected=1 then output heart_train; else output heart_val;
run;

/* Perform variable selection using HPREG */
proc hpreg  data=heart seed=12345;
    partition fraction(validate=0.3);
    model HeartDisease = Age RestingBP Cholesterol FastingBS MaxHR Oldpeak;
    selection method=stepwise(choose=validate);
run;

/* Decision Tree*/
proc hpsplit data=heart nodes=detail;
        class HeartDisease OldPeak FastingBS; /* Includes all the categorical variables */
        model HeartDisease(event="1")= Age RestingBP Cholesterol FastingBS MaxHR Oldpeak;
        partition fraction(validate=.3 seed=12345);
        grow gini;
        prune cc;
run;

/* Neural Network */
proc hpneural data=heart;
    partition fraction(validate=0.2 seed=12345);
    target HeartDisease/ level=nom; /* categorical target variable */
    input Sex ChestPainType RestingECG ExerciseAngina ST_Slope/level=nom;
    input Age RestingBP Cholesterol FastingBS MaxHR Oldpeak/ level=int; /* continuous predictors */
    hidden 11; /* first hidden layer with 11 neurons */
    train maxiter=1000 numtries=5;
run;

/* Logistic Rgression */
proc logistic data=heart;
	model HeartDisease(event="1")=Age RestingBP Cholesterol FastingBS MaxHR Oldpeak;
run;

proc surveyselect data=heart samprate=0.6 method=srs outall out=heart_part seed=12345;
run;

data heart_train heart_valid;
	set heart_part;
	if selected=1 then output heart_train; else output heart_valid;
run;

proc logistic data=heart_train outmodel=heart_model;
	model HeartDisease(event="1")=Age RestingBP Cholesterol FastingBS MaxHR Oldpeak;
run;

proc logistic inmodel=heart_model;
	score data=heart_train fitstat;
run;

proc logistic inmodel=heart_model;
	score data=heart_valid fitstat;
run;






























































