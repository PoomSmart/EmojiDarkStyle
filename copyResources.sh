#!/bin/bash

if [ -z $1 ];then
  echo "Runtime version required"
  exit 1
fi

DS_RUNTIME_ROOT=/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS\ ${1}.simruntime/Contents/Resources/RuntimeRoot

sudo cp -v ${PWD}/layout/System/Library/Frameworks/UIKit.framework/*.png "${DS_RUNTIME_ROOT}/System/Library/Frameworks/UIKit.framework/"
