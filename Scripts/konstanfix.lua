local success, err = pcall(function()
	-- Fixed by lovrewe (Repaired for local Luau compatibility)

	assert(getscriptbytecode, "Exploit not supported.")

	-- Switched to HTTPS to prevent executor network dropping
	local API = "https://api.plusgiant5.com" 

	local last_call = 0

	local request = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request

	local function call(konstantType, scriptPath)
		local success, bytecode = pcall(getscriptbytecode, scriptPath)

		if (not success) then
			return "-- Failed to get script bytecode, error:\n\n--[[\n" .. tostring(bytecode) .. "\n--]]"
		end

		local time_elapsed = os.clock() - last_call
		if time_elapsed <= .5 then
			task.wait(.5 - time_elapsed)
		end

		-- Ensure the request utility actually exists before calling
		if not request then
			return "-- Error: Your executor lacks a valid HTTP request utility (request/http_request)."
		end

		local httpResult = request({
			Url = API .. konstantType,
			Body = bytecode,
			Method = "POST",
			Headers = {
				["Content-Type"] = "text/plain"
			}
		})

		last_call = os.clock()

		-- Catch cases where the API is down or blocks the connection entirely
		if (not httpResult) or (typeof(httpResult) ~= "table") then
			return "-- Error: Executor network layer returned a nil response. API might be blocked."
		end

		if (httpResult.StatusCode ~= 200) then
			return "-- Error occurred while requesting Konstant API, error:\n\n--[[\n" .. tostring(httpResult.Body) .. "\n--]]"
		else
			return httpResult.Body
		end
	end

	local function decompile(scriptPath)
		return call("/konstant/decompile", scriptPath)
	end

	local function disassemble(scriptPath)
		return call("/konstant/disassemble", scriptPath)
	end

	getgenv().decompile = decompile
	getgenv().disassemble = disassemble
end)

if not success then
	warn("❌ Decompiler injection failed critically: " .. tostring(err))
end
