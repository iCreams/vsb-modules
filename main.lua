--[[

Modules for VSB

https://github.com/Mokiros/vsb-modules

Licensed under the MIT License <http://opensource.org/licenses/MIT>.

Copyright (c) 2019 Mokiros

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

]]

local env = getfenv()
local old_require = env.require

env.global = {}

local Cache = {}

local HS = game:GetService("HttpService")

local github_base_url = "https://raw.githubusercontent.com/Mokiros/vsb-modules/master/modules/"
local pastebin_base_url = "https://pastebin.com/raw/"

local function http_get(url,headers)
	local response = HS:RequestAsync({
		Url = url,
		Method = "GET",
		Headers = headers
	})
	
	return response.Body,response
end

local function new_require(a,b)
	if typeof(a) ~= "string" then
		local success,errmsg = pcall(old_require,a,b)
		if not success then
			return error(errmsg,2)
		end
		return errmsg
	end
	
	local cached = Cache[a]
	if cached then
		return cached
	end
	local url
	if a:sub(1,4):lower() == 'http' then -- Regular http link
		url = a
	elseif #a == 8 then -- Pastebin ID
		url = pastebin_base_url .. a
	else -- Modules from github repository
		url = github_base_url .. a .. '.lua'
	end
	local success,body,res = pcall(http_get,url)
	if not success then
		error(("Error loading %s: %s"):format(url,body),2)
	elseif res.StatusCode ~= 200 then
		error(("Error loading %s: server returned status code %s"):format(url,res.StatusCode),2)
	end
	local success,fun,err = pcall(loadstring,body)
	if not success then
		error(("Loadstring error: %s"):format(fun),2)
	elseif not fun then
		error(("Error parsing module: %s"):format(err),2)
	end
	local module_env = setmetatable({ module = {} },{ __index = env })
	setfenv(fun,module_env)
	local success,var = pcall(fun)
	if not success then
		error(("Error running module: %s"):format(var),2)
	elseif not var then
		error("Module did not return a single value",2)
	end
	Cache[a] = var
	return var
end

env.require = new_require
