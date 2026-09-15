-- translation_filter.lua
-- 中文候选词翻译为英文显示在候选词后面（只显示，不随候选词提交）
-- 需要本地翻译服务：POST http://127.0.0.1:5000/translate
-- 在方案 engine/filters 增加 - lua_filter@translation_filter

local translation_filter = {}
translation_filter.cache = {}

local API_URL = "http://127.0.0.1:5000/translate"
local REQUEST_TIMEOUT = 1  -- 本地 API，超时短，避免卡顿
local MAX_TRANSLATE = 3    -- 只翻译前 N 个候选词

-- 翻译失败记录，避免对失败文本反复请求
local failed = {}

-- 检查文本是否包含 CJK 汉字 (U+4E00-U+9FFF)
local function has_chinese(text)
    if not text then
        return false
    end
    return text:match("[\228-\233][\128-\191][\128-\191]") ~= nil
end

-- 从 JSON 响应中提取 translatedText 字段（处理可能存在的转义引号）
local function extract_translated(result)
    if not result then
        return nil
    end
    local m = result:match('"translatedText"%s*:%s*"(.-)"%s*[,}]')
    if m then
        m = m:gsub('\\"', '"'):gsub('\\\\', '\\')
        m = m:gsub('\\n', '\n'):gsub('\\r', '\r'):gsub('\\t', '\t')
        if m ~= "" then
            return m
        end
    end
    return nil
end

-- 清理文本用于缓存 key
local function normalize_text(text)
    if not text or text == "" then
        return nil
    end
    return text:gsub("%s+", " ")
end

-- 调用本地翻译 API（同步，本地 API 响应快，首次即可显示翻译）
local function translate_sync(text)
    local escaped = text:gsub('\\', '\\\\'):gsub('"', '\\"')
    local payload = '{"q": "' .. escaped
        .. '", "source": "auto", "target": "en", "format": "text", "alternatives": 1, "api_key": ""}'

    local handle = io.popen('curl -s -m ' .. REQUEST_TIMEOUT
        .. ' -X POST ' .. API_URL
        .. " -H 'Content-Type: application/json'"
        .. " -d '" .. payload:gsub("'", "'\\''") .. "'")
    if not handle then
        return nil
    end
    local result = handle:read("*a")
    handle:close()

    return extract_translated(result)
end

-- 获取翻译：缓存命中直接返回，未命中同步请求并缓存
local function get_translation(text)
    local key = normalize_text(text)
    if not key then
        return nil
    end

    local cached = translation_filter.cache[key]
    if cached then
        return cached
    end

    -- 失败过的不再请求
    if failed[key] then
        return nil
    end

    local translated = translate_sync(key)
    if translated then
        translation_filter.cache[key] = translated
    else
        failed[key] = true
    end
    return translated
end

-- 过滤器入口
function translation_filter.func(input, env)
    local count = 0

    for cand in input:iter() do
        if count < MAX_TRANSLATE and has_chinese(cand.text) then
            local translation = get_translation(cand.text)
            if translation then
                if cand.comment and cand.comment ~= "" then
                    cand.comment = cand.comment .. "  (" .. translation .. ")"
                else
                    cand.comment = "(" .. translation .. ")"
                end
            end
            count = count + 1
        end
        yield(cand)
    end
end

return translation_filter