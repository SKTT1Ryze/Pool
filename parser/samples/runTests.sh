#! /bin/bash

function runTest {
  ./dcc <$1.decaf &>$1.run
  diff -w $1.run $1.out &>$1.diff
  if [ $? -eq 0 ] ;then
    echo "Test:" $1"; OK"
  else
    echo "Test:" $1"; WRONG"
  fi
}

#building...
cd ..
make clean
make
cd samples

#testing...
cp ../dcc .
runTest bad1
runTest bad2
runTest bad3
runTest bad4
runTest bad5
runTest bad6
runTest bad7
runTest class
runTest control
runTest expressions
runTest functions
runTest inheritance
runTest interface
runTest matrix
runTest simple
