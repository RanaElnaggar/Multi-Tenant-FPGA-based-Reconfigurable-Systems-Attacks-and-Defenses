close all;
clear all;
clc;	

A=imread('OSE1cor_2.bmp');
%B=rgb2gray(A);
disp('Image file read successful');
figure,imshow(A),title('orginal image');
d=(A.');
fid = fopen('sobel_indoor.txt', 'wt');
fprintf(fid, '%d\n', d);
disp('Text file write done');disp(' ');
fclose(fid);

B=imread('sidewalk_174.bmp');
%B=rgb2gray(A);
disp('Image file read successful');
figure,imshow(B),title('orginal image');
d=(B.');
fid = fopen('gaussiasn_outdoor.txt', 'wt');
fprintf(fid, '%d\n', d);
disp('Text file write done');disp(' ');
fclose(fid);

