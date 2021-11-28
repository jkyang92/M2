#!/usr/bin/env python3

# Copyright (c) Jay Yang 2021
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted.

#
# Intended to be used with the -memlog option on scc1
# after compiling with -memlog, and optionally setting the
# output to some other file (see the alloc_log_file variable)
# this script can take the output and generate data to
# plot the memory usage per type as a function of time.
# Note that this currently only plots number of objects of each
# type and not actual memory usage in bytes
#

import re
import sys
import os
import gzip

if len(sys.argv)<3:
    print("Please provide a log file and an output filename");
    exit(1);
logfile = sys.argv[1];
datfile = sys.argv[2];

lines = []

typeNames = {}

allocPat = re.compile("A (0x[0-9a-fA-F]*) (.*)");
freePat = re.compile("F (0x[0-9a-fA-F]*)");

#find all typenames

def openLog(name):
    if os.path.splitext(logfile)[1]==".gz":
        return gzip.open(logfile,"rt");
    else:
        return open(logfile,"r");

for line in openLog(logfile):
    allocMatch = allocPat.match(line);
    if allocMatch:
        typename = allocMatch.group(2);
        if typename not in typeNames:
            typeNames[typename] = typename;

print("TYPES READ");

objTable = {}

typeNameList = list(typeNames.values())
typeTable = {t:0 for t in typeNameList}


def parseLine(line):
    allocMatch = allocPat.match(line);
    if allocMatch:
        addr = int(allocMatch.group(1),16);
        typename = allocMatch.group(2);
        typename = typeNames[typename];
        return (addr,typename);
    else:
        freeMatch = freePat.match(line);
        if freeMatch:
            addr = int(freeMatch.group(1),16);
            return (addr,);
        else:
            print("WARNING: Unparsable line");
            print(line);
            return None;


def writeData(allocCount,out):
    out.write(" ".join([str(allocCount)]+
                       [str(typeTable[t]) for t in typeNameList]));
    out.write("\n");

with open(datfile,"w") as out:
    out.write(" ".join(["allocNum"] + typeNameList));
    out.write("\n");
    allocCount = 0;
    for line in openLog(logfile):
        info = parseLine(line);
        if info==None:
            continue;
        elif len(info)==1:
            typeTable[objTable[info[0]]] -= 1;
            del objTable[info[0]];
        elif len(info)==2:
            typeTable[info[1]] += 1;
            objTable[info[0]] = info[1];
            allocCount += 1;
            if allocCount % 1000 == 0:
                writeData(allocCount,out);
    if allocCount % 1000 != 0:
        writeData(allocCount,out);

                
print(len(objTable));
#By Type
typeTable = {}
for t in objTable.values():
    if t in typeTable:
        typeTable[t] += 1;
    else:
        typeTable[t] = 1;
for k,v in typeTable.items():
    print("{} {}".format(k,v));
