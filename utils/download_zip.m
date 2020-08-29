%DOWNLOAD_ZIP

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

function download_zip(varargin)
tname = tempname();
co = onCleanup(@() delete_dir(tname));
mkdir(tname);
try
    download_zip_(tname, varargin{:});
catch me
    warning(getReport(me));
end
end

function download_zip_(tname, name, ext, url)
base = cd();
temp_cd(tname);
options = weboptions('Timeout', 60, 'ContentType', 'raw');
websave(['temp.' ext], url, options);
try
    unpack(ext, name);
catch
    % Maybe we require a token
    delete(['temp.' ext]);
    % Read again, collecting cookies
    [str, cookies] = webread(http_session('ConnectTimeout', 20), url);
    % Add the confirmation token to the URL
    token = regexp(str, 'confirm=(\w+)&', 'tokens');
    d = find(url == '&', 1, 'first');
    url = sprintf('%sconfirm=%s&%s', url(1:d), token{1}{1}, url(d+1:end));
    % Add the cookies to the options
    cookies = cookies(arrayfun(@(a) ~isequal(char(a.Name), 'NID'), cookies)); % Remove the NID cookie
    cookies = matlab.net.http.field.CookieField(cookies);
    options = weboptions('KeyName', 'Cookie', 'KeyValue', char(cookies.Value));
    options.Timeout = 20;
    options.ContentType = 'raw';
    % Read again
    websave(['temp.' ext], url, options);
    unpack(ext, name);
end
delete(['temp.' ext]);
if exist(name, 'dir')
    movefile(name, base);
else
    cd(base);
    movefile(tname, name);
end
end

function unpack(ext, name)
switch ext
    case 'zip'
        unzip('temp.zip');
    case 'tgz'
        gunzip('temp.tgz');
        untar('temp', name);
        delete('temp');
end
end

function delete_dir(tname)
if exist(tname, 'dir')
    rmdir(tname, 's');
end
end