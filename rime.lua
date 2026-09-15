-- Rime Lua 扩展 https://github.com/hchunhui/librime-lua
-- 文档 https://github.com/hchunhui/librime-lua/wiki/Scripting

-- v 模式 symbols 优先（全拼）
v_filter = require("v_filter")

-- 以词定字，可在 default.yaml key_binder 下配置快捷键，默认为左右中括号 [ ]
select_character = require("select_character")

-- 日期时间，可在方案中配置触发关键字。
date_translator = require("date_translator")

-- Unicode，U 开头
unicode = require("unicode")

-- 数字、人民币大写，R 开头
number_translator = require("number_translator")

-- 自动大写英文词汇
autocap_filter = require("autocap_filter")

-- 降低部分英语单词在候选项的位置，可在方案中配置要降低的单词
reduce_english_filter = require("reduce_english_filter")


-- 默认未启用：

-- 长词优先（全拼）
-- 在 engine/filters 增加 - lua_filter@long_word_filter
-- 在方案里写配置项:
-- 提升 count 个词语，插入到第 idx 个位置。
-- 示例：将 2 个词插入到第 4、5 个候选项，输入 jie 得到「1接 2解 3姐 4饥饿 5极恶」
-- long_word_filter:
--   count: 2
--   idx: 4
long_word_filter = require("long_word_filter")

-- 中英混输词条自动空格
-- 在 engine/filters 增加 - lua_filter@cn_en_spacer
cn_en_spacer = require("cn_en_spacer")

-- 九宫格，手机用。
-- 在 engine/filters 增加 - lua_filter@t9_preedit
t9_preedit = require("t9_preedit")

-- 根据是否在用户词典，在结尾加上一个星号 *
-- 在 engine/filters 增加 - lua_filter@is_in_user_dict
-- 在方案里写配置项：
-- is_in_user_dict: true     为输入过的内容加星号
-- is_in_user_dict: flase    为未输入过的内容加星号
is_in_user_dict = require("is_in_user_dict")

-- 词条隐藏、降频
-- 在 engine/processors 增加 - lua_processor@cold_word_drop_processor
-- 在 engine/filters 增加 - lua_filter@cold_word_drop_filter
-- 在 key_binder 增加快捷键：
-- turn_down_cand: "Control+j"  # 匹配当前输入码后隐藏指定的候选字词 或候选词条放到第四候选位置
-- drop_cand: "Control+d"       # 强制删词, 无视输入的编码
cold_word_drop_processor = require("cold_word_drop.processor")
cold_word_drop_filter = require("cold_word_drop.filter")

-- 中文候选词翻译为英文显示在候选词后面
-- 需要本地翻译服务：POST http://127.0.0.1:5000/translate
-- 在 engine/filters 增加 - lua_filter@translation_filter
-- 选择候选词时只会提交中文部分，英文仅作显示
translation_filter = require("translation_filter")

-- 我自己的方法
function my_translator(input, seg)
    if (input == "rq") then
       local cand = Candidate("date", seg.start, seg._end, os.date("%Y/%m/%d"), "")
       cand.quality = 1
       yield(cand)
    end
    if (input == "sjj") then
       local cand = Candidate("sjj", seg.start, seg._end, os.date("%H:%M"), " ")
       cand.quality = 1
       yield(cand)
    end
    -- 返回多个随机数候选项
    if (input == "rr") then
       local cand = Candidate("rr1", seg.start, seg._end, generate_random_timestamp(16), " ")
       cand.quality = 1
       yield(cand)
    end
    if (input == "rr") then
       local cand = Candidate("rr2", seg.start, seg._end, generate_random_timestamp(8), " ")
       cand.quality = 2
       yield(cand)
    end
    if (input == "rr") then
        local cand = Candidate("get_random_address", seg.start, seg._end, get_random_address(), " ")
        cand.quality = 2
        yield(cand)
    end
    if (input == "rr") then
        local cand = Candidate("generate_random_phone", seg.start, seg._end, generate_random_phone(), " ")
        cand.quality = 2
        yield(cand)
    end
    if (input == "rr") then
        local cand = Candidate("get_weekday_utc8", seg.start, seg._end, get_weekday_utc8(), " ")
        cand.quality = 3
        yield(cand)
    end
    if (input == "rr") then
        local cand = Candidate("get_random_nickname", seg.start, seg._end, get_random_nickname(), " ")
        cand.quality = 3
        yield(cand)
    end
end

-- 生成随机数
function generate_random_timestamp(lengthone)
    local timestamp = os.date("%Y%m%d%H%M%S")
    local random_number = string.format("%04d", math.random(0, 9999))
    local all = timestamp .. random_number
    return string.sub(all, 0, lengthone)
