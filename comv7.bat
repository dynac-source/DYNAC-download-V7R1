gcc -c cgof.cc

gfortran -c -g -Wall -fno-automatic dynacv7.f90

gfortran -O -o ../bin/dynacv7 dynacv7.o cgof.o -lstdc++ -lcomdlg32
