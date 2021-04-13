#!/bin/bash

restoreFile=$1
storageAccount=$2
shareName=$3

mkdir -p restore
rm -rf restore/*

tar -xzvf "${restoreFile}" -C restore

az storage remove --account-name "${storageAccount}" -s "${shareName}" -p worlds --recursive
az storage copy -s "./restore/*" --destination-account-name "${storageAccount}" --destination-share "${shareName}" --recursive

rm -rf restore
