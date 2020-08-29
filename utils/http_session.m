%HTTP_SESSION

% Copyright Snap Inc. 2020
% This sample code is made available by Snap Inc. for informational
% purposes only.  It is provided as-is, without warranty of any kind,
% express or implied, including any warranties of merchantability, fitness
% for a particular purpose, or non-infringement.  In no event will Snap
% Inc. be liable for any damages arising from the sample code or your use
% thereof.

classdef http_session < handle
    properties (SetAccess = private, Hidden = true)
        options;
        map;
    end
    methods
        function this = http_session(varargin)
            this.options = matlab.net.http.HTTPOptions(varargin{:});
            this.map = containers.Map();
        end
        
        function [data, cookies] = webread(this, url)
            uri = matlab.net.URI(url);
            host = char(uri.Host); % get Host from URI
            request = matlab.net.http.RequestMessage();
            try
                % Get info struct for host in map
                info = this.map(host);
                uri = info.uri;
                if ~isempty(info.cookies)
                    % If it has cookies, it means we previously received cookies from this host.
                    % Add Cookie header field containing all of them.
                    request = request.addFields(matlab.net.http.field.CookieField(info.cookies));
                end
            catch
                % A new host
                info = struct('cookies', [], 'uri', uri);
            end
            
            % Send request and get response and history of transaction.
            [response, ~, history] = request.send(uri, this.options);
            data = response.Body.Data;
            
            % Get the Set-Cookie header fields from response message in
            % each history record and save them in the map.
            cookies = info.cookies;
            for a = 1:numel(history)
                cookie = history(a).Response.getFields('Set-Cookie');
                if isempty(cookie)
                    continue;
                end
                cookie = cookie.convert(); % get array of Set-Cookie structs
                cookie = [cookie.Cookie]; % get array of Cookies from all structs
                cookies = [cookies cookie];
            end
            info.cookies = cookies;
            info.uri = history(end).URI;
            
            % Store the info
            this.map(host) = info;
        end
        
        function fname = websave(this, fname, url)
            data = convertStringsToChars(webread(this, url));
            if ischar(data)
                read_write_entire_textfile(fname, data);
            else
                write_bin(data, fname);
            end
        end
    end
end