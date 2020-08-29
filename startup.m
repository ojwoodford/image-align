%STARTUP

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function startup()
% Reset the path
restoredefaultpath();
% Put this folder on the path
cd(fileparts(mfilename('fullpath')));
cd submodules/ojwul/utils
add_genpath_exclude('../../..', '/.git', '\.git', '/build', '\build');
cd ../../..
% Reset everything else
close all;
clc();
evalin('base', 'clear all');
dbclear all;
rng default;
end