module(..., package.seeall)

function main(params)

	if params then

		if #params == 1 then
			return math.random(params[1])
		elseif #params == 2 then
			return math.random(params[1], params[2])
		end
	end

	return math.random()	
	
end
