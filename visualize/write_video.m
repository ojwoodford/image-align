%WRITE_VIDEO

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function write_video(ims, fname)
h = VideoWriter(fname, 'MPEG-4');
open(h);
for f = 1:ims.num_frames()
    writeVideo(h, ims(f));
end
close(h);
end
