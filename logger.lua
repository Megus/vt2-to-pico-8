local M = {}

M.E = {
  wrongPatternLength = "wrongPatternLength"
}
M.W = {
  ignoredOrnament = "ignoredOrnament"
}

M.errors = {}
M.warnings = {}

local function distinctList(values)
  local distinct = {}
  local res = ""
  for i, v in ipairs(values) do
    if i == 1 then
      res = res .. v
    elseif distinct[v] ~= true then
      res = res .. ", " .. v
    end
    distinct[v] = true
  end
  return res
end

local function valueList(data, field)
  local module1 = {}
  local module2 = {}
  for _, v in ipairs(data) do
    if v.module == 1 then
      table.insert(module1, v[field])
    else
      table.insert(module2, v[field])
    end
  end
  local res = "    Module 1: " .. distinctList(module1)
  if #module2 > 0 then
    res = res .. "\n    Module 2: " .. distinctList(module2)
  end

  return res
end

function M.errorLog()
  local log = ""
  for code, data in pairs(M.errors) do
    if code == M.E.wrongPatternLength then
      log = log .. "[!] All patterns should have 32 or 64 rows. These patterns have wrong length:\n"
      log = log .. valueList(data, "pattern") .. "\n"
    end
  end

  return log
end

function M.warningLog()
  local log = ""
  for code, data in pairs(M.warnings) do
    if code == M.W.ignoredOrnament then
      log = log .. "[-] These ornaments are ignored because they don't match the rules:\n"
      log = log .. valueList(data, "ornament") .. "\n"
    end
  end
  return log
end



function M.error(code, data)
  if M.errors[code] == nil then
    M.errors[code] = {}
  end
  table.insert(M.errors[code], data)
end

function M.warning(code, data)
  if M.warnings[code] == nil then
    M.warnings[code] = {}
  end
  table.insert(M.warnings[code], data)
end
  
return M