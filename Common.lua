-- LOCALs
local type = type;
local format = string.format;

-- 内部函数：校验参数。
function ValidateArgument(argumentName, argumentValue, expectedType, validatorFunction)
    local isValid = (not expectedType or type(argumentValue) == expectedType) and (type(validatorFunction) ~= "function" or validatorFunction(argumentValue));
    if (not isValid) then
		error(format("Argument %s is invalid.", argumentName), 2);
	end
end

-- 内部函数：校验参数。
function NormalizeArgumentAsPosition(argumentName, argumentValue)
	local result = false;
    if (type(argumentValue) == "table" and type(argumentValue[1]) == "number" and type(argumentValue[2]) == "number" and type(argumentValue[3]) == "number") then
		result = argumentValue;
	elseif (type(argumentValue) == "string") then
		result = GetObjectPosition(argumentValue);
	end
    if (result) then
		return result;
	else
		error(format("Argument %s is invalid.", argumentName), 2);
	end
end

-- 内部函数：判断参数是否为坐标。
function IsArgumentPosition(argument)
	return type(argument) == "table" and type(argument[1]) == "number" and type(argument[2]) == "number" and type(argument[3]) == "number";
end

-- 内部函数：判断参数是否为坐标。
function IsArgumentPositionOrString(argument)
	return type(argument) == "string" or type(argument) == "table" and type(argument[1]) == "number" and type(argument[2]) == "number" and type(argument[3]) == "number";
end

-- 内/外函数：打印变量。
function print(...)
	if (DEFAULT_CHAT_FRAME) then
		local message = "";
		for i = 1, table.getn(arg) do
			if arg[i] == nil then
				arg[i] = "nil";
			end
			message = message .. " " .. tostring(arg[i]);
		end
		message = string.sub(message, 2);
		DEFAULT_CHAT_FRAME:AddMessage(message);
	end
end

-- 内/外函数：获取本地化文本。
function GetLocalizedText(englishText, chineseText)
	if (GetLocale() == "zhCN") then
		return chineseText;
	else
		return englishText;
	end
end

-- 内/外函数：判断数组是否包含指定元素。
function tcontains(tbl, element)
	local result = false;
	for i = 1, table.getn(tbl) do
		if (tbl[i] == element) then
			result = true;
		end
	end
	return result;
end

-- 内/外函数：过滤数组。
function tfilter(tbl, filter)
	local results = {};
	local resultCount = 0;
	for i = 1, table.getn(tbl) do
		local element = tbl[i];
		if (filter(element)) then
			resultCount = resultCount + 1;
			results[resultCount] = element;
		end
	end
	return results;
end

-- 内/外函数：寻找数组中的最大元素。
function tmax(tbl, comparer)
	local result;
	for i = 1, table.getn(tbl) do
		local element = tbl[i];
		if (result) then
			if (type(comparer) == "function") then
				if (comparer(element, result)) then
					result = element;
				end
			elseif (element > result) then
				result = element;
			end
		else
			result = element;
		end
	end
	return result;
end

-- 内/外函数：寻找数组中的最小元素。
function tmin(tbl, comparer)
	local result;
	for i = 1, table.getn(tbl) do
		local element = tbl[i];
		if (result) then
			if (type(comparer) == "function") then
				if (comparer(element, result)) then
					result = element;
				end
			elseif (element < result) then
				result = element;
			end
		else
			result = element;
		end
	end
	return result;
end

-- 内/外函数：判断背包空余格数。
function GetContainerFreeSlotCount()
	local result = 0;
	for i = 0, 4 do
		local containerSlotCount = GetContainerNumSlots(i);
		if (containerSlotCount) then
			for j = 1, containerSlotCount do
				if (not GetContainerItemInfo(i, j)) then
					result = result + 1;
				end
			end
		end
	end
	return result;
end

-- 内外函数：获取坐标的2D平面距离
function GetDistance2D(position1, position2)
	position1 = NormalizeArgumentAsPosition("position1", position1);
	position2 = NormalizeArgumentAsPosition("position2", position2);
	return math.sqrt(math.pow(position1[1] - position2[1], 2) + math.pow(position1[2] - position2[2], 2));
end

-- 内/外函数：获取从坐标1到坐标2的面向角度。
function GetDirectionBetweenPositions(position1, position2)
	if (math.abs(position2[1] - position1[1]) < 0.0001) then
		return nil;
	end
	position1 = NormalizeArgumentAsPosition("position1", position1);
	position2 = NormalizeArgumentAsPosition("position2", position2);
	local facing = math.atan((position2[2] - position1[2]) / (position2[1] - position1[1]));
	if (position2[1] < position1[1] and position2[2] > position1[2]) then
		-- 第二象限
		facing = facing + math.pi;
	elseif (position2[1] < position1[1] and position2[2] < position1[2]) then
		-- 第三象限
		facing = facing + math.pi;
	elseif (position2[1] > position1[1] and position2[2] < position1[2]) then
		-- 第四象限
		facing = facing + 2 * math.pi;
	end
	local pitch = math.atan((position2[3] - position1[3]) / math.sqrt(math.pow(position2[2] - position1[2], 2) + math.pow(position2[1] - position1[1], 2)));
	return facing, pitch;
end