end

-- 返回随机地址
function get_random_address()
    local address_list = {
        "贵州省毕节地区毕节市麻园路金泉小区12号楼6单元504室",
        "浙江省台州市三门县珠岙镇朝阳大道4号",
        "黑龙江省双鸭山市尖山区尖山路锦绣路16号5楼",
        "四川省成都市彭州市桂花镇松柏巷53号",
        "北京市西城区广安门外街道鸭子桥路鸭子桥南里6栋",
        "河南省安阳市内黄县城关镇枣乡大道麟凤小区5栋3单元203室",
        "江苏省苏州市吴江区平望镇通运东路吴江百盛花园14号楼",
        "上海市宝山区顾村镇菊泉街488弄菊泉街488弄15号楼1单元1101号",
        "北京市房山区城关街道杏花东路中国铁建原香嘉苑7"
    }
    -- 检查输入是否为一个非空数组
    if type(address_list) ~= "table" or #address_list == 0 then
        return nil  -- 如果数组为空或无效，返回 nil
    end

    -- 获取数组的随机索引
    local random_index = math.random(1, #address_list)

    -- 返回随机地址
    return address_list[random_index]
end

-- 生成随机手机号
function generate_random_phone()
    local phone_prefixes = {
        "130", "131", "132", "133", "134", "135", "136", "137", "138", "139",
        "147", "150", "151", "152", "153", "155", "156", "157", "158", "159",
        "176", "177", "178", "182", "183", "185", "186", "187", "188", "199"
    }
    -- 随机选择一个号段
    local prefix = phone_prefixes[math.random(1, #phone_prefixes)]

    -- 随机生成后 8 位数字
    local suffix = ""
    for _ = 1, 8 do
        suffix = suffix .. tostring(math.random(0, 9))
    end

    -- 返回完整手机号
    return prefix .. suffix
end
function get_weekday_utc8()
    local weekdays = {
        "星期日",
        "星期一",
        "星期二",
        "星期三",
        "星期四",
        "星期五",
        "星期六"
    }
    local current_wday = os.date("*t").wday
    return weekdays[current_wday]
end
-- 返回随机名称
function get_random_nickname()
    local nickname_list = {
        "许真洁",
        "康贞蓉",
        "熊红香",
        "孔美",
        "唐菊瑾",
        "潘刚",
        "石莲兰",
        "曹勤",
        "毛菊",
        "孔勤",
        "金真琴",
        "曹辉岩",
        "卢英琴",
        "魏珍",
        "熊海",
        "万珠",
        "易芳",
        "阎素",
        "汪良",
        "杨磊国",
        "秦琳兰",
        "江龙中",
        "陆春蕊",
        "白兴志",
        "贺玲",
        "秦东学",
        "许宁",
        "彭娟兰",
        "贾彩",
        "吕勇中",
        "阎祥",
        "徐彩香",
        "袁俊",
        "孔兰",
        "冯白",
        "夏博",
        "罗仁",
        "康美",
        "易力子",
        "阎强飞",
        "史雅君",
        "杨峰",
        "郝玉霞",
        "史磊朗",
        "杨雪",
        "于珠瑶",
        "贺力",
        "王春贞",
        "谢洁菁",
        "谢娟",
        "文德",
        "钟平",
        "孟娜",
        "钱辉",
        "龚永信",
        "姚磊",
        "田素媛",
        "袁海成",
        "潘淑菁",
        "文龙国",
        "方真",
        "赵祥",
        "戴雪薇",
        "乔彪",
        "孔博成",
        "吕素丹",
        "杜彩",
        "张辰",
        "任博朗",
        "陈彪博",
        "罗芬兰",
        "姜萍凤",
        "赵广",
        "傅红璇",
        "程彪",
        "苏兰",
        "谢博有",
        "田世中",
        "崔云蓉",
        "董慧",
        "孟峰泽",
        "吴刚",
        "傅军",
        "苏翠",
        "夏秀",
        "贾春",
        "赖辰康",
        "文娥怡",
        "谢广中",
        "汪勤",
        "夏珠",
        "康玉",
        "龙志成",
        "龚辰",
        "郭白中",
        "范淑",
        "郭辉",
        "何淑兰",
        "彭燕媛",
        "朱志友"
    }
    -- 检查输入是否为一个非空数组
    if type(nickname_list) ~= "table" or #nickname_list == 0 then
        return nil  -- 如果数组为空或无效，返回 nil
    end

    -- 获取数组的随机索引
    local random_index = math.random(1, #nickname_list)

    -- 返回随机地址
    return nickname_list[random_index]
end
